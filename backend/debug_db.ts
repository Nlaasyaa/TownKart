import { query } from './src/config/db';

async function run() {
  try {
    const users = await query('SELECT id, role, email, phone FROM users');
    console.log('--- USERS ---');
    console.log(users.rows);

    const merchants = await query('SELECT id, user_id, owner_name FROM merchants');
    console.log('--- MERCHANTS ---');
    console.log(merchants.rows);

    const shops = await query('SELECT id, merchant_id, shop_name FROM shops');
    console.log('--- SHOPS ---');
    console.log(shops.rows);
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
