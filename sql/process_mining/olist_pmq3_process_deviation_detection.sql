-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ3 - JET SODA Network Planning:
-- I want to find orders that deviated significantly from normal process time. For each order calculate the total throughput
-- days and compare it to the network average. Flag orders as Normal (within 1 standard deviation), Delayed (1-2 SD above avg),
-- or Critical Deviation (>2 SD above avg). Show me a summary count and % per deviation category, and the top 10 worst
-- individual orders.
-- Output summary: deviation_category,order_count, pct_of_total. Output top 10: order_id, seller_state, customer_state,
-- total_days, network_avg, deviation_days, deviation_flag.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        o.order_id,
        s.seller_state,
        c.customer_state,
        ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC,2) AS total_days
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
),
    aggregating AS(
        SELECT
            *,
            AVG(total_days) OVER() AS network_avg,
            STDDEV(total_days) OVER () AS network_std,
            total_days - AVG(total_days) OVER() AS deviation_days
        FROM order_base
    )
--- Output Summary ---
SELECT
    CASE
        WHEN total_days > (network_avg + 2 * network_std) THEN 'Critical Deviation'
        WHEN total_days > (network_avg + 1 * network_std) THEN 'Delayed'
        ELSE 'Normal'
    END AS deviation_category,
    COUNT(DISTINCT order_id) AS order_count
FROM aggregating
GROUP BY CASE
        WHEN total_days > (network_avg + 2 * network_std) THEN 'Critical Deviation'
        WHEN total_days > (network_avg + 1 * network_std) THEN 'Delayed'
        ELSE 'Normal'
    END
ORDER BY deviation_category;

--- Output top 10 ---
WITH order_base AS(
    SELECT
        o.order_id,
        s.seller_state,
        c.customer_state,
        ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC,2) AS total_days
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
),
    aggregating AS(
        SELECT
            *,
            AVG(total_days) OVER() AS network_avg,
            STDDEV(total_days) OVER () AS network_std,
            total_days - AVG(total_days) OVER() AS deviation_days
        FROM order_base
    )
SELECT
    order_id,
    seller_state,
    customer_state,
    total_days,
    ROUND(network_avg,2) AS network_avg,
    ROUND(network_std,2) AS network_std,
    ROUND(deviation_days,2) AS deviation_days,
    CASE
        WHEN total_days > (network_avg + 2 * network_std) THEN 'Critical Deviation'
        WHEN total_days > (network_avg + 1 * network_std) THEN 'Delayed'
        ELSE 'Normal'
    END AS deviation_flag
FROM aggregating
ORDER BY total_days DESC
LIMIT 10;