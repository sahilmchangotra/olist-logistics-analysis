-- =====================================================================================================================
-- Introducing - Customer Logistics Questions
-- ✅ CQ4 - Myntra Seller Success:
--   I want to calculate Customer Lifetime Value by acquisition cohort. For each cohort month show the average cumulative
--   revenue per customer at 3 months, 6 months and 12 months after acquisition. This tells us which acquisition cohorts
--   have the highest long-term value. Output: cohort_month, cohort_size, avg_clv_3m, avg_clv_6m, avg_clv_12m.
-- =====================================================================================================================

WITH cohort_base AS(
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month',MIN(o.order_purchase_timestamp)) AS cohort_month,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
),
    customer_revenue AS(
        SELECT
            cb.customer_unique_id,
            cb.cohort_month,
            SUM(oi.price + oi.freight_value) FILTER (
                WHERE o.order_purchase_timestamp <= cb.first_order_date + INTERVAL '3 months') AS revenue_3m,
            SUM(oi.price + oi.freight_value) FILTER (
                WHERE o.order_purchase_timestamp <= cb.first_order_date + INTERVAL '6 months') AS revenue_6m,
            SUM(oi.price + oi.freight_value) FILTER (
                WHERE o.order_purchase_timestamp <= cb.first_order_date + INTERVAL '12 months') AS revenue_12m
        FROM cohort_base cb
        JOIN olist_customers c
            ON c.customer_unique_id = cb.customer_unique_id
        JOIN olist_orders o
            ON o.customer_id = c.customer_id
            AND o.order_status = 'delivered'
        JOIN olist_order_items oi
            ON o.order_id = oi.order_id
        GROUP BY cb.customer_unique_id, cb.cohort_month
    )
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_size,
    ROUND(AVG(revenue_3m),2) AS avg_clv_3m,
    ROUND(AVG(revenue_6m),2) AS avg_clv_6m,
    ROUND(AVG(revenue_12m),2) AS avg_clv_12m
FROM customer_revenue
GROUP BY TO_CHAR(cohort_month, 'YYYY-MM')
HAVING COUNT(DISTINCT customer_unique_id) >= 100
ORDER BY cohort_month;