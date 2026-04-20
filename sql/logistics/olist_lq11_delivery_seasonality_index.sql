-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ11 - JET SODA Senior Logistics
-- I'm presenting to the board next month and I need to show whether our delivery performance has a seasonal pattern.
-- For each calendar month (1–12), calculate the average late rate across all years, then build a seasonality index —
-- where 1.0 = average month, above 1.0 = worse than average, below 1.0 = better than average. Also show the best and
-- worst year for each month so we can see if the network is improving year over year. Output: month_name, avg_late_rate,
-- seasonality_index, best_year, worst_year, index_flag.
-- =====================================================================================================================

WITH order_base AS (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp)  AS year,
        EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
        ROUND(COUNT(DISTINCT order_id) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date) * 100.0 /
            NULLIF(COUNT(DISTINCT order_id), 0), 2) AS late_rate_pct
    FROM olist_orders
    WHERE order_status = 'delivered'
        AND order_purchase_timestamp IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
    GROUP BY 1, 2
),
seasonality AS (
    SELECT
        month,
        ROUND(AVG(late_rate_pct), 2)  AS avg_late_rate,
        MIN(late_rate_pct)             AS best_rate,
        MAX(late_rate_pct)             AS worst_rate,
        (SELECT year FROM order_base o2
         WHERE o2.month = ob.month
         ORDER BY late_rate_pct ASC LIMIT 1)  AS best_year,
        (SELECT year FROM order_base o2
         WHERE o2.month = ob.month
         ORDER BY late_rate_pct DESC LIMIT 1) AS worst_year
    FROM order_base ob
    GROUP BY month
),
final AS (
    SELECT
        TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month') AS month_name,
        avg_late_rate,
        best_rate,
        worst_rate,
        best_year,
        worst_year,
        ROUND(avg_late_rate / NULLIF(AVG(avg_late_rate) OVER (), 0), 2) AS seasonality_index
    FROM seasonality
)
SELECT
    month_name,
    avg_late_rate,
    seasonality_index,
    best_year,
    best_rate,
    worst_year,
    worst_rate,
    CASE
        WHEN seasonality_index > 1.05 THEN '🔴 Above Average'
        WHEN seasonality_index < 0.95 THEN '🟢 Below Average'
        ELSE '🟡 Average'
    END AS index_flag
FROM final
ORDER BY seasonality_index DESC;