-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ7 - BOL Category Marketing:
--  I need a pivot table for our quarterly category review. For our top 10 revenue categories, show me their revenue broken
--  down by quarter — Q1, Q2, Q3, Q4 — as columns. Also add a total column and a best quarter column showing which quarter
--  peaked for each category. Output: product_category_name, q1_revenue, q2_revenue, q3_revenue, q4_revenue, total_revenue,
--  best_quarter.
-- =====================================================================================================================

WITH revenue_base AS(
    SELECT
        COALESCE(p.product_category_name,'Unknown') AS product_category_name,
        SUM(oi.price + oi.freight_value) AS monthly_revenue,
        EXTRACT(QUARTER FROM o.order_purchase_timestamp) AS quarter
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY COALESCE(p.product_category_name,'Unknown'), EXTRACT(QUARTER FROM o.order_purchase_timestamp)
),
    pivoting AS(
        SELECT
            product_category_name,
            SUM(monthly_revenue) FILTER (WHERE quarter = 1) AS q1_revenue,
            SUM(monthly_revenue) FILTER (WHERE quarter = 2) AS q2_revenue,
            SUM(monthly_revenue) FILTER (WHERE quarter = 3) AS q3_revenue,
            SUM(monthly_revenue) FILTER (WHERE quarter = 4) AS q4_revenue,
            SUM(monthly_revenue) AS total_revenue
        FROM revenue_base
        GROUP BY product_category_name
    ),
    ranking AS(
        SELECT
            product_category_name,
            q1_revenue,
            q2_revenue,
            q3_revenue,
            q4_revenue,
            total_revenue,
            CASE
                WHEN GREATEST(q1_revenue, q2_revenue, q3_revenue, q4_revenue) = q1_revenue THEN 'Q1'
                WHEN GREATEST(q1_revenue, q2_revenue, q3_revenue, q4_revenue) = q2_revenue THEN 'Q2'
                WHEN GREATEST(q1_revenue, q2_revenue, q3_revenue, q4_revenue) = q3_revenue THEN 'Q3'
                ELSE 'Q4'
            END AS best_quarter,
            DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS rank
        FROM pivoting
    )
SELECT
    *
FROM ranking
WHERE rank <= 10
ORDER BY rank;