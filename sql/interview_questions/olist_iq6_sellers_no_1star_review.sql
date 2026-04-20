-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ6 - Meesho — Seller Analytics Interview:
-- This is from our seller trust team's technical screen. We want to identify our most reliable sellers —
-- specifically sellers who have never received a single 1-star review. Return the seller_id, seller_city,
-- seller_state, total orders, average review score, and flag them as 'Perfect Record'. Only include sellers with
-- at least 10 delivered orders so we exclude low-volume flukes. Order by total orders descending so we can
-- see our highest-volume reliable sellers first.
-- =====================================================================================================================


    SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.review_score),2) AS avg_review_score,
    'Perfect Record' AS flag
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews r
    ON o.order_id = r.order_id
JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 10
    AND MIN(r.review_score) > 1
ORDER BY total_orders DESC;