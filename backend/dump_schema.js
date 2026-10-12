const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'townkart',
  password: 'sql@123',
  port: 5432
});

async function run() {
  try {
    const res = await pool.query(`
      SELECT table_name, column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      ORDER BY table_name, ordinal_position;
    `);
    
    const fs = require('fs');
    fs.writeFileSync('schema_dump.json', JSON.stringify(res.rows, null, 2));
    console.log("Schema dumped to schema_dump.json");
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}

run();
