import { Request, Response } from 'express';
import { query } from '../config/db';
import { randomUUID } from 'crypto';

export const registerCustomer = async (req: Request, res: Response) => {
  try {
    const { fullName, email, phone, password } = req.body;

    if (!fullName || !email || !phone || !password) {
      return res.status(400).json({ error: 'Full name, email, phone, and password are required' });
    }

    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters long' });
    }

    // Check if this email or phone is already registered
    const userCheck = await query('SELECT id FROM users WHERE email = ? OR phone = ?', [email, phone]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ error: 'This email or phone is already registered. Please log in.' });
    }

    // 1. Insert into users table
    const userId = randomUUID();
    await query(
      `INSERT INTO users (id, email, phone, password_hash, role) VALUES (?, ?, ?, ?, 'CUSTOMER')`,
      [userId, email, phone, password]
    );

    // 2. Insert into customers table with the actual full name
    const customerId = randomUUID();
    await query(
      `INSERT INTO customers (id, user_id, full_name) VALUES (?, ?, ?)`,
      [customerId, userId, fullName]
    );

    res.status(201).json({ message: 'Registration successful', userId });
  } catch (error) {
    console.error('Error in registerCustomer:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const registerMerchant = async (req: Request, res: Response) => {
  try {
    const { ownerName, email, phone, gstNumber, shopName, shopAddress, categories, password } = req.body;

    if (!password) {
      return res.status(400).json({ error: 'Password is required' });
    }

    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters long' });
    }

    // Always use email as the userId
    const userId = email;

    // Check if a user with this email or phone already exists
    const userCheck = await query('SELECT id FROM users WHERE email = ? OR phone = ?', [email, phone]);

    if (userCheck.rows.length > 0) {
      const existingId = (userCheck.rows[0] as any).id;

      // Check if this existing user is already a merchant
      const merchantCheck = await query('SELECT id FROM merchants WHERE user_id = ?', [existingId]);
      if (merchantCheck.rows.length > 0) {
        return res.status(400).json({ error: 'This email or phone is already registered as a merchant' });
      }

      // If the existing user row has a UUID id (not the email), delete it and re-insert with email as id
      if (existingId !== userId) {
        await query('DELETE FROM users WHERE id = ?', [existingId]);
        await query(
          `INSERT INTO users (id, email, phone, password_hash, role) VALUES (?, ?, ?, ?, 'MERCHANT')`,
          [userId, email, phone, password]
        );
      }
    } else {
      await query(
        `INSERT INTO users (id, email, phone, password_hash, role) VALUES (?, ?, ?, ?, 'MERCHANT')`,
        [userId, email, phone, password]
      );
    }

    // Insert Merchant
    const merchantId = randomUUID();
    const categoryLetters = shopName ? shopName.substring(0, 2).toUpperCase() : 'SH';
    const sellerCode = merchantId.substring(0, 8).toUpperCase() + categoryLetters;

    await query(
      `INSERT INTO merchants (id, user_id, owner_name, gst_number, seller_code) VALUES (?, ?, ?, ?, ?)`,
      [merchantId, userId, ownerName, gstNumber || null, sellerCode]
    );

    // Insert Shop
    const shopId = randomUUID();
    await query(
      `INSERT INTO shops (id, merchant_id, shop_name, address, city, state, pincode, latitude, longitude) VALUES (?, ?, ?, ?, 'Pune', 'MH', '410507', 18.7362, 73.6734)`,
      [shopId, merchantId, shopName, shopAddress]
    );

    // Insert Categories
    if (categories && Array.isArray(categories) && categories.length > 0) {
      for (const catName of categories) {
        const catCheck = await query('SELECT id FROM categories WHERE name = ?', [catName]);
        if (catCheck.rows.length > 0) {
          const catId = (catCheck.rows[0] as any).id;
          await query('INSERT IGNORE INTO merchant_categories (merchant_id, category_id) VALUES (?, ?)', [merchantId, catId]);
        }
      }
    }

    res.status(201).json({
      message: 'Merchant Registration successful',
      shopId: shopId,
      sellerCode: sellerCode
    });
  } catch (error) {
    console.error('Error in registerMerchant:', error);
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
};

export const loginUser = async (req: Request, res: Response) => {
  try {
    const { contact, password } = req.body; // contact can be email or phone

    if (!password) {
      return res.status(400).json({ error: 'Password is required' });
    }

    const userCheck = await query(
      'SELECT id, role, password_hash FROM users WHERE email = ? OR phone = ?',
      [contact, contact]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found. Please sign up first.' });
    }

    const user: any = userCheck.rows[0];
    if (user.password_hash !== password) {
      return res.status(401).json({ error: 'Invalid password' });
    }

    res.status(200).json({
      message: 'Login successful',
      userId: user.id,
      role: user.role
    });
  } catch (error) {
    console.error('Error in loginUser:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const sendOtp = async (req: Request, res: Response) => {
  try {
    const { contact } = req.body;

    // Here we would integrate with SMS/Email provider like Twilio or AWS SNS
    // For now we just mock success
    console.log(`Mocking sending OTP to: ${contact}`);

    res.status(200).json({ message: 'OTP sent successfully' });
  } catch (error) {
    console.error('Error in sendOtp:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
