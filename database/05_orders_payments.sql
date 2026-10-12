-- =====================================================
-- 05_orders_payments.sql
-- ORDERS, PAYMENTS, DELIVERY
-- =====================================================

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    address_id UUID NOT NULL REFERENCES customer_addresses(id) ON DELETE RESTRICT,
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    delivery_charge NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (delivery_charge >= 0),
    tax NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
    grand_total NUMERIC(10,2) NOT NULL CHECK (grand_total >= 0),
    payment_method payment_method_enum NOT NULL,
    payment_status payment_status_enum NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE merchant_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE RESTRICT,
    status order_status_enum NOT NULL DEFAULT 'PLACED',
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0,
    delivery_charge NUMERIC(10,2) NOT NULL DEFAULT 0,
    tax NUMERIC(10,2) NOT NULL DEFAULT 0,
    total NUMERIC(10,2) NOT NULL DEFAULT 0,
    estimated_delivery TIMESTAMP,
    accepted_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_order_id UUID NOT NULL REFERENCES merchant_orders(id) ON DELETE CASCADE,
    merchant_product_id UUID NOT NULL REFERENCES merchant_products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK(unit_price >= 0),
    total_price NUMERIC(10,2) NOT NULL CHECK(total_price >= 0)
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK(amount >= 0),
    payment_method payment_method_enum NOT NULL,
    transaction_id VARCHAR(150),
    status payment_status_enum NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE delivery_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_order_id UUID NOT NULL REFERENCES merchant_orders(id) ON DELETE CASCADE,
    status order_status_enum NOT NULL,
    remarks TEXT,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE delivery_settings (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    minimum_order NUMERIC(10,2) NOT NULL,
    free_delivery_above NUMERIC(10,2) NOT NULL,
    delivery_fee NUMERIC(10,2) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO delivery_settings (minimum_order, free_delivery_above, delivery_fee) VALUES (0, 500, 40);
