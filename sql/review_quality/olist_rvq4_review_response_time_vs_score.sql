-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ4 - Myntra Head of Logistics:
-- I want to see the relationship between review response time and review score. Calculate for each order how many days
-- passed between order delivery and review creation. Bucket into: Same Day (0 days), Quick (1-3 days), Normal (4-7 days),
-- Slow (8-30 days), Very Slow (30+ days). Show avg review score and total reviews per bucket. Output: response_bucket,
-- total_reviews, avg_review_score, pct_5star, pct_1star.
-- =====================================================================================================================


    SELECT
        CASE
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE = 0 THEN '1 - Same Day'
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE BETWEEN 1 AND 3 THEN '2 - Quick'
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE BETWEEN 4 AND 7 THEN '3 - Normal'
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE BETWEEN 8 AND 30 THEN '4 - Slow'
            ELSE '5 - Very Slow'
        END AS response_bucket,
        COUNT(r.review_id) AS total_reviews,
        ROUND(AVG(r.review_score),2) AS avg_review_score,
        ROUND(COUNT(*) FILTER ( WHERE r.review_score = 5 ) * 100.0 / COUNT(*), 2) AS pct_5star,
        ROUND(COUNT(*) FILTER (WHERE r.review_score = 1) * 100.0 / COUNT(*), 2) AS pct_1star
    FROM olist_orders o
    JOIN olist_order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND r.review_creation_date IS NOT NULL
    GROUP BY CASE
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE = 0 THEN '1 - Same Day'
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE BETWEEN 1 AND 3 THEN '2 - Quick'
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE BETWEEN 4 AND 7 THEN '3 - Normal'
            WHEN r.review_creation_date::DATE - o.order_delivered_customer_date::DATE BETWEEN 8 AND 30 THEN '4 - Slow'
            ELSE '5 - Very Slow'
        END
    ORDER BY response_bucket;