-- =====================================================================================================================
-- Introducing - Review Quality
-- ✅ RVQ1 - Myntra Customer Analytics:
-- I need a full review score distribution report. For each review score (1-5) show total reviews, percentage of total,
-- cumulative percentage, and average delivery days for orders that received that score. I want to understand if lower
-- scores correlate with longer delivery times. Output: review_score, total_reviews, pct_of_total, cumulative_pct, avg_delivery_days.
-- =====================================================================================================================

WITH review_base AS (SELECT r.review_score,
                            COUNT(r.review_score)                                           AS total_reviews,
                            ROUND(COUNT(r.review_score) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
                            ROUND(SUM(COUNT(*))
                                  OVER (ORDER BY r.review_score ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) *
                                  100.0 /
                                  SUM(COUNT(*)) OVER (), 2)                                 AS cummulative_pct,
                            ROUND(AVG(EXTRACT(EPOCH FROM
                                              (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400),
                                  2)                                                        AS avg_delivery_days
                     FROM olist_orders o
                              JOIN olist_order_reviews r
                                   ON o.order_id = r.order_id
                     WHERE o.order_status = 'delivered'
                       AND o.order_purchase_timestamp IS NOT NULL
                     GROUP BY r.review_score)
SELECT
    review_score,
    total_reviews,
    pct_of_total,
    cummulative_pct,
    avg_delivery_days
FROM review_base
ORDER BY avg_delivery_days DESC;