-- 03. Seller Performance Scorecard
-- Business Question:
-- Which sellers are causing the most delivery delays?
-- Show seller-level KPIs: total orders, average delivery days,
-- average review score, and SLA breach rate.
-- Only include sellers with at least 50 delivered orders.

WITH seller_orders AS (
    SELECT
        s.seller_id,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        DATE_PART('day', o.order_delivered_customer_date - o.order_purchase_timestamp)::NUMERIC AS delivery_days,
        r.review_score
    FROM kaggle.olist_orders o
    JOIN kaggle.olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN kaggle.olist_sellers s
        ON oi.seller_id = s.seller_id
    JOIN kaggle.olist_order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
),
seller_stats AS (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
        ROUND(AVG(review_score::NUMERIC), 2) AS avg_review_score,
        ROUND(
            SUM(
                CASE
                    WHEN order_delivered_customer_date > order_estimated_delivery_date + INTERVAL '3 days'
                    THEN 1 ELSE 0
                END
            ) * 100.0 / COUNT(*),
            2
        ) AS breach_rate_pct
    FROM seller_orders
    GROUP BY seller_id
    HAVING COUNT(DISTINCT order_id) >= 50
)
SELECT
    seller_id,
    total_orders,
    avg_delivery_days,
    avg_review_score,
    breach_rate_pct,
    DENSE_RANK() OVER (ORDER BY breach_rate_pct DESC) AS rank
FROM seller_stats
ORDER BY rank;