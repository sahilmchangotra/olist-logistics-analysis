-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ2 -   BOL Category Marketing
--  I want to understand which months consistently over or underperform on revenue. Build a seasonality index —
--  where 1.0 = average month, above 1.0 = stronger than average, below 1.0 = weaker. Show each month number, month name,
--  average monthly revenue, the index, and flag months as Peak Season, Off Season or Normal. Output: month_number, month_name,
--  avg_monthly_revenue, seasonality_index, season_flag."
-- =====================================================================================================================

WITH revenue_base AS(
    SELECT
        DATE_TRUNC('month',o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_TRUNC('month',o.order_purchase_timestamp)
),
    aggregating AS(
        SELECT
            EXTRACT(MONTH FROM month) AS month,
            TO_CHAR(month, 'Month') AS month_name,
            ROUND(AVG(monthly_revenue),2) AS avg_monthly_revenue
        FROM revenue_base
        GROUP BY EXTRACT(MONTH FROM month), TO_CHAR(month, 'Month')
    ),
    index AS(
        SELECT
            *,
            ROUND(avg_monthly_revenue / AVG(avg_monthly_revenue) OVER(), 2) AS seasonality_index
        FROM aggregating
    )
SELECT
    month,
    month_name,
    avg_monthly_revenue,
    seasonality_index,
    CASE
        WHEN seasonality_index = 1.0 THEN 'Average Month'
        WHEN seasonality_index > 1.0 THEN 'Stronger then Average'
        WHEN seasonality_index < 1.0 THEN 'Weaker'
    END AS season_flag
FROM index
ORDER BY avg_monthly_revenue DESC;