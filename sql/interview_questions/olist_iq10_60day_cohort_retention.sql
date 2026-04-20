-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ10 - DHL — Customer Retention Interview :
-- This is from our customer retention team. For each acquisition month cohort, calculate what percentage of
-- new customers placed a second order within 60 days of their first delivered order. Show the acquisition
-- month, total new customers, customers who returned within 60 days, and the 60-day retention rate as a
-- percentage. Only include cohorts with at least 30 new customers. Order by acquisition month. This tests
-- cohort analysis using INTERVAL joins.
-- =====================================================================================================================

WITH order_base AS (
            SELECT
                    c.customer_unique_id,
                           DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS acquisition_month,
                           MIN(o.order_delivered_customer_date)::DATE AS first_order_date
                    FROM olist_orders o
                    JOIN olist_customers c
                        ON o.customer_id = c.customer_id
                    WHERE o.order_status = 'delivered'
                        AND o.order_delivered_customer_date IS NOT NULL
                    GROUP BY c.customer_unique_id
            ),
    rentention_check AS(
        SELECT
            f.customer_unique_id,
            f.acquisition_month,
            o2.order_id AS return_order_id
        FROM order_base f
        JOIN olist_customers c
            ON f.customer_unique_id = c.customer_unique_id
        LEFT JOIN olist_orders o2
            ON o2.customer_id = c.customer_id
            AND o2.order_status = 'delivered'
            AND o2.order_purchase_timestamp > f.first_order_date
            AND o2.order_purchase_timestamp <= f.first_order_date + INTERVAL '60 days'
    )
SELECT
    TO_CHAR(acquisition_month, 'YYYY-MM') AS acquisition_month,
    COUNT(DISTINCT customer_unique_id) AS new_customers,
    COUNT(DISTINCT customer_unique_id) FILTER ( WHERE return_order_id IS NOT NULL ) AS returned_within_60d,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE return_order_id IS NOT NULL ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id), 0), 2) AS retention_rate_pct
FROM rentention_check
GROUP BY TO_CHAR(acquisition_month, 'YYYY-MM')
HAVING COUNT(DISTINCT customer_unique_id) >= 30
ORDER BY acquisition_month;