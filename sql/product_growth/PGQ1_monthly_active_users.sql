-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ1 - Monthly Active Users (MAU) | Myntra - Growth & Retention:
-- MAU is our north-star growth metric. I need to see monthly unique customers who placed a
-- delivered order — this is our active user base. For each month, show: order_month, mau (unique
-- customers), total_orders, avg_orders_per_user, and mom_growth_pct (MoM MAU change). Flag months
-- where MAU declined vs prior month as Declining, otherwise Growing. Date range: 2017-01 to 2018-08
-- only — exclude partial months. Order by order_month ascending.
-- =====================================================================================================================

WITH user_base AS(
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month,
        COUNT(DISTINCT c.customer_unique_id) AS mau,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),
    mom AS(
        SELECT
            *,
            LAG(mau) OVER (ORDER BY order_month) AS prev_mau
        FROM user_base
    )
SELECT
    TO_CHAR(order_month, 'YYYY-MM') AS order_month,
    mau,
    prev_mau,
    total_orders,
    ROUND(total_orders::NUMERIC / mau,2) AS avg_orders_per_user,
    ROUND((mau - prev_mau) * 100.0 / NULLIF(prev_mau,0),2) AS mom_growth_pct,
    CASE
        WHEN mau < prev_mau THEN 'Declining'
        ELSE 'Growing'
    END AS flag
FROM mom
WHERE TO_CHAR(order_month, 'YYYY-MM') BETWEEN '2017-01' AND '2018-08'
AND prev_mau > 10
ORDER BY order_month;