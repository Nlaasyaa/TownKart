import { query } from './src/config/db';
import { randomUUID } from 'crypto';

// This script seeds the database with:
// - Categories, Subcategories, Units, and Master Products with Variants

async function seedCatalog() {
  try {
    console.log('🌱 Starting catalog seed...');

    // ── 1. Categories ──────────────────────────────
    // Change code for Beverages to 'Bv' to avoid conflicts with existing 'B' entries
    const categories = [
      { name: 'Groceries', code: 'G' },
      { name: 'Dairy', code: 'D' },
      { name: 'Fruits', code: 'F' },
      { name: 'Vegetables', code: 'V' },
      { name: 'Beverages', code: 'W' },  // W = "Water/drinks" to avoid DB conflicts
      { name: 'Snacks', code: 'S' },
    ];

    const categoryIds: Record<string, number> = {};
    for (const cat of categories) {
      // Use INSERT IGNORE to skip any duplicate name or code conflicts
      await query(
        'INSERT IGNORE INTO categories (name, code, is_active) VALUES (?, ?, true)',
        [cat.name, cat.code]
      );
      const result = await query('SELECT id FROM categories WHERE name = ?', [cat.name]);
      if (result.rows.length > 0) {
        categoryIds[cat.name] = (result.rows[0] as any).id;
        console.log(`   ✅ Category "${cat.name}" ready (id=${categoryIds[cat.name]}).`);
      } else {
        console.warn(`   ⚠️ Could not find or insert category "${cat.name}" — skipping.`);
      }
    }

    // ── 2. Subcategories ───────────────────────────
    const subcategories: Array<{ category: string; name: string }> = [
      { category: 'Groceries', name: 'Rice' },
      { category: 'Groceries', name: 'Wheat & Flour' },
      { category: 'Groceries', name: 'Pulses & Lentils' },
      { category: 'Groceries', name: 'Spices & Masalas' },
      { category: 'Groceries', name: 'Oils & Ghee' },
      { category: 'Dairy', name: 'Milk' },
      { category: 'Dairy', name: 'Paneer & Tofu' },
      { category: 'Dairy', name: 'Butter & Cheese' },
      { category: 'Dairy', name: 'Curd & Lassi' },
      { category: 'Fruits', name: 'Tropical Fruits' },
      { category: 'Fruits', name: 'Citrus Fruits' },
      { category: 'Vegetables', name: 'Leafy Greens' },
      { category: 'Vegetables', name: 'Root Vegetables' },
      { category: 'Beverages', name: 'Tea & Coffee' },
      { category: 'Beverages', name: 'Juices' },
      { category: 'Snacks', name: 'Chips & Namkeen' },
      { category: 'Snacks', name: 'Biscuits & Cookies' },
    ];

    const subcategoryIds: Record<string, number> = {};
    for (const sub of subcategories) {
      const catId = categoryIds[sub.category];
      if (!catId) {
        console.warn(`   ⚠️ Category "${sub.category}" not found for subcategory "${sub.name}", skipping.`);
        continue;
      }
      await query(
        'INSERT IGNORE INTO subcategories (category_id, name, is_active) VALUES (?, ?, true)',
        [catId, sub.name]
      );
      const result = await query('SELECT id FROM subcategories WHERE name = ? AND category_id = ?', [sub.name, catId]);
      if (result.rows.length > 0) {
        subcategoryIds[sub.name] = (result.rows[0] as any).id;
        console.log(`   ✅ Subcategory "${sub.name}" ready.`);
      }
    }

    // ── 3. Unit ──────────────────────────────────
    let kgUnitId: number;
    const unitCheck = await query('SELECT id FROM units WHERE symbol = ?', ['kg']);
    if (unitCheck.rows.length > 0) {
      kgUnitId = (unitCheck.rows[0] as any).id;
    } else {
      await query('INSERT INTO units (name, symbol) VALUES (?, ?)', ['Kilogram', 'kg']);
      const unitRes = await query('SELECT id FROM units WHERE symbol = ?', ['kg']);
      kgUnitId = (unitRes.rows[0] as any).id;
      console.log('   ✅ Unit "kg" created.');
    }

    let ltrUnitId: number;
    const ltrCheck = await query('SELECT id FROM units WHERE symbol = ?', ['L']);
    if (ltrCheck.rows.length > 0) {
      ltrUnitId = (ltrCheck.rows[0] as any).id;
    } else {
      await query('INSERT INTO units (name, symbol) VALUES (?, ?)', ['Litre', 'L']);
      const unitRes = await query('SELECT id FROM units WHERE symbol = ?', ['L']);
      ltrUnitId = (unitRes.rows[0] as any).id;
      console.log('   ✅ Unit "L" created.');
    }

    // ── Extra: Load ALL pre-existing subcategories from the DB by name ──
    const allExistingSubs = await query('SELECT id, name FROM subcategories');
    for (const row of allExistingSubs.rows as any[]) {
      subcategoryIds[row.name] = row.id;
    }
    console.log(`   ✅ Loaded ${allExistingSubs.rows.length} existing subcategories.`);

    // ── 4. Master Products with Variants ──────────
    // These subcategory names EXACTLY match what's in the DB
    const masterProducts: Array<{
      category: string;
      subcategory: string;
      name: string;
      unit: string;
      variants: string[];
    }> = [
      // Groceries > Rice
      { category: 'Groceries', subcategory: 'Rice', name: 'Basmati Rice', unit: 'kg', variants: ['1kg', '5kg', '10kg', '25kg'] },
      { category: 'Groceries', subcategory: 'Rice', name: 'Sona Masoori Rice', unit: 'kg', variants: ['1kg', '5kg', '10kg'] },
      { category: 'Groceries', subcategory: 'Rice', name: 'Brown Rice', unit: 'kg', variants: ['1kg', '5kg'] },
      // Groceries > Atta
      { category: 'Groceries', subcategory: 'Atta', name: 'Aashirvaad Atta', unit: 'kg', variants: ['1kg', '5kg', '10kg'] },
      { category: 'Groceries', subcategory: 'Atta', name: 'Pillsbury Chakki Atta', unit: 'kg', variants: ['1kg', '5kg'] },
      { category: 'Groceries', subcategory: 'Atta', name: 'Patanjali Atta', unit: 'kg', variants: ['1kg', '5kg', '10kg'] },
      // Groceries > Oil
      { category: 'Groceries', subcategory: 'Oil', name: 'Sunflower Oil', unit: 'L', variants: ['500ml', '1L', '5L'] },
      { category: 'Groceries', subcategory: 'Oil', name: 'Groundnut Oil', unit: 'L', variants: ['500ml', '1L', '5L'] },
      { category: 'Groceries', subcategory: 'Oil', name: 'Mustard Oil', unit: 'L', variants: ['500ml', '1L'] },
      // Groceries > Sugar
      { category: 'Groceries', subcategory: 'Sugar', name: 'White Sugar', unit: 'kg', variants: ['500g', '1kg', '5kg'] },
      { category: 'Groceries', subcategory: 'Sugar', name: 'Brown Sugar', unit: 'kg', variants: ['500g', '1kg'] },
      { category: 'Groceries', subcategory: 'Sugar', name: 'Jaggery (Gur)', unit: 'kg', variants: ['250g', '500g', '1kg'] },
      // Groceries > Spices
      { category: 'Groceries', subcategory: 'Spices', name: 'Turmeric Powder', unit: 'kg', variants: ['100g', '200g', '500g'] },
      { category: 'Groceries', subcategory: 'Spices', name: 'Red Chilli Powder', unit: 'kg', variants: ['100g', '200g', '500g'] },
      { category: 'Groceries', subcategory: 'Spices', name: 'Coriander Powder', unit: 'kg', variants: ['100g', '200g'] },
      { category: 'Groceries', subcategory: 'Spices', name: 'Garam Masala', unit: 'kg', variants: ['50g', '100g', '200g'] },
      // Groceries > Dal
      { category: 'Groceries', subcategory: 'Dal', name: 'Toor Dal', unit: 'kg', variants: ['500g', '1kg', '5kg'] },
      { category: 'Groceries', subcategory: 'Dal', name: 'Moong Dal', unit: 'kg', variants: ['500g', '1kg'] },
      { category: 'Groceries', subcategory: 'Dal', name: 'Chana Dal', unit: 'kg', variants: ['500g', '1kg'] },
      { category: 'Groceries', subcategory: 'Dal', name: 'Masoor Dal', unit: 'kg', variants: ['500g', '1kg'] },
      // Groceries > Snacks
      { category: 'Groceries', subcategory: 'Snacks', name: 'Lays Classic Salted', unit: 'kg', variants: ['26g', '40g', '80g'] },
      { category: 'Groceries', subcategory: 'Snacks', name: 'Parle G Biscuits', unit: 'kg', variants: ['100g', '200g', '800g'] },
      { category: 'Groceries', subcategory: 'Snacks', name: 'Haldiram Namkeen', unit: 'kg', variants: ['200g', '400g'] },
      // Dairy > Milk
      { category: 'Dairy', subcategory: 'Milk', name: 'Full Cream Milk', unit: 'L', variants: ['500ml', '1L'] },
      { category: 'Dairy', subcategory: 'Milk', name: 'Toned Milk', unit: 'L', variants: ['500ml', '1L'] },
      { category: 'Dairy', subcategory: 'Milk', name: 'Skimmed Milk', unit: 'L', variants: ['500ml', '1L'] },
      // Dairy > Curd
      { category: 'Dairy', subcategory: 'Curd', name: 'Amul Dahi', unit: 'kg', variants: ['200g', '400g', '1kg'] },
      { category: 'Dairy', subcategory: 'Curd', name: 'Nestle Nestea Curd', unit: 'kg', variants: ['200g', '400g'] },
      // Dairy > Butter
      { category: 'Dairy', subcategory: 'Butter', name: 'Amul Butter', unit: 'kg', variants: ['100g', '200g', '500g'] },
      { category: 'Dairy', subcategory: 'Butter', name: 'Mother Dairy Butter', unit: 'kg', variants: ['100g', '200g'] },
      // Dairy > Paneer
      { category: 'Dairy', subcategory: 'Paneer', name: 'Fresh Paneer', unit: 'kg', variants: ['200g', '500g', '1kg'] },
      { category: 'Dairy', subcategory: 'Paneer', name: 'Amul Paneer', unit: 'kg', variants: ['200g', '500g'] },
      // Dairy > Cheese
      { category: 'Dairy', subcategory: 'Cheese', name: 'Amul Cheese Slices', unit: 'kg', variants: ['100g', '200g'] },
      { category: 'Dairy', subcategory: 'Cheese', name: 'Britannia Cheese Spread', unit: 'kg', variants: ['180g'] },
      // Fruits > Apple
      { category: 'Fruits', subcategory: 'Apple', name: 'Shimla Apple', unit: 'kg', variants: ['500g', '1kg', '2kg'] },
      { category: 'Fruits', subcategory: 'Apple', name: 'Green Apple', unit: 'kg', variants: ['500g', '1kg'] },
      // Fruits > Banana
      { category: 'Fruits', subcategory: 'Banana', name: 'Robusta Banana', unit: 'kg', variants: ['Dozen', '½kg', '1kg'] },
      { category: 'Fruits', subcategory: 'Banana', name: 'Nendran Banana', unit: 'kg', variants: ['Dozen'] },
      // Fruits > Orange
      { category: 'Fruits', subcategory: 'Orange', name: 'Nagpur Orange', unit: 'kg', variants: ['500g', '1kg', '2kg'] },
      { category: 'Fruits', subcategory: 'Orange', name: 'Mosambi (Sweet Lime)', unit: 'kg', variants: ['500g', '1kg'] },
      // Fruits > Mango
      { category: 'Fruits', subcategory: 'Mango', name: 'Alphonso Mango', unit: 'kg', variants: ['Dozen', '1kg'] },
      { category: 'Fruits', subcategory: 'Mango', name: 'Kesar Mango', unit: 'kg', variants: ['Dozen', '1kg'] },
      // Fruits > Grapes
      { category: 'Fruits', subcategory: 'Grapes', name: 'Green Grapes', unit: 'kg', variants: ['500g', '1kg'] },
      { category: 'Fruits', subcategory: 'Grapes', name: 'Black Grapes', unit: 'kg', variants: ['500g', '1kg'] },
      // Vegetables > Tomato
      { category: 'Vegetables', subcategory: 'Tomato', name: 'Fresh Tomato', unit: 'kg', variants: ['250g', '500g', '1kg'] },
      // Vegetables > Potato
      { category: 'Vegetables', subcategory: 'Potato', name: 'Fresh Potato', unit: 'kg', variants: ['500g', '1kg', '5kg'] },
      // Vegetables > Onion
      { category: 'Vegetables', subcategory: 'Onion', name: 'Red Onion', unit: 'kg', variants: ['500g', '1kg', '5kg'] },
      // Vegetables > Carrot
      { category: 'Vegetables', subcategory: 'Carrot', name: 'Fresh Carrot', unit: 'kg', variants: ['250g', '500g', '1kg'] },
      // Vegetables > Beans
      { category: 'Vegetables', subcategory: 'Beans', name: 'French Beans', unit: 'kg', variants: ['250g', '500g'] },
      { category: 'Vegetables', subcategory: 'Beans', name: 'Cluster Beans (Gavar)', unit: 'kg', variants: ['250g', '500g'] },
    ];


    for (const prod of masterProducts) {
      const catId = categoryIds[prod.category];
      const subId = subcategoryIds[prod.subcategory];
      const unitId = prod.unit === 'kg' ? kgUnitId : ltrUnitId;

      // Skip if category or subcategory couldn't be resolved
      if (!catId) {
        console.warn(`   ⚠️ Skipping product "${prod.name}" — category "${prod.category}" not found.`);
        continue;
      }
      if (!subId) {
        console.warn(`   ⚠️ Skipping product "${prod.name}" — subcategory "${prod.subcategory}" not found.`);
        continue;
      }

      const existing = await query('SELECT id FROM master_products WHERE product_name = ? AND category_id = ?', [prod.name, catId]);
      let productId: string;

      if (existing.rows.length > 0) {
        productId = (existing.rows[0] as any).id;
        console.log(`   Product "${prod.name}" already exists.`);
      } else {
        productId = randomUUID();
        await query(
          `INSERT INTO master_products (id, category_id, subcategory_id, unit_id, product_name, is_active)
           VALUES (?, ?, ?, ?, ?, true)`,
          [productId, catId, subId, unitId, prod.name]
        );
        console.log(`   ✅ Product "${prod.name}" created.`);
      }

      // Insert variants
      for (const variant of prod.variants) {
        const variantCheck = await query(
          'SELECT id FROM master_product_variants WHERE master_product_id = ? AND variant_name = ?',
          [productId, variant]
        );
        if (variantCheck.rows.length === 0) {
          await query(
            'INSERT INTO master_product_variants (id, master_product_id, variant_name) VALUES (?, ?, ?)',
            [randomUUID(), productId, variant]
          );
          console.log(`      ✅ Variant "${variant}" added to "${prod.name}".`);
        }
      }
    }

    console.log('\n✅ Catalog seed complete!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed to seed catalog:', err);
    process.exit(1);
  }
}

seedCatalog();
