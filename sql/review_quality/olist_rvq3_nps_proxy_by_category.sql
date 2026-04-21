-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ3 - Myntra Growth:
-- I want to understand our NPS proxy — using review scores as a satisfaction proxy. Define Promoters as score 5,
-- Passives as score 3-4, Detractors as score 1-2. Calculate NPS = % Promoters - % Detractors for each product category.
-- Show categories ranked worst to best NPS. Only include categories with at least 100 reviews.
-- Output: product_category_name, total_reviews, promoters, passives, detractors, promoter_pct, detractor_pct, nps_score."
-- =====================================================================================================================

WITH category_base AS(
    SELECT
        COALESCE(p.product_category_name,'Unknown') AS product_category_name,
        COUNT(r.review_id) AS total_reviews,
        COUNT(*) FILTER ( WHERE r.review_score = 5 ) AS promoters,
        COUNT(*) FILTER (WHERE r.review_score IN (3,4)) AS passives,
        COUNT(*) FILTER (WHERE r.review_score IN (1,2)) AS detractors,
        ROUND(COUNT(*) FILTER ( WHERE r.review_score = 5 ) * 100.0 /
              COUNT(*), 2) AS promoter_pct,
        ROUND(COUNT(*) FILTER ( WHERE  r.review_score BETWEEN 1 AND 2) * 100.0 /
              COUNT(*), 2) AS detractor_pct,
        ROUND((COUNT(*) FILTER ( WHERE r.review_score = 5 ) * 100.0 /
              COUNT(*)) - (COUNT(*) FILTER ( WHERE  r.review_score BETWEEN 1 AND 2) * 100.0 /
              COUNT(*)),2) AS nps_score
    FROM olist_orders o
    JOIN olist_order_reviews r
        ON o.order_id = r.order_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name
    HAVING COUNT(r.review_id) >= 100
)
SELECT
    product_category_name,
    promoters,
    passives,
    detractors,
    promoter_pct,
    detractor_pct,
    nps_score,
    DENSE_RANK() OVER (ORDER BY nps_score ASC) AS rank
FROM category_base
ORDER BY rank;