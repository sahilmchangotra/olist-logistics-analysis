-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ4 -   Myntra Head of Logistics
--  I need to understand which seller-to-customer state routes are consistently failing on delivery. We're planning our
--  carrier contracts for next year and I need hard data on which routes have the worst on-time performance. Define a late
--  delivery as actual delivery date exceeding the estimated delivery date. Show me all routes with at least 30 orders,
--  their total orders, late orders, late rate percentage, and rank them worst to best. Output: route, total_orders,
--  late_orders, late_rate_pct, rank.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        s.seller_city ||' -> '|| c.customer_city AS delivery_route,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date
                                > o.order_estimated_delivery_date) AS late_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date
                                > o.order_estimated_delivery_date) * 100.0 /
                    NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS late_rate_pct
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY s.seller_city ||' -> '|| c.customer_city
    HAVING COUNT(DISTINCT o.order_id) >= 30
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY late_rate_pct DESC) AS rank
        FROM order_base
    )
SELECT
    delivery_route,
    total_orders,
    late_orders,
    late_rate_pct,
    rank
FROM ranking
ORDER BY rank;