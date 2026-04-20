-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ14 - Shopee Analytics Interview :
-- This is from our customer experience team. We want to understand the relationship between delivery speed and review scores.
-- Bucket orders into delivery speed tiers — Fast (≤7 days), Normal (8–14 days), Slow (15–21 days), Very Slow (>21 days) —
-- and for each bucket show total orders, average review score, percentage of 5-star reviews, percentage of 1-star reviews
-- and a satisfaction flag. We want to see if late deliveries actually cause lower review scores.
-- Output: delivery_bucket, total_orders, avg_review_score, pct_5star, pct_1star, satisfaction_flag."
-- =====================================================================================================================

WITH delivery_base AS(
    SELECT
        o.order_id,
        r.review_score,
        ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date -
                            o.order_purchase_timestamp))/86400::NUMERIC, 2) AS delivery_days
    FROM olist_orders o
    JOIN olist_order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
),
    bucketing AS(
        SELECT
            *,
            CASE
                WHEN delivery_days <= 7 THEN 'Fast'
                WHEN delivery_days BETWEEN 8 AND 14 THEN 'Normal'
                WHEN delivery_days BETWEEN 15 AND 21 THEN 'Slow'
                ELSE 'Very Slow'
            END AS delivery_bucket
        FROM delivery_base
    ),
    aggregating AS(
        SELECT
            delivery_bucket,
            COUNT(DISTINCT order_id) AS total_orders,
            ROUND(AVG(review_score), 2) AS avg_review_score,
            ROUND(SUM(CASE WHEN review_score = 5 THEN 1 END) * 100.0 /
                COUNT(review_score), 2) AS pct_5star,
            ROUND(SUM(CASE WHEN review_score = 1 THEN 1 END) * 100.0 /
                COUNT(review_score), 2) AS pct_1star,
            CASE
                WHEN AVG(review_score) >= 4 THEN 'Satisfied'
                WHEN AVG(review_score) >= 3 THEN 'Neutral'
                ELSE 'Dissatisfied'
            END AS satisfaction_flag
        FROM bucketing
        GROUP BY delivery_bucket
    )
SELECT
    *
FROM aggregating delivery_bucket;