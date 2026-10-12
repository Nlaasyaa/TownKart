-- =====================================================
-- 04_merchant_inventory.sql
-- MERCHANT PRODUCTS, INVENTORY, TRANSACTIONS
-- =====================================================

CREATE TABLE merchant_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    master_product_variant_id UUID NOT NULL REFERENCES master_product_variants(id) ON DELETE RESTRICT,
    selling_price NUMERIC(10,2) NOT NULL CHECK (selling_price >= 0),
    mrp NUMERIC(10,2) CHECK (mrp >= 0),
    purchase_price NUMERIC(10,2) CHECK (purchase_price >= 0),
    minimum_stock INTEGER NOT NULL DEFAULT 5 CHECK (minimum_stock >= 0),
    status product_status_enum DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(merchant_id, master_product_variant_id)
);

CREATE TABLE merchant_inventory (
    merchant_product_id UUID PRIMARY KEY REFERENCES merchant_products(id) ON DELETE CASCADE,
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
    reserved_quantity INTEGER NOT NULL DEFAULT 0 CHECK(reserved_quantity >= 0),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_product_id UUID NOT NULL REFERENCES merchant_products(id) ON DELETE CASCADE,
    transaction_type inventory_transaction_type NOT NULL,
    quantity INTEGER NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
