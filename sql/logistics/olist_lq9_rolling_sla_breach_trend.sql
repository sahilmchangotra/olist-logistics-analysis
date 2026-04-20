-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ9 - JET SODA Logistics Operations
--   I need a daily pulse on our SLA performance rather than just monthly snapshots. Can you build me a rolling 7-day
--   SLA breach rate — for each day show the daily breach rate, the 7-day rolling average breach rate, and flag days where
--   the rolling average is worsening compared to the previous day's rolling average. This will feed into our real-time
--   operations dashboard. Output: order_date, daily_orders, daily_breach_rate, rolling_7d_breach_rate, trend_flag.
-- =====================================================================================================================

 WITH order_base AS(
     SELECT
         order_purchase_timestamp::DATE AS order_date,
         COUNT(DISTINCT order_id) AS daily_orders,
         COUNT(DISTINCT order_id) FILTER ( WHERE order_delivered_customer_date > order_estimated_delivery_date) AS total_sla_breach,
         ROUND(COUNT(DISTINCT order_id) FILTER ( WHERE order_delivered_customer_date > order_estimated_delivery_date) * 100.0 /
                NULLIF(COUNT(DISTINCT order_id), 0), 2) AS daily_breach_rate
     FROM olist_orders
     WHERE order_status = 'delivered'
        AND order_purchase_timestamp IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
     GROUP BY order_purchase_timestamp::DATE
     HAVING COUNT(DISTINCT order_id) >= 30
 ),
     rolling_average AS(
         SELECT
             *,
             ROUND(AVG(daily_breach_rate) OVER (
                 ORDER BY order_date
                 ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                 )::NUMERIC, 2) AS rolling_7d_avg
         FROM order_base
     ),
     previous_day AS(
         SELECT
             *,
             ROUND(LAG(rolling_7d_avg) OVER (ORDER BY order_date)::NUMERIC, 2) AS previous_rolling
         FROM rolling_average
     )
 SELECT
     order_date,
     daily_orders,
     daily_breach_rate,
     ROUND((rolling_7d_avg - previous_rolling) * 100.0 / previous_rolling, 2) AS rolling_7d_breach_rate,
     CASE
         WHEN rolling_7d_avg > previous_rolling THEN 'Worsening'
         WHEN rolling_7d_avg < previous_rolling THEN 'Improving'
         ELSE 'Stable'
     END AS flag
 FROM previous_day
 ORDER BY order_date, rolling_7d_breach_rate DESC;