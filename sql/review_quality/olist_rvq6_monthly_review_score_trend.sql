-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ6 - Myntra Customer Analytics:
-- I want to understand review score trends over time — is customer satisfaction improving or declining month by month?
-- Show monthly avg review score, total reviews, % 5-star, % 1-star, and a 3-month rolling average score.
-- Flag months where rolling avg drops below 4.0. Output: month, total_reviews, avg_score, pct_5star, pct_1star,
-- rolling_3m_avg, flag.
-- =====================================================================================================================

WITH review_base AS(
    SELECT
    DATE_TRUNC('month', r.review_creation_date) AS month,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.review_score),2) AS avg_review_score,
    ROUND(COUNT(*) FILTER ( WHERE r.review_score = 5 ) * 100.0 / COUNT(*), 2) AS pct_5star,
    ROUND(COUNT(*) FILTER ( WHERE r.review_score = 1 ) * 100.0 / COUNT(*),2) AS pct_1star
FROM olist_orders o
JOIN olist_order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
    AND r.review_creation_date IS NOT NULL
GROUP BY DATE_TRUNC('month', r.review_creation_date)
),
    rolling AS(
        SELECT
            *,
            ROUND(AVG(avg_review_score) OVER (ORDER BY month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ),2) AS rolling_3m_avg
        FROM review_base
    )
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    total_reviews,
    avg_review_score,
    pct_5star,
    pct_1star,
    rolling_3m_avg,
    CASE
        WHEN rolling_3m_avg < 4.0 THEN 'Declining'
        ELSE 'On Track'
    END AS flag
FROM rolling
ORDER BY month;