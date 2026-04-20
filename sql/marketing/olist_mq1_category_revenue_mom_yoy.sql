-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ1 -   BOL Category Marketing
--  I need a full revenue performance report by product category. Show me each category's monthly revenue, the month-over-month
--  change in revenue, and a YoY comparison using LAG(12) to compare the same month last year. Flag categories as Growing,
--  Declining or New (no data last year). This goes into our quarterly category review deck.
--  Output: category, month, monthly_revenue, mom_change_pct, same_month_last_year, yoy_change_pct, trend_flag."
-- =====================================================================================================================

WITH revenue_base AS(
    SELECT
        COALESCE(p.product_category_name,'Unknown') AS product_category_name,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY p.product_category_name, DATE_TRUNC('month', o.order_purchase_timestamp)
),
    previous_months AS(
        SELECT
            *,
            LAG(monthly_revenue, 1) OVER (PARTITION BY product_category_name ORDER BY month) AS prev_month,
            LAG(monthly_revenue, 12) OVER (PARTITION BY product_category_name ORDER BY month) AS same_month_ly
        FROM revenue_base
    )
        SELECT
            product_category_name,
            TO_CHAR(month, 'YYYY-MM') AS month,
            monthly_revenue,
            ROUND((monthly_revenue - prev_month) * 100.0 / NULLIF(prev_month,0), 2) AS mom_change_pct,
            ROUND((monthly_revenue - same_month_ly) * 100.0 / NULLIF(same_month_ly,0), 2) AS yoy_change_pct,
            CASE
                WHEN same_month_ly IS NULL THEN 'New'
                WHEN monthly_revenue > same_month_ly THEN 'Growing'
                ELSE 'Declining'
            END AS trend_flag
        FROM previous_months
ORDER BY month, monthly_revenue;