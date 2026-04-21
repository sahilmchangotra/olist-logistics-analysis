-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ2 - Myntra Seller Success:
-- I want to track how each seller's average review score has changed over time. For each seller show their review score
-- in Q1 2017, Q2 2017, Q3 2017 and Q4 2017 as a pivot — and flag sellers whose score dropped more than 0.5 points from
-- Q1 to Q4. Only include sellers with at least 10 reviews per quarter. Output: seller_id, q1_score, q2_score, q3_score,
-- q4_score, q1_to_q4_change, trend_flag.
-- =====================================================================================================================

WITH seller_base AS(
                    SELECT s.seller_id,
                           EXTRACT(QUARTER FROM r.review_creation_date) AS quarter,
                           COUNT(r.review_id)                           AS total_reviews,
                           ROUND(AVG(r.review_score), 2)                AS avg_review_score
                    FROM olist_orders o
                             JOIN olist_order_items oi
                                  ON o.order_id = oi.order_id
                             JOIN olist_order_reviews r
                                  ON o.order_id = r.order_id
                             JOIN olist_sellers s
                                  ON oi.seller_id = s.seller_id
                    WHERE o.order_status = 'delivered'
                      AND EXTRACT(YEAR FROM r.review_creation_date) = '2017'
                    GROUP BY s.seller_id, EXTRACT(QUARTER FROM r.review_creation_date)
                    HAVING COUNT(DISTINCT r.review_id) >= 10
),
    pivoting AS(
        SELECT
            seller_id,
            ROUND(AVG(avg_review_score) FILTER (WHERE quarter = 1)::NUMERIC, 2) AS q1_score,
            ROUND(AVG(avg_review_score) FILTER (WHERE quarter = 2)::NUMERIC, 2) AS q2_score,
            ROUND(AVG(avg_review_score) FILTER (WHERE quarter = 3)::NUMERIC, 2) AS q3_score,
            ROUND(AVG(avg_review_score) FILTER (WHERE quarter = 4)::NUMERIC, 2) AS q4_score
        FROM seller_base
        GROUP BY seller_id
    )
SELECT
    seller_id,
    q1_score,
    q2_score,
    q3_score,
    q4_score,
    ROUND((q4_score - q1_score),2) AS q1_to_q4_change,
    CASE
        WHEN q4_score - q1_score < - 0.5 THEN 'Declining'
        WHEN q4_score - q1_score > 0.5 THEN 'Improving'
        ELSE 'Stable'
    END AS trend_flag
FROM pivoting
WHERE q1_score IS NOT NULL
AND q4_score IS NOT NULL;