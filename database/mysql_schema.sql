-- =====================================================
-- mysql_schema.sql
-- Consolidated MySQL Setup Script for TownKart
-- =====================================================

-- Users
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT,
    role ENUM('CUSTOMER', 'MERCHANT', 'ADMIN') NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_login DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    profile_image TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE customer_addresses (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id VARCHAR(36) NOT NULL,
    address_type ENUM('HOME', 'WORK', 'OTHER') DEFAULT 'HOME',
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    landmark TEXT,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    country VARCHAR(80) NOT NULL DEFAULT 'India',
    pincode VARCHAR(10) NOT NULL,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    is_default BOOLEAN DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE admins (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    designation VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE merchants (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL UNIQUE,
    owner_name VARCHAR(120) NOT NULL,
    gst_number VARCHAR(30),
    seller_code VARCHAR(20) UNIQUE NOT NULL,
    approval_status ENUM('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED') DEFAULT 'PENDING',
    approved_by VARCHAR(36),
    approved_at DATETIME,
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES admins(id) ON DELETE SET NULL
);

CREATE TABLE shops (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    merchant_id VARCHAR(36) NOT NULL UNIQUE,
    shop_name VARCHAR(150) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    country VARCHAR(80) NOT NULL DEFAULT 'India',
    pincode VARCHAR(10) NOT NULL,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    working_hours VARCHAR(100),
    shop_status ENUM('OPEN', 'BUSY', 'OFFLINE', 'CLOSED') DEFAULT 'OPEN',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE
);

-- Catalog
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    code CHAR(1) NOT NULL UNIQUE,
    icon TEXT,
    display_order INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE subcategories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(120) NOT NULL,
    display_order INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(category_id, name)
);

CREATE TABLE merchant_categories (
    merchant_id VARCHAR(36) NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (merchant_id, category_id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

CREATE TABLE units (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE brands (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(120) NOT NULL UNIQUE,
    logo_url TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE master_products (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    category_id INT NOT NULL,
    subcategory_id INT,
    brand_id VARCHAR(36),
    unit_id INT,
    product_name VARCHAR(200) NOT NULL,
    barcode VARCHAR(100),
    hsn_code VARCHAR(30),
    description TEXT,
    tax_percentage DECIMAL(5,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE SET NULL,
    FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
    UNIQUE (brand_id, product_name)
);

CREATE TABLE master_product_variants (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    master_product_id VARCHAR(36) NOT NULL,
    variant_name VARCHAR(50) NOT NULL,
    sort_order INT DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (master_product_id) REFERENCES master_products(id) ON DELETE CASCADE,
    UNIQUE(master_product_id, variant_name)
);

CREATE TABLE product_images (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    master_product_id VARCHAR(36) NOT NULL,
    image_url TEXT NOT NULL,
    display_order INT DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (master_product_id) REFERENCES master_products(id) ON DELETE CASCADE
);

-- Merchant Inventory
CREATE TABLE merchant_products (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    merchant_id VARCHAR(36) NOT NULL,
    master_product_variant_id VARCHAR(36) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    mrp DECIMAL(10,2),
    purchase_price DECIMAL(10,2),
    minimum_stock INT NOT NULL DEFAULT 5,
    status ENUM('AVAILABLE', 'OUT_OF_STOCK', 'DISCONTINUED', 'HIDDEN') DEFAULT 'AVAILABLE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE,
    FOREIGN KEY (master_product_variant_id) REFERENCES master_product_variants(id) ON DELETE RESTRICT,
    UNIQUE(merchant_id, master_product_variant_id)
);

CREATE TABLE merchant_inventory (
    merchant_product_id VARCHAR(36) PRIMARY KEY,
    stock_quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (merchant_product_id) REFERENCES merchant_products(id) ON DELETE CASCADE
);

CREATE TABLE inventory_transactions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    merchant_product_id VARCHAR(36) NOT NULL,
    transaction_type ENUM('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT', 'DAMAGED') NOT NULL,
    quantity INT NOT NULL,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (merchant_product_id) REFERENCES merchant_products(id) ON DELETE CASCADE
);

-- Orders
CREATE TABLE orders (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id VARCHAR(36) NOT NULL,
    address_id VARCHAR(36) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    delivery_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax DECIMAL(10,2) NOT NULL DEFAULT 0,
    grand_total DECIMAL(10,2) NOT NULL,
    payment_method ENUM('COD', 'UPI') NOT NULL,
    payment_status ENUM('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    FOREIGN KEY (address_id) REFERENCES customer_addresses(id) ON DELETE RESTRICT
);

CREATE TABLE merchant_orders (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    order_id VARCHAR(36) NOT NULL,
    merchant_id VARCHAR(36) NOT NULL,
    status ENUM('PLACED', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED') NOT NULL DEFAULT 'PLACED',
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    delivery_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    estimated_delivery DATETIME,
    accepted_at DATETIME,
    delivered_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE RESTRICT
);

CREATE TABLE order_items (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    merchant_order_id VARCHAR(36) NOT NULL,
    merchant_product_id VARCHAR(36) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (merchant_order_id) REFERENCES merchant_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (merchant_product_id) REFERENCES merchant_products(id) ON DELETE RESTRICT
);

CREATE TABLE payments (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    order_id VARCHAR(36) NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('COD', 'UPI') NOT NULL,
    transaction_id VARCHAR(150),
    status ENUM('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    paid_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

CREATE TABLE delivery_tracking (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    merchant_order_id VARCHAR(36) NOT NULL,
    status ENUM('PLACED', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED') NOT NULL,
    remarks TEXT,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (merchant_order_id) REFERENCES merchant_orders(id) ON DELETE CASCADE
);

CREATE TABLE delivery_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    minimum_order DECIMAL(10,2) NOT NULL,
    free_delivery_above DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO delivery_settings (minimum_order, free_delivery_above, delivery_fee) VALUES (0, 500, 40);

-- Misc
CREATE TABLE carts (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id VARCHAR(36) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    cart_id VARCHAR(36) NOT NULL,
    merchant_product_id VARCHAR(36) NOT NULL,
    quantity INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
    FOREIGN KEY (merchant_product_id) REFERENCES merchant_products(id) ON DELETE CASCADE,
    UNIQUE(cart_id, merchant_product_id)
);

CREATE TABLE wishlists (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id VARCHAR(36) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE wishlist_items (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    wishlist_id VARCHAR(36) NOT NULL,
    master_product_id VARCHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wishlist_id) REFERENCES wishlists(id) ON DELETE CASCADE,
    FOREIGN KEY (master_product_id) REFERENCES master_products(id) ON DELETE CASCADE,
    UNIQUE(wishlist_id, master_product_id)
);

CREATE TABLE reviews (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id VARCHAR(36) NOT NULL,
    merchant_product_id VARCHAR(36) NOT NULL,
    rating INT NOT NULL,
    review TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (merchant_product_id) REFERENCES merchant_products(id) ON DELETE CASCADE,
    UNIQUE(customer_id, merchant_product_id)
);

CREATE TABLE merchant_subscriptions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    merchant_id VARCHAR(36) NOT NULL,
    plan_name VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    start_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status ENUM('ACTIVE', 'EXPIRED', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE
);

CREATE TABLE notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE otp_verifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    phone VARCHAR(20) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admin_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    admin_id VARCHAR(36) NOT NULL,
    action TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE
);
