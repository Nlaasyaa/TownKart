import { Request, Response } from 'express';
import { query } from '../config/db';
import { randomUUID } from 'crypto';

export const getDashboard = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    // 1. Get Merchant info
    const merchantResult = await query(
      `SELECT id as merchant_id, seller_code FROM merchants WHERE user_id = ?`,
      [userId]
    );

    if (merchantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Merchant profile not found for this user. Please register as a merchant.' });
    }

    const merchant = merchantResult.rows[0] as any;
    const merchantId = merchant.merchant_id;

    // 1.5 Get Shop info
    const shopResult = await query(
      `SELECT shop_name, shop_status FROM shops WHERE merchant_id = ?`,
      [merchantId]
    );

    const shop = shopResult.rows.length > 0 
      ? (shopResult.rows[0] as any) 
      : { shop_name: 'Shop Not Setup', shop_status: 'CLOSED' };

    // 2. Get Revenue & Orders today
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const metricsResult = await query(
      `SELECT 
         COUNT(*) as total_orders,
         SUM(CASE WHEN status = 'DELIVERED' THEN total ELSE 0 END) as total_revenue
       FROM merchant_orders 
       WHERE merchant_id = ? AND created_at >= ?`,
      [merchantId, startOfToday]
    );
    const metrics = metricsResult.rows[0] as any;

    // 3. Get pending action count
    const pendingResult = await query(
      `SELECT COUNT(*) as pending_count 
       FROM merchant_orders 
       WHERE merchant_id = ? AND status = 'PLACED'`,
      [merchantId]
    );
    const pendingCount = (pendingResult.rows[0] as any).pending_count;

    // 4. Get products count
    const productsResult = await query(
      `SELECT COUNT(*) as products_count 
       FROM merchant_products 
       WHERE merchant_id = ?`,
      [merchantId]
    );
    const productsCount = (productsResult.rows[0] as any).products_count;

    // 5. Get recent pending orders preview
    const recentOrders = await query(
      `SELECT mo.id, mo.total, mo.created_at, COALESCE(c.full_name, 'Unknown Customer') as full_name,
              (SELECT COUNT(*) FROM order_items oi WHERE oi.merchant_order_id = mo.id) as item_count
       FROM merchant_orders mo
       LEFT JOIN orders o ON mo.order_id = o.id
       LEFT JOIN customers c ON o.customer_id = c.id
       WHERE mo.merchant_id = ? AND mo.status = 'PLACED'
       ORDER BY mo.created_at DESC LIMIT 3`,
      [merchantId]
    );

    res.status(200).json({
      shopName: shop.shop_name,
      sellerCode: merchant.seller_code,
      shopStatus: shop.shop_status,
      todayRevenue: metrics.total_revenue || 0,
      todayOrders: metrics.total_orders || 0,
      pendingAction: pendingCount,
      productsCount: productsCount,
      recentPendingOrders: recentOrders.rows,
    });
  } catch (error) {
    console.error('Error in getDashboard:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getProducts = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    const merchantId = (merchantResult.rows[0] as any).id;

    // Join merchant_products, master_product_variants, master_products, and merchant_inventory
    const productsResult = await query(
      `SELECT 
         mp.id as merchant_product_id,
         mp.selling_price,
         mp.mrp,
         mp.minimum_stock,
         mp.status,
         mpv.variant_name,
         mast.product_name,
         cat.name as category_name,
         COALESCE(inv.stock_quantity, 0) as stock_quantity
       FROM merchant_products mp
       JOIN master_product_variants mpv ON mp.master_product_variant_id = mpv.id
       JOIN master_products mast ON mpv.master_product_id = mast.id
       JOIN categories cat ON mast.category_id = cat.id
       LEFT JOIN merchant_inventory inv ON mp.id = inv.merchant_product_id
       WHERE mp.merchant_id = ?`,
      [merchantId]
    );

    res.status(200).json({ products: productsResult.rows });
  } catch (error) {
    console.error('Error in getProducts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getOrders = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    const merchantId = (merchantResult.rows[0] as any).id;

    // Get orders with their items
    const ordersResult = await query(
      `SELECT 
         mo.id, mo.status, mo.total, mo.created_at,
         COALESCE(c.full_name, 'Unknown Customer') as full_name
       FROM merchant_orders mo
       LEFT JOIN orders o ON mo.order_id = o.id
       LEFT JOIN customers c ON o.customer_id = c.id
       WHERE mo.merchant_id = ?
       ORDER BY mo.created_at DESC`,
      [merchantId]
    );

    const orders = ordersResult.rows as any[];
    
    // For each order, fetch items (in a real app, use a join with GROUP_CONCAT or fetch in parallel)
    for (const order of orders) {
      const itemsResult = await query(
        `SELECT 
           oi.quantity, 
           mast.product_name,
           mpv.variant_name
         FROM order_items oi
         JOIN merchant_products mp ON oi.merchant_product_id = mp.id
         JOIN master_product_variants mpv ON mp.master_product_variant_id = mpv.id
         JOIN master_products mast ON mpv.master_product_id = mast.id
         WHERE oi.merchant_order_id = ?`,
        [order.id]
      );
      order.items = itemsResult.rows;
    }

    res.status(200).json({ orders });
  } catch (error) {
    console.error('Error in getOrders:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSettings = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const settingsResult = await query(
      `SELECT 
         m.owner_name, m.gst_number, m.approval_status,
         s.shop_name, s.address, s.working_hours, s.shop_status
       FROM merchants m
       JOIN shops s ON m.id = s.merchant_id
       WHERE m.user_id = ?`,
      [userId]
    );

    if (settingsResult.rows.length === 0) {
      return res.status(404).json({ error: 'Merchant not found' });
    }

    res.status(200).json({ settings: settingsResult.rows[0] });
  } catch (error) {
    console.error('Error in getSettings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getCategories = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const merchantResult = await query('SELECT id, seller_code FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    const merchantId = (merchantResult.rows[0] as any).id;

    const categoriesResult = await query(
      `SELECT 
         c.id, c.name, c.code, 
         IF(mc.merchant_id IS NOT NULL, true, false) as is_enabled,
         (SELECT COUNT(*) FROM master_products mp JOIN merchant_products m_prod ON mp.id = m_prod.master_product_variant_id WHERE mp.category_id = c.id AND m_prod.merchant_id = ?) as products_count
       FROM categories c
       LEFT JOIN merchant_categories mc ON c.id = mc.category_id AND mc.merchant_id = ?`,
      [merchantId, merchantId]
    );

    res.status(200).json({ 
      categories: categoriesResult.rows,
      sellerCode: (merchantResult.rows[0] as any).seller_code
    });
  } catch (error) {
    console.error('Error in getCategories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const toggleCategory = async (req: Request, res: Response) => {
  try {
    const { userId, categoryId } = req.params;
    const { isEnabled } = req.body;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    const merchantId = (merchantResult.rows[0] as any).id;

    if (isEnabled) {
      await query('INSERT IGNORE INTO merchant_categories (merchant_id, category_id) VALUES (?, ?)', [merchantId, categoryId]);
    } else {
      await query('DELETE FROM merchant_categories WHERE merchant_id = ? AND category_id = ?', [merchantId, categoryId]);
    }

    res.status(200).json({ message: 'Category toggled successfully' });
  } catch (error) {
    console.error('Error in toggleCategory:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSubcategories = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const subcategoriesResult = await query(
      `SELECT sc.id, sc.name, c.name as category_name
       FROM subcategories sc
       JOIN categories c ON sc.category_id = c.id
       JOIN merchant_categories mc ON c.id = mc.category_id
       WHERE mc.merchant_id = ? AND sc.is_active = true`,
      [merchantId]
    );

    res.status(200).json({ subcategories: subcategoriesResult.rows });
  } catch (error) {
    console.error('Error in getSubcategories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getAvailableMasterProducts = async (req: Request, res: Response) => {
  try {
    const { userId, subcategoryId } = req.params;
    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const productsResult = await query(
      `SELECT mp.id, mp.product_name, mpv.id as variant_id, mpv.variant_name
       FROM master_products mp
       JOIN master_product_variants mpv ON mp.id = mpv.master_product_id
       WHERE mp.subcategory_id = ? AND mp.is_active = true
         AND mpv.id NOT IN (
           SELECT master_product_variant_id FROM merchant_products WHERE merchant_id = ?
         )`,
      [subcategoryId, merchantId]
    );

    res.status(200).json({ products: productsResult.rows });
  } catch (error) {
    console.error('Error in getAvailableMasterProducts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const addProduct = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { variantId, sellingPrice, mrp, minimumStock } = req.body;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const merchantProductId = randomUUID();

    await query(
      `INSERT INTO merchant_products (id, merchant_id, master_product_variant_id, selling_price, mrp, minimum_stock)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [merchantProductId, merchantId, variantId, sellingPrice, mrp, minimumStock]
    );

    await query(
      `INSERT INTO merchant_inventory (merchant_product_id, stock_quantity) VALUES (?, 0)`,
      [merchantProductId]
    );

    res.status(201).json({ message: 'Product added successfully' });
  } catch (error: any) {
    console.error('Error in addProduct:', error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Product already added to your store' });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateProduct = async (req: Request, res: Response) => {
  try {
    const { userId, productId } = req.params;
    const { sellingPrice, mrp, minimumStock, stockQuantity } = req.body;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const productCheck = await query('SELECT id FROM merchant_products WHERE id = ? AND merchant_id = ?', [productId, merchantId]);
    if (productCheck.rows.length === 0) return res.status(404).json({ error: 'Product not found' });

    await query(
      `UPDATE merchant_products SET selling_price = ?, mrp = ?, minimum_stock = ? WHERE id = ?`,
      [sellingPrice, mrp, minimumStock, productId]
    );

    const invCheck = await query('SELECT merchant_product_id FROM merchant_inventory WHERE merchant_product_id = ?', [productId]);
    if (invCheck.rows.length > 0) {
      await query('UPDATE merchant_inventory SET stock_quantity = ? WHERE merchant_product_id = ?', [stockQuantity, productId]);
    } else {
      await query('INSERT INTO merchant_inventory (merchant_product_id, stock_quantity) VALUES (?, ?)', [productId, stockQuantity]);
    }

    res.status(200).json({ message: 'Product updated successfully' });
  } catch (error) {
    console.error('Error in updateProduct:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteProduct = async (req: Request, res: Response) => {
  try {
    const { userId, productId } = req.params;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const productCheck = await query('SELECT id FROM merchant_products WHERE id = ? AND merchant_id = ?', [productId, merchantId]);
    if (productCheck.rows.length === 0) return res.status(404).json({ error: 'Product not found' });

    await query('DELETE FROM merchant_inventory WHERE merchant_product_id = ?', [productId]);
    await query('DELETE FROM merchant_products WHERE id = ?', [productId]);

    res.status(200).json({ message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Error in deleteProduct:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const toggleProductStatus = async (req: Request, res: Response) => {
  try {
    const { userId, productId } = req.params;
    const { status } = req.body;

    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const productCheck = await query('SELECT id FROM merchant_products WHERE id = ? AND merchant_id = ?', [productId, merchantId]);
    if (productCheck.rows.length === 0) return res.status(404).json({ error: 'Product not found' });

    await query('UPDATE merchant_products SET status = ? WHERE id = ?', [status, productId]);

    res.status(200).json({ message: 'Product status updated' });
  } catch (error) {
    console.error('Error in toggleProductStatus:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateOrderStatus = async (req: Request, res: Response) => {
  try {
    const { userId, merchantOrderId } = req.params;
    const { status } = req.body;

    const allowedStatuses = ['ACCEPTED', 'READY', 'DELIVERED', 'CANCELLED'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ error: `Invalid status. Must be one of: ${allowedStatuses.join(', ')}` });
    }

    // Verify the order belongs to this merchant
    const merchantResult = await query('SELECT id FROM merchants WHERE user_id = ?', [userId]);
    if (merchantResult.rows.length === 0) return res.status(404).json({ error: 'Merchant not found' });
    const merchantId = (merchantResult.rows[0] as any).id;

    const orderCheck = await query(
      'SELECT id FROM merchant_orders WHERE id = ? AND merchant_id = ?',
      [merchantOrderId, merchantId]
    );
    if (orderCheck.rows.length === 0) return res.status(404).json({ error: 'Order not found' });

    await query('UPDATE merchant_orders SET status = ? WHERE id = ?', [status, merchantOrderId]);

    res.status(200).json({ message: `Order status updated to ${status}` });
  } catch (error) {
    console.error('Error in updateOrderStatus:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
