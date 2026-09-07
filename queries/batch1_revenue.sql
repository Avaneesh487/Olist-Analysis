-- Q1: Monthly GMV (Gross Merchandise Value) Trend
-- Business question: How is total revenue trending month over month?
-- Pattern: DATE_TRUNC to bucket timestamps into months, then aggregate

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id)                       AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS gmv,
    ROUND(AVG(oi.price + oi.freight_value)::numeric, 2) AS aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;


-- Q2: Top 10 Product Categories by Revenue
-- Business question: Which categories drive the most GMV?
-- Pattern: Multi-table join (order_items → products), GROUP BY category

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id)                      AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2)                 AS total_revenue,
    ROUND(AVG(oi.price)::numeric, 2)                 AS avg_item_price
FROM order_items oi
JOIN products p    ON oi.product_id = p.product_id
JOIN orders o      ON oi.order_id   = o.order_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;


-- Q3: Revenue by Payment Type
-- Business question: What share of GMV comes from credit card vs boleto vs voucher?
-- Pattern: JOIN payments, GROUP BY payment_type, compute share with window function

SELECT
    payment_type,
    COUNT(DISTINCT order_id)                         AS total_orders,
    ROUND(SUM(payment_value)::numeric, 2)            AS total_revenue,
    ROUND(
        100.0 * SUM(payment_value) /
        SUM(SUM(payment_value)) OVER ()
    ::numeric, 2)                                    AS revenue_share_pct
FROM payments
GROUP BY payment_type
ORDER BY total_revenue DESC;


-- Q4: Top 10 Sellers by Revenue
-- Business question: Which sellers contribute most to platform GMV?
-- Pattern: JOIN order_items → sellers, aggregate by seller

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                      AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2)                 AS total_revenue
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN orders o  ON oi.order_id  = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;