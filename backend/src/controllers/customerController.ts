import { Request, Response } from 'express';
import pool from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export const getCategories = async (req: Request, res: Response) => {
  try {
    const query = `
      SELECT 
        c.id, 
        c.name, 
        c.icon,
        COUNT(DISTINCT CASE WHEN mi.stock_quantity > 0 THEN mp.master_product_variant_id ELSE NULL END) as product_count
      FROM categories c
      LEFT JOIN master_products master_p ON c.id = master_p.category_id AND master_p.is_active = true
      LEFT JOIN master_product_variants master_v ON master_p.id = master_v.master_product_id
      LEFT JOIN merchant_products mp ON master_v.id = mp.master_product_variant_id AND mp.status = 'AVAILABLE'
      LEFT JOIN merchant_inventory mi ON mp.id = mi.merchant_product_id
      WHERE c.is_active = true
      GROUP BY c.id, c.name, c.icon
      ORDER BY c.display_order ASC;
    `;
    const [rows] = await pool.query(query);
    res.json({ categories: rows });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getCategoryDetails = async (req: Request, res: Response) => {
  try {
    const { categoryId } = req.params;
    
    const subcatsQuery = `SELECT id, name FROM subcategories WHERE category_id = ? AND is_active = true ORDER BY display_order ASC`;
    const [subcats] = await pool.query(subcatsQuery, [categoryId]);
    
    const productsQuery = `
      SELECT 
        master_v.id as variant_id,
        master_p.subcategory_id,
        master_p.product_name,
        master_v.variant_name,
        MIN(mp.selling_price) as lowest_price,
        COUNT(DISTINCT mp.merchant_id) as shops_count
      FROM merchant_products mp
      JOIN master_product_variants master_v ON mp.master_product_variant_id = master_v.id
      JOIN master_products master_p ON master_v.master_product_id = master_p.id
      JOIN merchant_inventory mi ON mp.id = mi.merchant_product_id
      WHERE master_p.category_id = ? 
        AND mp.status = 'AVAILABLE' 
        AND mi.stock_quantity > 0
        AND master_p.is_active = true
      GROUP BY master_v.id, master_p.subcategory_id, master_p.product_name, master_v.variant_name
      ORDER BY shops_count DESC;
    `;
    const [products] = await pool.query(productsQuery, [categoryId]);
    
    res.json({ 
      subcategories: subcats,
      products: products
    });
  } catch (error) {
    console.error('Error fetching category details:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getAvailableProducts = async (req: Request, res: Response) => {
  try {
    const query = `
      SELECT 
        master_v.id as variant_id,
        master_p.product_name,
        master_v.variant_name,
        MIN(mp.selling_price) as lowest_price,
        MAX(mp.mrp) as mrp,
        COUNT(DISTINCT mp.merchant_id) as shops_count,
        MAX(master_p.description) as description
      FROM merchant_products mp
      JOIN master_product_variants master_v ON mp.master_product_variant_id = master_v.id
      JOIN master_products master_p ON master_v.master_product_id = master_p.id
      JOIN merchant_inventory mi ON mp.id = mi.merchant_product_id
      WHERE mp.status = 'AVAILABLE' 
        AND mi.stock_quantity > 0
        AND master_p.is_active = true
      GROUP BY master_v.id, master_p.product_name, master_v.variant_name
      ORDER BY shops_count DESC
      LIMIT 100;
    `;
    const [rows] = await pool.query(query);
    res.json({ products: rows });
  } catch (error) {
    console.error('Error fetching customer products:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSellersForVariant = async (req: Request, res: Response) => {
  try {
    const { variantId } = req.params;
    const query = `
      SELECT 
        mp.id as merchant_product_id,
        mp.selling_price,
        mp.mrp,
        mi.stock_quantity,
        m.seller_code,
        s.shop_name,
        s.city
      FROM merchant_products mp
      JOIN merchants m ON mp.merchant_id = m.id
      JOIN shops s ON m.id = s.merchant_id
      JOIN merchant_inventory mi ON mp.id = mi.merchant_product_id
      WHERE mp.master_product_variant_id = ?
        AND mp.status = 'AVAILABLE' 
        AND mi.stock_quantity > 0
      ORDER BY mp.selling_price ASC;
    `;
    const [rows] = await pool.query(query, [variantId]);
    res.json({ sellers: rows });
  } catch (error) {
    console.error('Error fetching sellers for variant:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const placeOrder = async (req: Request, res: Response) => {
  const { customerId, addressId: reqAddressId, items, paymentMethod = 'COD' } = req.body;

  if (!customerId || !items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Invalid order data' });
  }

  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    // Resolve the customers.id UUID from the user_id passed from the frontend
    const [customerRows] = await conn.query<RowDataPacket[]>(
      'SELECT id FROM customers WHERE user_id = ?',
      [customerId]
    );

    let customerUUID: string;
    if (customerRows.length === 0) {
      // Auto-create a customers record if it's missing (self-healing)
      const [uuidRes] = await conn.query<RowDataPacket[]>('SELECT UUID() as uuid');
      customerUUID = uuidRes[0].uuid;
      await conn.query(
        'INSERT INTO customers (id, user_id, full_name) VALUES (?, ?, ?)',
        [customerUUID, customerId, 'Customer']
      );
    } else {
      customerUUID = customerRows[0].id;
    }

    let subtotal = 0;
    const deliveryCharge = 40;

    // Calculate subtotal and verify stock
    for (const item of items) {
      const [productRows] = await conn.query<RowDataPacket[]>(
        'SELECT mp.selling_price, mi.stock_quantity, mp.merchant_id FROM merchant_products mp JOIN merchant_inventory mi ON mp.id = mi.merchant_product_id WHERE mp.id = ?',
        [item.merchant_product_id]
      );

      if (productRows.length === 0) {
        throw new Error(`Product ${item.merchant_product_id} not found`);
      }

      const product = productRows[0];
      if (product.stock_quantity < item.quantity) {
        throw new Error(`Insufficient stock for product ${item.merchant_product_id}`);
      }

      item.unit_price = parseFloat(product.selling_price);
      item.merchant_id = product.merchant_id;
      subtotal += item.unit_price * item.quantity;
    }

    const grandTotal = subtotal + deliveryCharge;

    let addressId = reqAddressId;
    if (!addressId) {
      // Get or create a default address using the resolved customerUUID
      const [addressRows] = await conn.query<RowDataPacket[]>(
        'SELECT id FROM customer_addresses WHERE customer_id = ? LIMIT 1',
        [customerUUID]
      );

      if (addressRows.length === 0) {
        const [uuidResult] = await conn.query<RowDataPacket[]>('SELECT UUID() as uuid');
        addressId = uuidResult[0].uuid;
        await conn.query(
          'INSERT INTO customer_addresses (id, customer_id, address_line1, city, state, pincode) VALUES (?, ?, ?, ?, ?, ?)',
          [addressId, customerUUID, '123 Main St', 'Pune', 'MH', '411001']
        );
      } else {
        addressId = addressRows[0].id;
      }
    }

    // 1. Create Order
    const [orderUuidResult] = await conn.query<RowDataPacket[]>('SELECT UUID() as uuid');
    const orderId = orderUuidResult[0].uuid;

    await conn.query(
      `INSERT INTO orders (id, customer_id, address_id, subtotal, delivery_charge, tax, grand_total, payment_method, payment_status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [orderId, customerUUID, addressId, subtotal, deliveryCharge, 0, grandTotal, paymentMethod, 'PENDING']
    );

    // Group items by merchant
    const merchantGroups: { [key: string]: any[] } = {};
    for (const item of items) {
      if (!merchantGroups[item.merchant_id]) {
        merchantGroups[item.merchant_id] = [];
      }
      merchantGroups[item.merchant_id].push(item);
    }

    // 2. Create Merchant Orders and Order Items
    for (const [merchantId, mItems] of Object.entries(merchantGroups)) {
      let mSubtotal = 0;
      mItems.forEach(i => mSubtotal += (i.unit_price * i.quantity));

      const [mOrderUuidResult] = await conn.query<RowDataPacket[]>('SELECT UUID() as uuid');
      const merchantOrderId = mOrderUuidResult[0].uuid;

      await conn.query(
        `INSERT INTO merchant_orders (id, order_id, merchant_id, subtotal, delivery_charge, tax, total, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [merchantOrderId, orderId, merchantId, mSubtotal, 0, 0, mSubtotal, 'PLACED']
      );

      for (const item of mItems) {
        // Insert order item
        const [itemUuidResult] = await conn.query<RowDataPacket[]>('SELECT UUID() as uuid');
        const itemId = itemUuidResult[0].uuid;

        await conn.query(
          `INSERT INTO order_items (id, merchant_order_id, merchant_product_id, quantity, unit_price, total_price)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [itemId, merchantOrderId, item.merchant_product_id, item.quantity, item.unit_price, item.unit_price * item.quantity]
        );

        // Update inventory
        await conn.query(
          `UPDATE merchant_inventory 
           SET stock_quantity = stock_quantity - ? 
           WHERE merchant_product_id = ?`,
          [item.quantity, item.merchant_product_id]
        );
      }
    }

    await conn.commit();
    res.json({ message: 'Order placed successfully', orderId });
  } catch (error: any) {
    await conn.rollback();
    console.error('Error placing order:', error);
    res.status(500).json({ error: error.message || 'Failed to place order' });
  } finally {
    conn.release();
  }
};

export const getCustomerProfile = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    
    // Fetch user details (don't require customers row to exist)
    const userQuery = `
      SELECT 
        u.id,
        u.email,
        u.phone,
        c.id as customer_id,
        c.full_name
      FROM users u
      LEFT JOIN customers c ON u.id = c.user_id
      WHERE u.id = ?
    `;
    const [userRows]: any = await pool.query(userQuery, [userId]);
    
    if (userRows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = userRows[0];
    
    // If no customers row, auto-create one
    let customerId = user.customer_id;
    let fullName = user.full_name;
    const genericNames = ['new customer', 'customer', 'user'];
    
    if (!customerId) {
      const { randomUUID } = require('crypto');
      customerId = randomUUID();
      fullName = user.email?.split('@')[0]?.replace(/[._]/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase()) || 'User';
      await pool.query(
        'INSERT INTO customers (id, user_id, full_name) VALUES (?, ?, ?)',
        [customerId, userId, fullName]
      );
    } else if (fullName && genericNames.includes(fullName.toLowerCase())) {
      // Fix stale generic name — derive from email
      const derivedName = user.email?.split('@')[0]?.replace(/[._]/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase()) || fullName;
      await pool.query('UPDATE customers SET full_name = ? WHERE id = ?', [derivedName, customerId]);
      fullName = derivedName;
    }
    
    // Fetch real order stats
    const statsQuery = `
      SELECT 
        COUNT(o.id) as total_orders,
        COALESCE(SUM(o.grand_total), 0) as total_spent
      FROM orders o
      WHERE o.customer_id = ?
    `;
    const [statsRows]: any = await pool.query(statsQuery, [customerId]);
    const totalOrders = Number(statsRows[0]?.total_orders) || 0;
    const totalSpent = Number(statsRows[0]?.total_spent) || 0;
    
    // Calculate real savings from orders (MRP - selling_price across all order items)
    const savingsQuery = `
      SELECT COALESCE(SUM((mp.mrp - oi.unit_price) * oi.quantity), 0) as total_saved
      FROM orders o
      JOIN merchant_orders mo ON o.id = mo.order_id
      JOIN order_items oi ON mo.id = oi.merchant_order_id
      JOIN merchant_products mp ON oi.merchant_product_id = mp.id
      WHERE o.customer_id = ?
        AND mp.mrp > oi.unit_price
    `;
    const [savingsRows]: any = await pool.query(savingsQuery, [customerId]);
    const totalSaved = Number(savingsRows[0]?.total_saved) || 0;
    
    res.json({
      fullName: fullName || 'User',
      email: user.email || '',
      phone: user.phone || '',
      totalOrders,
      totalSpent,
      totalSaved,
      townCoins: Math.floor(totalSpent / 10) // 1 TownCoin per ₹10 spent
    });
  } catch (error) {
    console.error('Error fetching customer profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getAddresses = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const queryStr = `
      SELECT a.* 
      FROM customer_addresses a
      JOIN customers c ON a.customer_id = c.id
      WHERE c.user_id = ?
      ORDER BY a.is_default DESC, a.created_at DESC
    `;
    const [rows] = await pool.query(queryStr, [userId]);
    res.json({ addresses: rows });
  } catch (error) {
    console.error('Error fetching addresses:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const addAddress = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { addressType = 'HOME', addressLine1, addressLine2, landmark, city, state, pincode, isDefault = false } = req.body;
    
    const customerQuery = 'SELECT id FROM customers WHERE user_id = ?';
    const [customerRows]: any = await pool.query(customerQuery, [userId]);
    if (customerRows.length === 0) {
      return res.status(404).json({ error: 'Customer not found' });
    }
    const customerId = customerRows[0].id;

    if (isDefault) {
      await pool.query('UPDATE customer_addresses SET is_default = FALSE WHERE customer_id = ?', [customerId]);
    }

    const insertQuery = `
      INSERT INTO customer_addresses (customer_id, address_type, address_line1, address_line2, landmark, city, state, pincode, is_default)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    await pool.query(insertQuery, [customerId, addressType, addressLine1, addressLine2, landmark, city, state, pincode, isDefault]);
    
    res.status(201).json({ message: 'Address added successfully' });
  } catch (error) {
    console.error('Error adding address:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getOrderHistory = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    
    // First find the customer id
    const customerQuery = 'SELECT id FROM customers WHERE user_id = ?';
    const [customerRows]: any = await pool.query(customerQuery, [userId]);
    if (customerRows.length === 0) {
      return res.status(404).json({ error: 'Customer not found' });
    }
    const customerId = customerRows[0].id;

    // Fetch orders with items and merchants
    const orderQuery = `
      SELECT 
        o.id as order_id,
        o.grand_total,
        o.payment_method,
        o.payment_status,
        o.created_at,
        mo.id as merchant_order_id,
        mo.status as order_status,
        mo.merchant_id,
        m.shop_name,
        oi.merchant_product_id,
        oi.quantity,
        oi.unit_price,
        oi.total_price,
        mp.master_product_variant_id,
        master_p.product_name,
        master_v.variant_name
      FROM orders o
      JOIN merchant_orders mo ON o.id = mo.order_id
      JOIN shops m ON mo.merchant_id = m.merchant_id
      JOIN order_items oi ON mo.id = oi.merchant_order_id
      JOIN merchant_products mp ON oi.merchant_product_id = mp.id
      JOIN master_product_variants master_v ON mp.master_product_variant_id = master_v.id
      JOIN master_products master_p ON master_v.master_product_id = master_p.id
      WHERE o.customer_id = ?
      ORDER BY o.created_at DESC
    `;
    
    const [rows]: any = await pool.query(orderQuery, [customerId]);
    
    // Group rows by order
    const ordersMap = new Map();
    for (const row of rows) {
      if (!ordersMap.has(row.order_id)) {
        ordersMap.set(row.order_id, {
          order_id: row.order_id,
          grand_total: row.grand_total,
          payment_method: row.payment_method,
          payment_status: row.payment_status,
          created_at: row.created_at,
          items: []
        });
      }
      
      const order = ordersMap.get(row.order_id);
      order.items.push({
        merchant_order_id: row.merchant_order_id,
        order_status: row.order_status,
        shop_name: row.shop_name,
        product_name: row.product_name,
        variant_name: row.variant_name,
        quantity: row.quantity,
        unit_price: row.unit_price,
        total_price: row.total_price
      });
    }

    res.json({ orders: Array.from(ordersMap.values()) });
  } catch (error) {
    console.error('Error fetching order history:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
