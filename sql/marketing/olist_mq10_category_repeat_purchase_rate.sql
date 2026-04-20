-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ10 - BOL Product Ops:
-- I want to understand which product categories have the best and worst repeat purchase rates. For each category,
-- show how many customers bought from it, how many bought from it more than once using customer_unique_id, and the
-- repeat rate percentage. Only include categories with at least 200 customers. Rank by repeat rate.
-- Output: product_category_name, total_customers, repeat_customers, repeat_rate_pct, rank.
-- =====================================================================================================================

WITH product_base AS (
    SELECT
        COALESCE(p.product_category_name,'Unknown') AS product_category_name,
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_customers c
        ON c.customer_id = o.customer_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(p.product_category_name,'Unknown'), c.customer_unique_id
),
    aggregating AS(
        SELECT
            product_category_name,
            COUNT(DISTINCT customer_unique_id) AS total_customers,
            COUNT(DISTINCT customer_unique_id) FILTER ( WHERE order_count > 1) AS repeat_customers,
            ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE order_count > 1) * 100.0 /
                NULLIF(COUNT(DISTINCT customer_unique_id),0), 2) AS repeat_rate_pct
        FROM product_base
        GROUP BY product_category_name
        HAVING COUNT(DISTINCT customer_unique_id) >= 200
    )
SELECT
    product_category_name,
    total_customers,
    repeat_customers,
    repeat_rate_pct,
    DENSE_RANK() OVER (ORDER BY repeat_rate_pct DESC) AS rank
FROM aggregating
ORDER BY rank;