-- Q9: Monthly Cohort Retention (Month 0 vs Month 1)
-- Business question: Of customers who first ordered in month X, how many came back?
-- Pattern: CTE to find first order month per customer, then self-join to find repeat orders

WITH customer_cohorts AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)
SELECT
    co.cohort_month,
    COUNT(DISTINCT co.customer_unique_id) AS cohort_size,
    COUNT(DISTINCT CASE
        WHEN cor.order_month > co.cohort_month THEN co.customer_unique_id
    END) AS returned_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE
        WHEN cor.order_month > co.cohort_month THEN co.customer_unique_id
    END) / COUNT(DISTINCT co.customer_unique_id)::numeric, 2) AS retention_rate_pct
FROM customer_cohorts co
LEFT JOIN customer_orders cor ON co.customer_unique_id = cor.customer_unique_id
GROUP BY co.cohort_month
ORDER BY co.cohort_month;


-- Q10: Revenue Rank by Seller Using Window Functions
-- Business question: How does each seller rank within their state?
-- Pattern: RANK() window function partitioned by state — classic interview question

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        s.seller_state,
        ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
    FROM order_items oi
    JOIN sellers s ON oi.seller_id = s.seller_id
    JOIN orders o  ON oi.order_id  = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id, s.seller_state
)
SELECT
    seller_id,
    seller_state,
    total_revenue,
    RANK()        OVER (PARTITION BY seller_state ORDER BY total_revenue DESC) AS rank_in_state,
    DENSE_RANK()  OVER (PARTITION BY seller_state ORDER BY total_revenue DESC) AS dense_rank_in_state,
    ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (PARTITION BY seller_state)::numeric, 2) AS pct_of_state_revenue
FROM seller_revenue
ORDER BY seller_state, rank_in_state
LIMIT 30;


-- Q11: Running Total GMV by Month
-- Business question: What is the cumulative GMV over time?
-- Pattern: SUM() OVER with ORDER BY = running total (classic window function)

WITH monthly_gmv AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS monthly_gmv
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    monthly_gmv,
    ROUND(SUM(monthly_gmv) OVER (ORDER BY month)::numeric, 2) AS cumulative_gmv,
    ROUND(100.0 * (monthly_gmv - LAG(monthly_gmv) OVER (ORDER BY month)) /
        NULLIF(LAG(monthly_gmv) OVER (ORDER BY month), 0)::numeric, 2) AS mom_growth_pct
FROM monthly_gmv
ORDER BY month;


-- Q12: Average Order Value Percentile by Customer State
-- Business question: Which states have the highest-value customers?
-- Pattern: NTILE + PERCENTILE_CONT for distribution analysis

WITH state_aov AS (
    SELECT
        c.customer_state,
        ROUND(AVG(oi.price + oi.freight_value)::numeric, 2) AS avg_order_value,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN customers c   ON o.customer_id  = c.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    avg_order_value,
    total_orders,
    RANK() OVER (ORDER BY avg_order_value DESC) AS aov_rank,
    NTILE(4) OVER (ORDER BY avg_order_value DESC) AS quartile
FROM state_aov
ORDER BY avg_order_value DESC;