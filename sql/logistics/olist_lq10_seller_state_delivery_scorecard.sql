-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ10 - Myntra Seller Success Manager
--   I'm preparing the quarterly seller state performance review for our logistics board. I need a complete delivery scorecard
--   for every seller state — showing total orders, average estimated delivery days (what we promised customers),
--   average actual delivery days (what we delivered), the delivery gap (actual minus estimated), late rate percentage,
--   and a performance grade based on the gap. Grade them as: Excellent (gap ≤ -2, arriving early), Good (-2 < gap ≤ 0),
--   Needs Improvement (0 < gap ≤ 2), or Poor (gap > 2). Rank states worst to best by delivery gap. Output: seller_state,
--   total_orders, avg_estimated_days, avg_actual_days, avg_delivery_gap, late_rate_pct, performance_grade, rank.
-- =====================================================================================================================


WITH order_base AS(

    SELECT
        s.seller_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date -
            o.order_purchase_timestamp))/86400)::NUMERIC, 2) AS avg_estimated_days,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date -
            o.order_purchase_timestamp))/86400)::NUMERIC, 2) AS avg_actual_days,
        ROUND(COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                o.order_estimated_delivery_date) * 100.0 / COUNT(DISTINCT o.order_id), 2) AS late_rate_pct,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))/86400::NUMERIC), 2) AS avg_delivery_gap
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY s.seller_state
    HAVING COUNT(DISTINCT o.order_id) >= 30
),
    ranking AS(
        SELECT
            *,
            CASE
                WHEN avg_delivery_gap <= -10 AND late_rate_pct < 5 THEN '⭐ Elite'
                WHEN avg_delivery_gap <= -10 AND late_rate_pct < 10 THEN '✅ Excellent'
                WHEN avg_delivery_gap <= -10 AND late_rate_pct >= 10 THEN '⚠️ Excellent but Unreliable'
                WHEN avg_delivery_gap BETWEEN -10 AND 0 THEN '🟡 Good'
                ELSE '🔴 Poor'
            END AS performance_grade,
            DENSE_RANK() OVER (ORDER BY avg_delivery_gap DESC) AS rank
        FROM order_base
    )
SELECT
    seller_state,
    total_orders,
    avg_estimated_days,
    avg_actual_days,
    avg_delivery_gap,
    late_rate_pct,
    performance_grade,
    rank
FROM ranking
ORDER BY rank;