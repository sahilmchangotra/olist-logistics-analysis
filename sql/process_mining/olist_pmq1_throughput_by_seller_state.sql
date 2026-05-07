-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ1 - Myntra Head of Logistics:
-- I need to understand how long orders actually take from purchase to delivery. Can you show me the
-- average, median (using PERCENTILE_CONT), minimum and maximum throughput time in days for each seller
-- state? Also bucket each state into Fast (<10 days avg), Normal (10-15 days), Slow (15-20 days) or Critical (>20
-- days). Only include states with at least 50 delivered orders. Output: seller_state, total_orders, avg_days,
-- median_days, min_days, max_days, speed_bucket.
-- =====================================================================================================================

WITH seller_base AS (
    SELECT
        s.seller_state,
        o.order_id,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC AS delivery_days
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
    )
SELECT
    seller_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(delivery_days),2) AS avg_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP ( ORDER BY delivery_days)::NUMERIC,2) AS median_days,
    ROUND(MIN(delivery_days),2) AS min_days,
    ROUND(MAX(delivery_days),2) AS max_days,
    CASE
        WHEN AVG(delivery_days) < 10 THEN 'Fast Delivery'
        WHEN AVG(delivery_days) BETWEEN 10 AND 15 THEN 'Normal Delivery'
        WHEN AVG(delivery_days) BETWEEN 15 AND 20 THEN 'Slow Delivery'
        WHEN AVG(delivery_days) > 20 THEN 'Critical'
    END AS speed_bucket
FROM seller_base
GROUP BY seller_state
HAVING COUNT(DISTINCT order_id) >= 50
ORDER BY avg_days DESC;