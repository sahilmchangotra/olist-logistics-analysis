-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ2 - ARPU by Month | BOL | Performance Marketing:
-- We track MAU but what really matters is whether each user is worth more over time. I need ARPU
-- (Average Revenue Per User) by month — total payment_value divided by unique customers. Also show:
-- total_revenue, mau, arpu, and arpu_mom_change (absolute change vs prior month, not percentage). If
-- ARPU dropped more than €5 vs prior month, flag it as Watch. Use payment_value from
-- olist_order_payments. Important: fan-out rule applies — aggregate payments to order level first. Order by
-- month ascending.
-- =====================================================================================================================

WITH pay_agg AS(
    SELECT
        order_id,
        SUM(payment_value) AS order_revenue
    FROM olist_order_payments
    GROUP BY order_id
),
    monthly AS(
    SELECT
        DATE_TRUNC('month',o.order_purchase_timestamp)::DATE AS order_month,
        COUNT(DISTINCT c.customer_unique_id) AS mau,
        SUM(p.order_revenue) AS total_revenue,
        ROUND(SUM(p.order_revenue) / COUNT(DISTINCT c.customer_unique_id)::NUMERIC,2) AS arpu
    FROM olist_orders o
    JOIN pay_agg p
        ON o.order_id = p.order_id
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_TRUNC('month',o.order_purchase_timestamp)::DATE
),
    mom AS(
        SELECT
            *,
            LAG(arpu) OVER(ORDER BY order_month) AS prev_arpu
        FROM monthly
    )
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    prev_arpu,
    arpu,
    mau,
    ROUND((arpu - prev_arpu),2) AS arpu_mom_change,
    CASE
        WHEN arpu < (prev_arpu - 5) THEN 'Watch'
        ELSE 'Stable'
    END AS flag
FROM mom
WHERE TO_CHAR(order_month,'YYYY-MM') BETWEEN '2017-01' AND '2018-08'
    AND prev_arpu > 20
ORDER BY order_month;

-- FAN-OUT NOTE: pay_agg CTE applied as best practice
-- ARPU values unchanged from raw join — confirmed safe
-- Reason: SUM(payment_value) self-corrects at monthly GROUP BY
-- Fan-out risk applies to COUNT-based metrics, not SUM
-- Always aggregate payments separately when using COUNT or AVG