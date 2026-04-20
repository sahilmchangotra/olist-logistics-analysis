-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ12 - Grab Data Analyst Interview :
-- This is from our payments analytics team. We want to understand how payment method preferences shift across quarters.
-- Build a pivot table showing total orders broken down by payment type as rows and quarter as columns — Q1, Q2, Q3, Q4.
-- Also add a total column. This tests whether candidates know how to pivot in SQL without a PIVOT function.
-- Output: payment_type, q1_orders, q2_orders, q3_orders, q4_orders, total_orders.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        o.order_id,
        p.payment_type,
        EXTRACT(QUARTER FROM o.order_purchase_timestamp) AS quarter
    FROM olist_orders o
    JOIN olist_order_payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
),
    pivot_summary AS(
        SELECT
            payment_type,
            COUNT(DISTINCT CASE WHEN quarter = 1 THEN order_id END) AS Q1,
            COUNT(DISTINCT CASE WHEN quarter = 2 THEN order_id END) AS Q2,
            COUNT(DISTINCT CASE WHEN quarter = 3 THEN order_id END) AS Q3,
            COUNT(DISTINCT CASE WHEN quarter = 4 THEN order_id END) AS Q4,
            COUNT(DISTINCT order_id) AS total_orders
        FROM order_base
        GROUP BY payment_type
    )
       SELECT
           *,
           ROUND(total_orders * 100.0 / SUM(total_orders) OVER(), 2) AS share_pct
FROM pivot_summary
ORDER BY share_pct DESC;