-- =====================================================
-- 02_users.sql
-- USERS, CUSTOMERS, ADMINS, MERCHANTS, SHOPS
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT,
    role user_role NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(120) NOT NULL,
    profile_image TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_type address_type_enum DEFAULT 'HOME',
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    landmark TEXT,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    country VARCHAR(80) NOT NULL DEFAULT 'India',
    pincode VARCHAR(10) NOT NULL,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(120) NOT NULL,
    designation VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    owner_name VARCHAR(120) NOT NULL,
    gst_number VARCHAR(30),
    seller_code VARCHAR(20) UNIQUE NOT NULL,
    approval_status approval_status_enum DEFAULT 'PENDING',
    approved_by UUID REFERENCES admins(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL UNIQUE REFERENCES merchants(id) ON DELETE CASCADE,
    shop_name VARCHAR(150) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    country VARCHAR(80) NOT NULL DEFAULT 'India',
    pincode VARCHAR(10) NOT NULL,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    working_hours VARCHAR(100),
    shop_status shop_status_enum DEFAULT 'OPEN',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
