-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ6 - BOL Product Ops:
--  I need a Pareto analysis of our product categories for the annual category review. Show me every category ranked by
--  total revenue, with each category's revenue share and cumulative revenue percentage. I want to validate whether 20%
--  of our categories generate 80% of revenue — the classic Pareto principle. Flag categories as Core (top 80% of revenue),
--  Secondary (80-95%) or Long Tail (bottom 5%). Output: rank, product_category_name, total_revenue, revenue_share_pct,
--  cumulative_pct, category_tier."
-- =====================================================================================================================

WITH product_base AS(
    SELECT
        COALESCE(p.product_category_name, 'Unknown') AS product_category_name,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(p.product_category_name, 'Unknown')
),
    aggregating AS(
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS rank,
            ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share_pct,
            ROUND(SUM(total_revenue) OVER (
                ORDER BY total_revenue DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) * 100.0 / SUM(total_revenue) OVER (), 2) AS cumulative_pct
        FROM product_base
    )
SELECT
    rank,
    product_category_name,
    total_revenue,
    revenue_share_pct,
    cumulative_pct,
    CASE
        WHEN cumulative_pct <= 80 THEN 'Core'
        WHEN cumulative_pct <= 95 THEN 'Secondary'
        ELSE 'Long Tail'
    END AS category_tier
FROM aggregating
ORDER BY rank;