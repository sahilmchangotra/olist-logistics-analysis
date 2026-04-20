-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ8 - Delhivery — Operations Analytics Interview
-- This is from our carrier performance team. We want to identify our gold-standard routes — seller state to
-- customer state combinations where 100% of orders were delivered on time (actual delivery <= estimated
-- delivery). Show the route, total orders, on-time orders, on-time rate, and average delivery days. Only
-- include routes with at least 20 orders to exclude statistical flukes. Order by total orders descending — we
-- want to see the highest-volume perfect routes first.
-- =====================================================================================================================

    SELECT
        s.seller_state ||' -> '|| c.customer_state AS route,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date) AS on_time_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0), 2) AS on_time_rate_pct,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date -
                                      o.order_delivered_carrier_date))/86400)::NUMERIC,2) AS avg_delivery_days,
        CASE
            WHEN COUNT(DISTINCT o.order_id) FILTER (
                WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date)
                     = COUNT(DISTINCT o.order_id) THEN 'Gold Standard' ELSE '' END AS route_flag
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_state, c.customer_state
    HAVING COUNT(DISTINCT o.order_id) >= 20
    ORDER BY total_orders DESC;