-- Q5: Order Funnel Analysis
-- Business question: Where do orders drop off across statuses?
-- Pattern: COUNT with FILTER, compute drop-off % using window functions

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()::numeric, 2) AS pct_of_total,
    ROUND(100.0 * COUNT(*) / FIRST_VALUE(COUNT(*)) OVER (ORDER BY COUNT(*) DESC)::numeric, 2) AS pct_of_peak
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- Q6: Average Delivery Delay by State
-- Business question: Which states have the worst delivery performance?
-- Pattern: EXTRACT to compute day differences, filter only delivered orders

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400
    )::numeric, 2) AS avg_delay_days,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400
    )::numeric, 2) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delay_days DESC;


-- Q7: Review Score Distribution vs Delivery Delay
-- Business question: Does late delivery correlate with lower review scores?
-- Pattern: JOIN 3 tables, bucket delay into categories, aggregate scores

SELECT
    CASE
        WHEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400 < -5 THEN 'Very Early (>5d)'
        WHEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400 < 0  THEN 'Early'
        WHEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400 = 0  THEN 'On Time'
        WHEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400 <= 5 THEN 'Late (1-5d)'
        ELSE 'Very Late (>5d)'
    END AS delivery_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 1
ORDER BY avg_review_score DESC;


-- Q8: Repeat Customer Rate
-- Business question: What % of customers placed more than one order?
-- Pattern: CTE to count orders per customer, then classify and aggregate

WITH customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time'
        WHEN total_orders = 2 THEN 'Returned once'
        ELSE 'Loyal (3+ orders)'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()::numeric, 2) AS pct_of_customers
FROM customer_order_counts
GROUP BY 1
ORDER BY customer_count DESC;