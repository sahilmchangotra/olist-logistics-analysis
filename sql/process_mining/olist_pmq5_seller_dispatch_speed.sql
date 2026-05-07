-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ5 - Myntra Seller Success Manager:
-- Dispatch speed (time from order approval to carrier handover) is one of our key seller KPIs. For each
-- seller I want: average dispatch days, % of orders dispatched within 1 day, within 3 days, and within 5 days.
-- Classify sellers as Elite (<1 day avg), Good (1-2 days), Average (2-4 days) or Slow (>4 days). Only include
-- sellers with at least 30 orders. Output: seller_id, seller_state, total_orders, avg_dispatch_days, pct_within_1day,
-- pct_within_3days, pct_within_5days, dispatch_tier.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        o.order_id,
        EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400 AS dispatch_days
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_approved_at IS NOT NULL
),
    aggreagte AS(
        SELECT
            seller_id,
            seller_state,
            ROUND(AVG(dispatch_days),2) AS avg_dispatch_days,
            COUNT(DISTINCT order_id) AS total_orders,
            ROUND(COUNT(*) FILTER ( WHERE dispatch_days <= 1 ) * 100 / COUNT(*),2) AS pct_within_1day,
            ROUND(COUNT(*) FILTER ( WHERE dispatch_days <= 3 ) * 100 / COUNT(*),2) AS pct_within_3days,
            ROUND(COUNT(*) FILTER ( WHERE dispatch_days <= 5 ) * 100 / COUNT(*),2) AS pct_within_5days
        FROM seller_base
        GROUP BY seller_id, seller_state
        HAVING COUNT(DISTINCT order_id) >= 30
    )
SELECT
    seller_id,
    seller_state,
    avg_dispatch_days,
    total_orders,
    pct_within_1day,
    pct_within_3days,
    pct_within_5days,
    CASE
        WHEN avg_dispatch_days < 1 THEN 'Elite'
        WHEN avg_dispatch_days BETWEEN 1 AND 2 THEN 'Good'
        WHEN avg_dispatch_days BETWEEN 2 AND 4 THEN 'Average'
        WHEN avg_dispatch_days > 4 THEN 'Slow'
    END AS dispatch_tier
FROM aggreagte
ORDER BY avg_dispatch_days DESC;