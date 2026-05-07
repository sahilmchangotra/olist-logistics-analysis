-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ4 - Myntra Category Analytics Lead:
-- I need a monthly process efficiency score for the platform. Define efficiency as: (on_time_orders /
-- total_orders) * (5 / avg_review_score). A perfect score would be 1.0 — 100% on time with 5-star reviews. Show
-- the score for each month, MoM change, and flag months as Improving or Worsening. Output: month,
-- total_orders, on_time_orders, on_time_rate, avg_review_score, efficiency_score, prev_score, mom_change,
-- trend_flag.
-- =====================================================================================================================

WITH efficiency_base AS(
    SELECT
        DATE_TRUNC('month',o.order_purchase_timestamp)::DATE AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date ) AS on_time_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date ) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0),2) AS on_time_rate,
        ROUND(AVG(r.review_score),2) AS avg_review_score,
        (COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date ) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0)) * (5 / NULLIF(AVG(r.review_score),0)) AS efficiency_score
    FROM olist_orders o
    LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score FROM olist_order_reviews GROUP BY order_id) r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY DATE_TRUNC('month',o.order_purchase_timestamp)
    HAVING COUNT(DISTINCT o.order_id) >= 10
),
    previous_month_score AS(
        SELECT
            *,
            LAG(efficiency_score) OVER (ORDER BY month) AS prev_score,
            (efficiency_score - LAG(efficiency_score) OVER (ORDER BY month)) AS mom_change
        FROM efficiency_base
    )
SELECT
    TO_CHAR(month,'YYYY-MM') AS month,
    total_orders,
    on_time_orders,
    on_time_rate,
    avg_review_score,
    ROUND(efficiency_score,2) AS efficiency_score,
    ROUND(prev_score,2) AS prev_score,
    ROUND(mom_change,2) AS mom_change,
    CASE
        WHEN efficiency_score > prev_score THEN 'Improving'
        WHEN efficiency_score < prev_score THEN 'Worsening'
        ELSE 'Stable'
    END AS trend_flag
FROM previous_month_score
ORDER BY month;