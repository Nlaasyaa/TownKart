-- =====================================================
-- 01_setup.sql
-- ENUMS, EXTENSIONS & FUNCTIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ENUMS
CREATE TYPE user_role AS ENUM ('CUSTOMER', 'MERCHANT', 'ADMIN');
CREATE TYPE approval_status_enum AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED');
CREATE TYPE shop_status_enum AS ENUM ('OPEN', 'BUSY', 'OFFLINE', 'CLOSED');
CREATE TYPE address_type_enum AS ENUM ('HOME', 'WORK', 'OTHER');
CREATE TYPE product_status_enum AS ENUM ('AVAILABLE', 'OUT_OF_STOCK', 'DISCONTINUED', 'HIDDEN');
CREATE TYPE inventory_transaction_type AS ENUM ('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT', 'DAMAGED');
CREATE TYPE order_status_enum AS ENUM ('PLACED', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED');
CREATE TYPE payment_method_enum AS ENUM ('COD', 'UPI');
CREATE TYPE payment_status_enum AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED');
CREATE TYPE subscription_status_enum AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELLED');

-- UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- SELLER CODE SEQUENCE
CREATE SEQUENCE seller_code_seq START WITH 1001 INCREMENT BY 1;

CREATE OR REPLACE FUNCTION generate_seller_code(category_letters TEXT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    next_code INTEGER;
BEGIN
    next_code := nextval('seller_code_seq');
    RETURN next_code || UPPER(category_letters);
END;
$$;
