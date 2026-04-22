-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ1 - Myntra Seller Success:
-- I need a complete seller performance ranking. For each seller show total orders, total revenue, average order value,
-- average review score, late rate and rank them by total revenue. I want to identify our top 20 revenue-generating sellers
-- and understand if high revenue correlates with high quality. Output: rank, seller_id, seller_city, seller_state,
-- total_orders, total_revenue, avg_order_value, avg_review_score, late_rate_pct.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        ROUND(AVG(oi.price + oi.freight_value),2) AS avg_order_value,
        ROUND(AVG(r.review_score),2) AS avg_review_score,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100.0 /
              COUNT(DISTINCT o.order_id), 2) AS late_rate
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_order_reviews r
        ON o.order_id = r.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY s.seller_id, s.seller_city, s.seller_state
),
    ranking AS (
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS rank
        FROM seller_base
    )
SELECT
    rank,
    seller_id,
    seller_city,
    seller_state,
    total_orders,
    total_revenue,
    avg_order_value,
    avg_review_score,
    late_rate
FROM ranking
WHERE rank <= 20
ORDER BY rank;