import { Request, Response } from 'express';
import { query } from '../config/db';

const checkAdmin = async (userId: string): Promise<boolean> => {
  const result = await query('SELECT role FROM users WHERE id = ?', [userId]);
  if (result.rows.length > 0 && (result.rows[0] as any).role === 'ADMIN') {
    return true;
  }
  return false;
};

export const getDashboard = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    
    // Check admin and get details
    const adminCheck = await query(`
      SELECT u.role, a.full_name, a.designation 
      FROM users u 
      LEFT JOIN admins a ON u.id = a.user_id 
      WHERE u.id = ?
    `, [userId]);

    if (adminCheck.rows.length === 0 || (adminCheck.rows[0] as any).role !== 'ADMIN') {
      return res.status(403).json({ error: 'Unauthorized: Admins only' });
    }

    const adminDetails = adminCheck.rows[0] as any;

    // Overview Stats
    const custRes = await query(`SELECT COUNT(*) as count FROM users WHERE role = 'CUSTOMER'`);
    const merchRes = await query(`SELECT COUNT(*) as count FROM merchants`);
    
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const ordersRes = await query(`SELECT COUNT(*) as count, SUM(total) as revenue FROM merchant_orders WHERE created_at >= ?`, [startOfToday]);
    
    // Category share (simplified for now, based on products per category)
    const catShareRes = await query(`
      SELECT c.name, COUNT(mp.id) as product_count
      FROM categories c
      LEFT JOIN master_products mp ON c.id = mp.category_id
      GROUP BY c.id, c.name
      ORDER BY product_count DESC
      LIMIT 5
    `);

    // Merchant approvals
    const approvalsRes = await query(`
      SELECT m.id, m.seller_code, m.created_at, s.shop_name, s.city, 
             (SELECT GROUP_CONCAT(c.name) 
              FROM merchant_categories mc 
              JOIN categories c ON mc.category_id = c.id 
              WHERE mc.merchant_id = m.id) as categories
      FROM merchants m
      JOIN shops s ON m.id = s.merchant_id
      WHERE m.approval_status = 'PENDING'
      ORDER BY m.created_at DESC
      LIMIT 10
    `);

    res.status(200).json({
      adminName: adminDetails.full_name || 'Admin',
      adminDesignation: adminDetails.designation || 'Administrator',
      totalCustomers: (custRes.rows[0] as any).count,
      totalMerchants: (merchRes.rows[0] as any).count,
      ordersToday: (ordersRes.rows[0] as any).count,
      revenueToday: (ordersRes.rows[0] as any).revenue || 0,
      categoryShare: catShareRes.rows,
      merchantApprovals: approvalsRes.rows
    });
  } catch (error) {
    console.error('Error in Admin getDashboard:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getProfile = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const adminCheck = await query(`
      SELECT u.role, a.full_name, a.designation 
      FROM users u 
      LEFT JOIN admins a ON u.id = a.user_id 
      WHERE u.id = ?
    `, [userId]);

    if (adminCheck.rows.length === 0 || (adminCheck.rows[0] as any).role !== 'ADMIN') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const adminDetails = adminCheck.rows[0] as any;
    res.status(200).json({
      adminName: adminDetails.full_name || 'Admin',
      adminDesignation: adminDetails.designation || 'Administrator',
    });
  } catch (error) {
    console.error('Error in Admin getProfile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getCustomers = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    if (!(await checkAdmin(userId))) return res.status(403).json({ error: 'Unauthorized' });

    const result = await query(`
      SELECT u.id, u.phone, COALESCE(c.full_name, 'Unknown Customer') as full_name, c.created_at, ca.city,
             (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) as total_orders,
             (SELECT SUM(grand_total) FROM orders o WHERE o.customer_id = c.id) as lifetime_spend
      FROM users u
      LEFT JOIN customers c ON u.id = c.user_id
      LEFT JOIN customer_addresses ca ON c.id = ca.customer_id AND ca.is_default = TRUE
      WHERE u.role = 'CUSTOMER'
      ORDER BY u.created_at DESC
    `);
    
    res.status(200).json({ customers: result.rows });
  } catch (error) {
    console.error('Error in Admin getCustomers:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getMerchants = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    if (!(await checkAdmin(userId))) return res.status(403).json({ error: 'Unauthorized' });

    const result = await query(`
      SELECT m.id, m.seller_code, m.approval_status, COALESCE(s.shop_name, 'No Shop Created') as shop_name, s.city,
             (SELECT COUNT(*) FROM merchant_products mp WHERE mp.merchant_id = m.id) as products_count,
             (SELECT SUM(total) FROM merchant_orders mo WHERE mo.merchant_id = m.id) as gmv
      FROM merchants m
      LEFT JOIN shops s ON m.id = s.merchant_id
      ORDER BY m.created_at DESC
    `);
    
    res.status(200).json({ merchants: result.rows });
  } catch (error) {
    console.error('Error in Admin getMerchants:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateMerchantStatus = async (req: Request, res: Response) => {
  try {
    const { merchantId } = req.params;
    const { userId, status } = req.body;

    if (!userId || !(await checkAdmin(userId))) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (!['APPROVED', 'SUSPENDED', 'PENDING'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const adminCheck = await query(`SELECT a.id FROM admins a WHERE a.user_id = ?`, [userId]);
    const adminId = adminCheck.rows.length > 0 ? (adminCheck.rows[0] as any).id : null;

    let updateQuery = `UPDATE merchants SET approval_status = ?`;
    let queryParams: any[] = [status];

    if (status === 'APPROVED') {
      updateQuery += `, approved_by = ?, approved_at = NOW()`;
      queryParams.push(adminId);
    }

    updateQuery += ` WHERE id = ?`;
    queryParams.push(merchantId);

    await query(updateQuery, queryParams);

    res.status(200).json({ success: true, message: `Merchant status updated to ${status}` });
  } catch (error) {
    console.error('Error updating merchant status:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getProducts = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    if (!(await checkAdmin(userId))) return res.status(403).json({ error: 'Unauthorized' });

    const result = await query(`
      SELECT mp.id, mp.product_name, mp.is_active, c.name as category_name, b.name as brand_name,
             (SELECT COUNT(*) FROM master_product_variants mpv WHERE mpv.master_product_id = mp.id) as variants_count
      FROM master_products mp
      JOIN categories c ON mp.category_id = c.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      ORDER BY mp.created_at DESC
      LIMIT 100
    `);
    
    res.status(200).json({ products: result.rows });
  } catch (error) {
    console.error('Error in Admin getProducts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
