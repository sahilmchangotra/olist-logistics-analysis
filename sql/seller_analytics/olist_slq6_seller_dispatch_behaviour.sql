WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        o.order_id,
        EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400 AS dispatch_time
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
), aggregating AS(
    SELECT
        seller_id,
        seller_state,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(AVG(dispatch_time),2) AS avg_dispatch_days,
        ROUND(SUM(dispatch_time) FILTER ( WHERE dispatch_time <= 2 ) * 100.0 /
              NULLIF(SUM(dispatch_time),0), 2) AS pct_within_2days,
        ROUND(SUM(dispatch_time) FILTER ( WHERE dispatch_time <= 5 ) * 100.0 /
              NULLIF(SUM(dispatch_time),0), 2) AS pct_within_5days
    FROM seller_base
    GROUP BY seller_id, seller_state
    HAVING COUNT(DISTINCT order_id) >= 50
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    avg_dispatch_days,
    pct_within_2days,
    pct_within_5days,
    CASE
        WHEN avg_dispatch_days <= 2 THEN 'Excellent'
        WHEN avg_dispatch_days <= 4 THEN 'Good'
        WHEN avg_dispatch_days <= 7 THEN 'Average'
    ELSE 'Slow'
    END AS dispatch_grade
FROM aggregating
ORDER BY avg_dispatch_days ASC;