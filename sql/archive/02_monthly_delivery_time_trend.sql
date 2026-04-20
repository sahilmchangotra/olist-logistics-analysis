-- 02. Monthly Delivery Time Trend + 3-Month Rolling Average
-- Business Question:
-- Is the delivery network improving over time?
-- Show monthly average delivery days, a 3-month rolling average,
-- and flag months where average delivery time exceeds 15 days.

WITH delivery_days AS (
    SELECT
        order_id,
        TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month,
        DATE_PART('day', order_delivered_customer_date - order_purchase_timestamp) AS delivery_days
    FROM kaggle.olist_orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
),
monthly_avg AS (
    SELECT
        year_month,
        COUNT(order_id) AS total_orders,
        ROUND(AVG(delivery_days)::NUMERIC, 2) AS avg_delivery_days
    FROM delivery_days
    GROUP BY year_month
),
rolling_calc AS (
    SELECT
        *,
        ROUND(
            AVG(avg_delivery_days) OVER (
                ORDER BY year_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            )::NUMERIC,
            2
        ) AS rolling_3m_avg,
        CASE
            WHEN avg_delivery_days > 15 THEN 'Performance Alert'
            ELSE 'Within Target'
        END AS performance_flag
    FROM monthly_avg
)
SELECT
    year_month,
    total_orders,
    avg_delivery_days,
    rolling_3m_avg,
    performance_flag
FROM rolling_calc
ORDER BY year_month;