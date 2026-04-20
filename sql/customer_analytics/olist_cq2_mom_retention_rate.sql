-- =====================================================================================================================
-- Introducing - Customer Logistics Questions
-- ✅ CQ2 - Myntra Customer Analytics:
--  I need monthly repeat purchase rate — what percentage of customers who ordered in a given month also ordered again in
--  the following month. This is our Month-over-Month retention rate. Show month, total active customers, retained customers
--  (also ordered next month), and retention rate. Output: month, active_customers, retained_next_month, mom_retention_rate_pct.
-- =====================================================================================================================

WITH active_months AS(
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS month
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL

),
    retention AS(
        SELECT
            a1.month,
            a1.customer_unique_id,
            a2.customer_unique_id AS retained
        FROM active_months a1
        LEFT JOIN active_months a2
            ON a1.customer_unique_id = a2.customer_unique_id
            AND a2.month = a1.month + INTERVAL '1 month'
    )
SELECT
TO_CHAR(month,'YYYY-MM') AS month,
COUNT(DISTINCT customer_unique_id) AS active_customers,
COUNT(DISTINCT customer_unique_id) FILTER ( WHERE retained IS NOT NULL ) AS retained_customers,
ROUND((COUNT(DISTINCT customer_unique_id) FILTER (
    WHERE retained IS NOT NULL )) * 100.0 / NULLIF(COUNT(DISTINCT customer_unique_id),0),2) AS mom_retention_pct
FROM retention
GROUP BY month
ORDER BY month;