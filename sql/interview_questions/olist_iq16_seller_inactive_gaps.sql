-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ16 - Google Data Analytics Interview:
-- This is a gaps-and-islands question we use in our senior analyst screen. In our seller operations team we want to
-- identify sellers who had no orders (inactive) for 3 or more consecutive days — we call these 'ghost sellers'.
-- Using the OLIST dataset, find all sellers who had at least one active day followed by a gap of 3 or more consecutive
-- days with zero orders, followed by another active day. Return the seller_id, gap_start_date, gap_end_date, and
-- gap_length_days. Only include sellers with at least 50 total orders so we focus on established sellers who suddenly
-- went quiet. Order by gap_length_days DESC.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        DATE_TRUNC('day',o.order_purchase_timestamp)::DATE AS order_date,
        COUNT(DISTINCT o.order_id) AS daily_orders
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY s.seller_id, DATE_TRUNC('day',o.order_purchase_timestamp)::DATE
),
    next_date AS(
        SELECT
            seller_id,
            order_date,
            SUM(daily_orders) OVER (PARTITION BY seller_id) AS seller_total_orders,
            LEAD(order_date, 1) OVER (PARTITION BY seller_id ORDER BY order_date) AS next_active_date
        FROM seller_base
    )
        SELECT
            seller_id,
            (order_date + 1) AS gap_start,
            (next_active_date - 1) AS gap_end,
            (next_active_date - order_date - 1) AS gap_length
        FROM next_date
        WHERE next_active_date - order_date > 3
        AND seller_total_orders >= 50
        ORDER BY gap_length DESC;