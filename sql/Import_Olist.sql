-- ============================================================
-- OLIST IMPORT SCRIPT
-- Thay D:/archive bằng đường dẫn thực tế đến folder CSV
-- ============================================================

USE olist;

-- Tắt kiểm tra foreign key tạm thời để import nhanh hơn
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 1. customers
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

SELECT CONCAT('customers: ', COUNT(*), ' rows') AS status FROM customers;

-- ----------------------------
-- 2. products
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, product_name_length, product_description_length,
 product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm);

SELECT CONCAT('products: ', COUNT(*), ' rows') AS status FROM products;

-- ----------------------------
-- 3. sellers
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

SELECT CONCAT('sellers: ', COUNT(*), ' rows') AS status FROM sellers;

-- ----------------------------
-- 4. product_category_name_translation
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, product_category_name_english);

SELECT CONCAT('category_translation: ', COUNT(*), ' rows') AS status FROM product_category_name_translation;

-- ----------------------------
-- 5. orders
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status,
 order_purchase_timestamp, order_approved_at,
 order_delivered_carrier_date, order_delivered_customer_date,
 order_estimated_delivery_date);

SELECT CONCAT('orders: ', COUNT(*), ' rows') AS status FROM orders;

-- ----------------------------
-- 6. order_items
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id,
 shipping_limit_date, price, freight_value);

SELECT CONCAT('order_items: ', COUNT(*), ' rows') AS status FROM order_items;

-- ----------------------------
-- 7. order_payments
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

SELECT CONCAT('order_payments: ', COUNT(*), ' rows') AS status FROM order_payments;

-- ----------------------------
-- 8. order_reviews
-- ----------------------------
LOAD DATA LOCAL INFILE 'D:/archive/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title,
 review_comment_message, review_creation_date, review_answer_timestamp);

SELECT CONCAT('order_reviews: ', COUNT(*), ' rows') AS status FROM order_reviews;

-- Bật lại foreign key check
SET FOREIGN_KEY_CHECKS = 1;

-- Kiểm tra tổng kết
SELECT 'customers'     AS tbl, COUNT(*) AS Number_Rows FROM customers
UNION ALL SELECT 'orders',         COUNT(*) FROM orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'products',       COUNT(*) FROM products
UNION ALL SELECT 'sellers',        COUNT(*) FROM sellers
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM order_reviews;