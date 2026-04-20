-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ1 - Amazon Data Analytics Interview:
-- We're hiring for a Senior Data Analyst role on our seller performance team. Here's the SQL question we use in our technical
-- screen: Find all sellers who improved their average review score for 3 consecutive months. Return the seller_id, the three
-- consecutive months, and their review score in each of those months. We want to see candidates who understand window
-- functions and trend detection."
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        oi.seller_id,
        TO_CHAR(r.review_creation_date, 'YYYY-MM') AS month,
        ROUND(AVG(r.review_score),2) AS avg_score
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_order_reviews r
        ON oi.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND review_creation_date IS NOT NULL
    GROUP BY oi.seller_id,
        TO_CHAR(r.review_creation_date, 'YYYY-MM')
),
    previous_months AS(
        SELECT
            *,
            LAG(avg_score, 1) OVER(PARTITION BY seller_id ORDER BY month) AS prev_month,
            LAG(avg_score, 2) OVER(PARTITION BY seller_id ORDER BY month) AS two_months_ago
        FROM seller_base
    )
SELECT
    seller_id,
    month,
    avg_score,
    prev_month,
    two_months_ago
FROM previous_months
WHERE avg_score > prev_month
AND prev_month > two_months_ago
AND two_months_ago IS NOT NULL;