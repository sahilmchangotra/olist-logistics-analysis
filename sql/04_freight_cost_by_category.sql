-- 04. Freight Cost by Category
-- Business Question:
-- For each product category, give total orders, total freight cost,
-- average freight per order, and freight as a percentage of total revenue (freight + price).
-- Only include categories with at least 100 orders.
-- Rank categories by total freight cost in descending order.

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.freight_value) AS total_freight_cost,
    ROUND(SUM(oi.freight_value) / COUNT(DISTINCT oi.order_id), 2) AS avg_freight_per_order,
    ROUND(
        SUM(oi.freight_value) * 100.0 / NULLIF(SUM(oi.freight_value + oi.price), 0),
        2
    ) AS freight_pct_of_revenue,
    RANK() OVER (ORDER BY SUM(oi.freight_value) DESC) AS freight_cost_rank
FROM olist_order_items oi
JOIN olist_products p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY freight_cost_rank;