-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ4 - Myntra Category Analytics:
--  I want to identify sellers who are consistently improving — showing month-over-month revenue growth for 3 or
--  more consecutive months in 2018. This helps us identify rising stars for our seller spotlight programme.
--  Output: seller_id, seller_state, streak_start_month, streak_end_month, streak_length, total_revenue_in_streak.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
    GROUP BY s.seller_id, s.seller_state, DATE_TRUNC('month',o.order_purchase_timestamp)
),

    growth AS(
        SELECT
            seller_id,
            seller_state,
            month,
            monthly_revenue,
            CASE
                WHEN monthly_revenue > LAG(monthly_revenue) OVER (PARTITION BY seller_id ORDER BY month)
                THEN 1 ELSE 0 END AS is_growth
        FROM seller_base
    ),
    streaks AS(
        SELECT
            seller_id,
            seller_state,
            month,
            monthly_revenue,
            is_growth,
            ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY month) -
            ROW_NUMBER() OVER (PARTITION BY seller_id, is_growth ORDER BY month) AS streak_group
        FROM growth
    ),
    ranked AS(
        SELECT
            seller_id,
            seller_state,
            COUNT(*) AS streak_length,
            MIN(month) AS streak_start_month,
            MAX(month) AS streak_end_month,
            SUM(monthly_revenue) AS total_revenue,
            ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY COUNT(*) DESC) AS streak_rank
        FROM streaks
        WHERE is_growth = 1
        GROUP BY seller_id, seller_state, streak_group
        HAVING COUNT(*) >= 3
    )
SELECT
    seller_id,
    seller_state,
    streak_length,
    TO_CHAR(streak_start_month, 'YYYY-MM') AS streak_start_month,
    TO_CHAR(streak_end_month, 'YYYY-MM') AS streak_end_month,
    total_revenue
FROM ranked
WHERE streak_rank = 1
ORDER BY streak_length DESC;