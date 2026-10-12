-- =====================================================
-- 03_catalog.sql
-- CATEGORIES, PRODUCTS, BRANDS, UNITS
-- =====================================================

CREATE TABLE categories (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    code CHAR(1) NOT NULL UNIQUE,
    icon TEXT,
    display_order INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE subcategories (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    display_order INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category_id, name)
);

CREATE TABLE merchant_categories (
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (merchant_id, category_id)
);

CREATE TABLE units (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL UNIQUE,
    logo_url TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE master_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    subcategory_id INTEGER REFERENCES subcategories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
    unit_id INTEGER REFERENCES units(id) ON DELETE RESTRICT,
    product_name VARCHAR(200) NOT NULL,
    barcode VARCHAR(100),
    hsn_code VARCHAR(30),
    description TEXT,
    tax_percentage NUMERIC(5,2) DEFAULT 0 CHECK (tax_percentage >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (brand_id, product_name)
);

CREATE TABLE master_product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_product_id UUID NOT NULL REFERENCES master_products(id) ON DELETE CASCADE,
    variant_name VARCHAR(50) NOT NULL,
    sort_order INTEGER DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(master_product_id, variant_name)
);

CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_product_id UUID NOT NULL REFERENCES master_products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
