-- ============================================================
-- OLIST E-COMMERCE SALES ANALYTICS
-- Stack: MySQL / PostgreSQL
-- Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
-- Author: Trung Quân
-- ============================================================


-- ============================================================
-- SECTION 0: DATABASE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist;
USE olist;

-- Sau khi import CSV từ Kaggle, bảng chính gồm:
--   orders, order_items, order_payments, order_reviews,
--   customers, products, product_category_name_translation, sellers, geolocation


-- ============================================================
-- SECTION 1: DATA EXPLORATION
-- ============================================================

-- 1.1 Tổng quan dataset
SELECT 
    'orders'             AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL SELECT 'order_items',         COUNT(*) FROM order_items
UNION ALL SELECT 'customers',           COUNT(*) FROM customers
UNION ALL SELECT 'products',            COUNT(*) FROM products
UNION ALL SELECT 'sellers',             COUNT(*) FROM sellers
UNION ALL SELECT 'order_payments',      COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',       COUNT(*) FROM order_reviews;

-- 1.2 Kiểm tra khoảng thời gian dữ liệu
SELECT 
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order,
    COUNT(DISTINCT DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) AS total_months
FROM orders;

-- 1.3 Phân bố trạng thái đơn hàng
SELECT 
    order_status,
    COUNT(*)                                    AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 1.4 Kiểm tra null ở các cột quan trọng
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)                    AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)                 AS null_customer_id,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)    AS null_purchase_ts,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered_date
FROM orders;


-- ============================================================
-- SECTION 2: REVENUE ANALYSIS
-- ============================================================

-- 2.1 Tổng doanh thu toàn thời gian
SELECT 
    ROUND(SUM(payment_value), 2)  AS total_revenue,
    COUNT(DISTINCT order_id)       AS total_orders,
    ROUND(AVG(payment_value), 2)   AS avg_order_value
FROM order_payments
WHERE payment_type != 'not_defined';

-- 2.2 Doanh thu theo tháng (Monthly Revenue Trend)
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id)                        AS total_orders,
    ROUND(SUM(p.payment_value), 2)                    AS revenue,
    ROUND(AVG(p.payment_value), 2)                    AS avg_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- 2.3 Doanh thu theo quý
SELECT 
    YEAR(o.order_purchase_timestamp)                          AS year,
    QUARTER(o.order_purchase_timestamp)                       AS quarter,
    COUNT(DISTINCT o.order_id)                                AS total_orders,
    ROUND(SUM(p.payment_value), 2)                            AS revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY year, quarter
ORDER BY year, quarter;

-- 2.4 Month-over-Month Growth (dùng window function)
WITH monthly AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        ROUND(SUM(p.payment_value), 2)                   AS revenue
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                               AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100, 2
    )                                                                 AS mom_growth_pct
FROM monthly
ORDER BY month;

-- 2.5 Phương thức thanh toán phổ biến
SELECT 
    payment_type,
    COUNT(*)                                              AS usage_count,
    ROUND(SUM(payment_value), 2)                          AS total_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)    AS pct_usage
FROM order_payments
GROUP BY payment_type
ORDER BY usage_count DESC;


-- ============================================================
-- SECTION 3: PRODUCT ANALYSIS
-- ============================================================

-- 3.1 Top 10 danh mục sản phẩm theo doanh thu
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT oi.order_id)              AS total_orders,
    SUM(oi.quantity)                         AS total_units_sold,
    ROUND(SUM(oi.price), 2)                  AS total_revenue,
    ROUND(AVG(oi.price), 2)                  AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

-- 3.2 Pareto Analysis — Top 20% sản phẩm đóng góp bao nhiêu % doanh thu
WITH product_revenue AS (
    SELECT 
        oi.product_id,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id
),
ranked AS (
    SELECT 
        product_id,
        revenue,
        NTILE(5) OVER (ORDER BY revenue DESC) AS quintile  -- 1 = top 20%
    FROM product_revenue
)
SELECT 
    quintile,
    COUNT(*)                                              AS product_count,
    ROUND(SUM(revenue), 2)                                AS total_revenue,
    ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER(), 2) AS pct_of_total
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- 3.3 Top 10 sản phẩm bán chạy nhất
SELECT 
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(oi.order_item_id)         AS units_sold,
    ROUND(SUM(oi.price), 2)         AS total_revenue,
    ROUND(AVG(r.review_score), 2)   AS avg_review_score
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id, category
ORDER BY units_sold DESC
LIMIT 10;


