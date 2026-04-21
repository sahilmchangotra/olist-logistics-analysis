-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ8 - JET SODA Network Planning:
-- I need a seller review scorecard combining delivery performance and review quality. For each seller show: total orders,
-- avg delivery days, late rate, avg review score, total reviews, and a combined performance grade.
-- Grade as Elite (avg score ≥ 4.5 AND late rate < 5%), Good (avg score ≥ 4.0 AND late rate < 10%),
-- Needs Improvement (avg score ≥ 3.5 OR late rate < 15%), or Poor (everything else). Only include sellers with at least
-- 50 orders and 20 reviews. Output: seller_id, total_orders, avg_delivery_days, late_rate_pct, avg_review_score,
-- total_reviews, performance_grade.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400)) AS avg_delivery_days,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100.0 /
              COUNT(DISTINCT o.order_id), 2) AS late_rate_pct,
        ROUND(AVG(r.review_score),2) AS avg_review_score,
        COUNT(r.review_id) AS total_reviews
    FROM olist_orders o
    JOIN olist_order_reviews r
        ON o.order_id = r.order_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY s.seller_id
    HAVING COUNT(DISTINCT o.order_id) >= 50
        AND COUNT(r.review_id) >= 20
)
SELECT
    seller_id,
    total_orders,
    total_reviews,
    avg_review_score,
    avg_delivery_days,
    late_rate_pct,
    CASE
        WHEN avg_review_score >= 4.5 AND late_rate_pct < 5 THEN 'Elite'
        WHEN avg_review_score >= 4.0 AND late_rate_pct < 10 THEN 'Good'
        WHEN avg_review_score >= 3.5 AND late_rate_pct < 15 THEN 'Needs Improvement'
        ELSE 'Poor'
    END AS performance_grade
FROM seller_base
ORDER BY avg_review_score DESC;