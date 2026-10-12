import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// A wrapper to maintain compatibility with existing controller code
export const query = async (text: string, params?: any[]) => {
  const [result] = await pool.query(text, params);
  if (Array.isArray(result)) {
    return { rows: result };
  } else {
    return { rows: [result], insertId: (result as any).insertId };
  }
};

export default pool;
