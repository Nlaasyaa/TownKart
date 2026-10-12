-- =====================================================
-- 07_indexes_triggers.sql
-- TRIGGERS, SEED DATA AND INDEXES
-- =====================================================

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_customer_addresses_updated_at BEFORE UPDATE ON customer_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_admins_updated_at BEFORE UPDATE ON admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_merchants_updated_at BEFORE UPDATE ON merchants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_shops_updated_at BEFORE UPDATE ON shops FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_subcategories_updated_at BEFORE UPDATE ON subcategories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_master_products_updated_at BEFORE UPDATE ON master_products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_master_product_variants_updated_at BEFORE UPDATE ON master_product_variants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_merchant_products_updated_at BEFORE UPDATE ON merchant_products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_inventory_updated_at BEFORE UPDATE ON merchant_inventory FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_carts_updated_at BEFORE UPDATE ON carts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_merchant_orders_updated_at BEFORE UPDATE ON merchant_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_merchant_subscriptions_updated_at BEFORE UPDATE ON merchant_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- SEED DATA
INSERT INTO categories (name, code, display_order) VALUES
('Dairy', 'A', 1), ('Groceries', 'B', 2), ('Stationery', 'C', 3), ('Fruits', 'D', 4), ('Vegetables', 'E', 5);

INSERT INTO subcategories (category_id, name) VALUES
(2,'Rice'), (2,'Atta'), (2,'Oil'), (2,'Sugar'), (2,'Spices'), (2,'Dal'), (2,'Snacks'),
(1,'Milk'), (1,'Curd'), (1,'Butter'), (1,'Paneer'), (1,'Cheese'),
(3,'Notebook'), (3,'Pen'), (3,'Pencil'), (3,'Eraser'), (3,'Marker'), (3,'File'),
(4,'Apple'), (4,'Banana'), (4,'Orange'), (4,'Mango'), (4,'Grapes'),
(5,'Tomato'), (5,'Potato'), (5,'Onion'), (5,'Carrot'), (5,'Beans');

INSERT INTO units(name, symbol) VALUES
('Kilogram','kg'), ('Gram','g'), ('Liter','L'), ('Milliliter','ml'),
('Piece','pcs'), ('Pack','pack'), ('Bottle','bottle'), ('Box','box');


-- INDEXES
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_merchants_status ON merchants(approval_status);
CREATE INDEX idx_shops_status ON shops(shop_status);
CREATE INDEX idx_shop_location ON shops(latitude, longitude);
CREATE INDEX idx_customer_addresses_customer ON customer_addresses(customer_id);
CREATE INDEX idx_subcategories_category ON subcategories(category_id);
CREATE INDEX idx_merchant_categories_category ON merchant_categories(category_id);
CREATE INDEX idx_master_products_category ON master_products(category_id);
CREATE INDEX idx_master_products_subcategory ON master_products(subcategory_id);
CREATE INDEX idx_master_products_brand ON master_products(brand_id);
CREATE INDEX idx_master_products_name ON master_products(product_name);
CREATE INDEX idx_master_products_barcode ON master_products(barcode);
CREATE INDEX idx_master_product_variants_product ON master_product_variants(master_product_id);
CREATE INDEX idx_product_images_product ON product_images(master_product_id);
CREATE INDEX idx_merchant_products_merchant ON merchant_products(merchant_id);
CREATE INDEX idx_merchant_products_variant ON merchant_products(master_product_variant_id);
CREATE INDEX idx_merchant_products_status ON merchant_products(status);
CREATE INDEX idx_inventory_stock ON merchant_inventory(stock_quantity);
CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(merchant_product_id);
CREATE INDEX idx_cart_customer ON carts(customer_id);
CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_cart_items_product ON cart_items(merchant_product_id);
CREATE INDEX idx_reviews_product ON reviews(merchant_product_id);
CREATE INDEX idx_reviews_customer ON reviews(customer_id);
CREATE INDEX idx_wishlist_customer ON wishlists(customer_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_merchant_orders_order ON merchant_orders(order_id);
CREATE INDEX idx_merchant_orders_merchant ON merchant_orders(merchant_id);
CREATE INDEX idx_merchant_orders_status ON merchant_orders(status);
CREATE INDEX idx_order_items_order ON order_items(merchant_order_id);
CREATE INDEX idx_order_items_product ON order_items(merchant_product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_delivery_tracking_order ON delivery_tracking(merchant_order_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_subscription_merchant ON merchant_subscriptions(merchant_id);
CREATE INDEX idx_otp_phone ON otp_verifications(phone);
CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_id);