-- ============================================================
-- SECTION 4: CUSTOMER ANALYSIS
-- ============================================================

-- 4.1 Tỷ lệ khách hàng mua lại (Repeat Customers)
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE WHEN order_count = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
    COUNT(*)                                                       AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)            AS pct
FROM customer_orders
GROUP BY customer_type;

-- 4.2 RFM Analysis (Recency, Frequency, Monetary)
WITH rfm_base AS (
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)                                           AS last_purchase,
        COUNT(DISTINCT o.order_id)                                                AS frequency,
        ROUND(SUM(p.payment_value), 2)                                            AS monetary,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM orders),
            MAX(o.order_purchase_timestamp)
        )                                                                          AS recency_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,   -- thấp = gần đây
        NTILE(5) OVER (ORDER BY frequency DESC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)     AS m_score
    FROM rfm_base
)
SELECT 
    r_score, f_score, m_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential Loyalists'
    END AS segment,
    COUNT(*)                   AS customer_count,
    ROUND(AVG(monetary), 2)    AS avg_monetary
FROM rfm_scored
GROUP BY r_score, f_score, m_score, segment
ORDER BY customer_count DESC;

-- 4.3 Doanh thu theo bang (State) — dùng cho geo map trong Tableau
SELECT 
    c.customer_state                AS state,
    COUNT(DISTINCT o.order_id)      AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(p.payment_value), 2)  AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- ============================================================
-- SECTION 5: DELIVERY & REVIEW ANALYSIS
-- ============================================================

-- 5.1 Thời gian giao hàng trung bình
SELECT 
    ROUND(AVG(
        DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
    ), 1) AS avg_delivery_days,
    ROUND(MIN(
        DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
    ), 1) AS min_delivery_days,
    ROUND(MAX(
        DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
    ), 1) AS max_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- 5.2 Tỷ lệ giao hàng đúng hẹn vs trễ
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time' 
        ELSE 'Late' 
    END                                                AS delivery_status,
    COUNT(*)                                            AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)  AS pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- 5.3 Điểm đánh giá trung bình theo danh mục sản phẩm
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score,
    COUNT(r.review_id)               AS total_reviews
FROM order_reviews r
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
GROUP BY category
HAVING total_reviews > 100
ORDER BY avg_review_score DESC
LIMIT 15;

-- 5.4 Correlation: giao hàng trễ → review thấp hơn không?
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time' 
        ELSE 'Late' 
    END                              AS delivery_status,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score,
    COUNT(*)                         AS order_count
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;


-- ============================================================
-- SECTION 6: EXPORT VIEWS FOR TABLEAU
-- ============================================================
-- Tạo view sạch để kết nối trực tiếp với Tableau

-- View 1: Monthly Revenue (dùng cho Revenue Trend chart)
CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month_date,
    COUNT(DISTINCT o.order_id)                           AS total_orders,
    ROUND(SUM(p.payment_value), 2)                       AS revenue,
    ROUND(AVG(p.payment_value), 2)                       AS avg_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month_date;

-- View 2: Category Performance (dùng cho Product chart)
CREATE OR REPLACE VIEW v_category_performance AS
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT oi.order_id)       AS total_orders,
    ROUND(SUM(oi.price), 2)           AS revenue,
    ROUND(AVG(r.review_score), 2)     AS avg_review
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY category;

-- View 3: Customer State Map (dùng cho Geo map)
CREATE OR REPLACE VIEW v_customer_geo AS
SELECT 
    c.customer_state                      AS state,
    COUNT(DISTINCT c.customer_unique_id)  AS unique_customers,
    COUNT(DISTINCT o.order_id)            AS total_orders,
    ROUND(SUM(p.payment_value), 2)        AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state;

-- View 4: Delivery Performance (dùng cho KPI cards)
CREATE OR REPLACE VIEW v_delivery_performance AS
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
        THEN 'On Time' ELSE 'Late' 
    END                              AS delivery_status,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score,
    ROUND(AVG(DATEDIFF(
        o.order_delivered_customer_date, 
        o.order_purchase_timestamp
    )), 1)                           AS avg_delivery_days,
    COUNT(*)                         AS order_count
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;