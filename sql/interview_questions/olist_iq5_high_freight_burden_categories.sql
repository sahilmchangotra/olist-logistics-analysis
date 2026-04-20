-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ5 - Swiggy Data Analyst Interview:
-- This is from our category economics team. We want to identify product categories where the freight cost is
-- disproportionately high relative to the order value — specifically where freight exceeds 30% of total order value.
-- High freight burden categories are either priced too low or shipped inefficiently. Return the category name,
-- total orders, average order value, average freight value, average freight burden percentage, and rank them highest
-- freight burden first. Only include categories with at least 100 orders.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        p.product_category_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(AVG(oi.price + oi.freight_value),2) AS avg_order_value,
        ROUND(AVG(oi.freight_value), 2) AS avg_freight_value,
        ROUND(AVG(oi.freight_value * 100.0 / NULLIF((oi.price + oi.freight_value),0)), 2) AS avg_freight_burden_pct
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY avg_freight_burden_pct DESC) AS rank
        FROM order_base
    )
SELECT
    product_category_name,
    total_orders,
    avg_order_value,
    avg_freight_value,
    avg_freight_burden_pct,
    rank
FROM ranking
WHERE avg_freight_burden_pct > 30
    AND total_orders >= 100
ORDER BY rank;