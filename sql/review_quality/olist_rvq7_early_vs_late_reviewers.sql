-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ7 - BOL Performance Marketing:
-- I want to understand whether customers who leave reviews quickly (within 3 days of delivery) give different scores
-- than those who delay. Split reviews into Early (0-3 days after delivery) and Late (4+ days).
-- For each group show total reviews, avg score, % 5-star, % 1-star and whether the difference is statistically meaningful.
-- Output: review_timing, total_reviews, avg_score, pct_5star, pct_1star.
-- =====================================================================================================================

SELECT
    CASE
        WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE <= 3 THEN 'Early - (0-3 days)'
        ELSE 'Late - (4+ days)'
    END AS review_timing,
COUNT(r.review_id) AS total_reviews,
ROUND(AVG(r.review_score),2) AS avg_review_score,
ROUND(COUNT(*) FILTER ( WHERE r.review_score = 5 ) * 100.0 / COUNT(*), 2) AS pct_5star,
ROUND(COUNT(*) FILTER (WHERE r.review_score = 1) * 100.0 / COUNT(*), 2) AS pct_1star
FROM olist_orders o
JOIN olist_order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
    AND r.review_creation_date IS NOT NULL
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY CASE
        WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE <= 3 THEN 'Early - (0-3 days)'
        ELSE 'Late - (4+ days)'
    END
ORDER BY avg_review_score DESC;