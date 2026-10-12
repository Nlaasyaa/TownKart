import { query } from './src/config/db';
import { randomUUID } from 'crypto';

async function seedAdmin() {
  try {
    const email = 'ops@townkart.in';
    const password = 'password123'; // As per screenshot mask

    const check = await query('SELECT id FROM users WHERE email = ?', [email]);
    if (check.rows.length > 0) {
      console.log('Admin already exists.');
      process.exit(0);
    }

    const userId = randomUUID();
    await query(
      `INSERT INTO users (id, email, phone, password_hash, role, is_verified) 
       VALUES (?, ?, ?, ?, 'ADMIN', TRUE)`,
      [userId, email, '0000000000', password]
    );

    const adminId = randomUUID();
    await query(
      `INSERT INTO admins (id, user_id, full_name, designation) VALUES (?, ?, ?, ?)`,
      [adminId, userId, 'Aditi Rao', 'Platform Admin']
    );

    console.log('Admin seeded successfully! Email: ops@townkart.in, Password: password123');
    process.exit(0);
  } catch (err) {
    console.error('Failed to seed admin', err);
    process.exit(1);
  }
}

seedAdmin();
