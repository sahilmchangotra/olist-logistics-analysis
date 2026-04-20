-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ3 - Zomato Data Analyst Interview:
-- "This is from our city operations team's technical screen. For each customer city, find the peak hour of the day —
-- the hour with the highest number of orders. Return the city, peak hour, total orders in that peak hour, and the percentage
-- of that city's daily orders that fall in the peak hour. Only include cities with at least 50 total orders. We use this
-- to optimise rider allocation per city per hour."
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        c.customer_city,
        EXTRACT(HOUR FROM o.order_purchase_timestamp) AS hour,
        COUNT(DISTINCT o.order_id) AS hourly_orders
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_city, EXTRACT(HOUR FROM o.order_purchase_timestamp)
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (PARTITION BY customer_city ORDER BY hourly_orders DESC) AS hour_rank,
            SUM(hourly_orders) OVER (PARTITION BY customer_city) AS city_total_orders
        FROM order_base
    )
SELECT
    customer_city,
    hour,
    hourly_orders,
    city_total_orders,
    ROUND(hourly_orders * 100.0 / NULLIF(city_total_orders,0), 2) AS peak_hour_share_pct
FROM ranking
WHERE hour_rank = 1
    AND city_total_orders >= 50
ORDER BY city_total_orders DESC;