-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ6 -   Myntra Category Analytics Lead
-- I'm doing a category health review and I want to understand which product categories are consistently failing customers
-- on delivery promises. Late deliveries damage our review scores and increase returns. For each product category show me
-- total orders, late orders, late rate percentage, average delivery days, and rank them from worst to best. Only include
-- categories with at least 100 orders.
-- Output: product_category_name, total_orders, late_orders, late_rate_pct, avg_delivery_days, rank.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        COALESCE(p.product_category_name, 'Uncategorized') AS category_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) AS late_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0), 2) AS late_rate_pct,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400)::NUMERIC, 2) AS avg_delivery_days
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT o.order_id) >= 100
)
SELECT
    category_name,
    total_orders,
    late_orders,
    late_rate_pct,
    avg_delivery_days,
    DENSE_RANK() OVER (ORDER BY late_rate_pct DESC) AS rank
FROM order_base
ORDER BY rank;