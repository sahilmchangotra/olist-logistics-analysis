-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ5 - BOL Category Marketing:
-- I need to identify sellers with consistently poor review scores — sellers who have received more than 30% of their
-- reviews as 1-star AND have at least 50 total reviews. These are sellers we need to flag for performance improvement
-- plans. Show seller_id, seller_city, seller_state, total_reviews, one_star_reviews, one_star_rate_pct, avg_review_score,
-- ranked worst first. Output: rank, seller_id, seller_city, seller_state, total_reviews, one_star_reviews,
-- one_star_rate_pct, avg_review_score.
-- =====================================================================================================================
WITH seller_base AS(
    SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(r.review_id) AS total_reviews,
    COUNT(*) FILTER ( WHERE r.review_score = 1 ) AS one_star_reviews,
    ROUND(COUNT(*) FILTER ( WHERE r.review_score = 1 ) * 100.0 / COUNT(*),2) AS one_star_rate_pct,
    ROUND(AVG(r.review_score),2) AS avg_review_score
FROM olist_orders o
JOIN olist_order_reviews r
    ON o.order_id = r.order_id
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING COUNT(r.review_id) >= 50
AND ROUND(COUNT(*) FILTER ( WHERE r.review_score = 1 ) * 100.0 / COUNT(*),2) > 30
)
SELECT
    seller_id,
    seller_city,
    seller_state,
    total_reviews,
    one_star_reviews,
    one_star_rate_pct,
    avg_review_score,
    DENSE_RANK() OVER (ORDER BY one_star_rate_pct DESC) AS rank
FROM seller_base
ORDER BY rank;