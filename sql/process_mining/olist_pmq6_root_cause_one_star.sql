-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ6 - Myntra Customer Analytics:
--  I want to understand what process factors drive 1-star reviews. For orders with review score = 1, show
-- me: average total throughput days, average dispatch days (Stage 2), average transit days (Stage 3), late delivery
-- rate, and compare each metric to the platform average for all reviews. Also show the top 5 seller states with the
-- highest 1-star rate (min 100 orders). Output comparison: metric, one_star_avg, platform_avg, difference. Output
-- top 5 states: seller_state, total_orders, one_star_count, one_star_rate.
-- =====================================================================================================================

WITH review_base AS(
    SELECT
        s.seller_state,
        o.order_id,
        r.review_score,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400 AS throughput_days,
        EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400 AS dispatch_days,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date))/86400 AS transit_days,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS late_delivery
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    JOIN olist_order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
),
    plaftform_average AS(
        SELECT
            ROUND(AVG(throughput_days),2) AS p_throughput,
            ROUND(AVG(dispatch_days),2) AS p_dispatch,
            ROUND(AVG(transit_days),2) AS p_transit,
            ROUND(AVG(late_delivery),2) AS p_late_rate
        FROM review_base
    ),
    one_star_avg AS(
        SELECT
            ROUND(AVG(throughput_days),2) AS o_throughput,
            ROUND(AVG(dispatch_days),2) AS o_dispatch,
            ROUND(AVG(transit_days),2) AS o_transit,
            ROUND(AVG(late_delivery),2) AS o_late_rate
        FROM review_base
        WHERE review_score = 1
    )
SELECT
    'Total Throughput' AS metric,
    o_throughput AS one_star_avg,
    p_throughput AS platform_avg,
    (o_throughput - p_throughput) AS difference
FROM one_star_avg, plaftform_average

UNION ALL

SELECT
    'Dispatch (Stage 2)',
    o_dispatch,
    p_dispatch,
    (o_dispatch - p_dispatch) AS difference
FROM one_star_avg, plaftform_average

UNION ALL

SELECT
    'Dispatch (Stage 3)',
    o_transit,
    p_transit,
    (o_transit - p_transit) AS difference
FROM one_star_avg, plaftform_average

UNION ALL

SELECT
    'Late Rate',
    o_late_rate,
    p_late_rate,
    (o_late_rate - p_late_rate) AS difference
FROM one_star_avg, plaftform_average;

SELECT
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS one_star_count,
    ROUND(AVG(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END),2) AS one_star_rate
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
JOIN olist_sellers s
    ON s.seller_id = oi.seller_id
LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score FROM olist_order_reviews GROUP BY order_id) r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY one_star_rate DESC;