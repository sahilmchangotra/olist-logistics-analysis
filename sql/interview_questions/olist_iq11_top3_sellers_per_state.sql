-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ11 - Ola City Operations Interview:
-- This is from our regional operations team. For each Brazilian state, show me the top 3 sellers ranked by total revenue.
-- We use this to identify our anchor sellers in each state for partnership negotiations. Output: seller_state, seller_rank,
-- seller_id, seller_city, total_revenue, total_orders. If two sellers are tied on revenue they should share the same rank.
-- Order by seller_state then rank.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        s.seller_city,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id, s.seller_state, s.seller_city
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (PARTITION BY seller_state ORDER BY total_revenue DESC) AS rank
        FROM seller_base
    )
SELECT
    seller_state,
    rank AS seller_rank,
    seller_id,
    seller_city,
    total_revenue,
    total_orders
FROM ranking
WHERE rank <= 3
ORDER BY seller_state, rank;