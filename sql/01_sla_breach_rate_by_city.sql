-- 01. SLA Breach Rate by City
-- Business Question:
-- Which cities have the worst delivery SLA performance?
-- SLA breach = order delivered more than 3 days after the estimated delivery date.
-- Only include cities with at least 50 delivered orders.

WITH order_delivery AS (
    SELECT
        c.customer_city AS city,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date + INTERVAL '3 days'
            THEN 1 ELSE 0
        END AS sla_breach
    FROM kaggle.olist_orders o
    JOIN kaggle.olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
city_sla AS (
    SELECT
        city,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(sla_breach) AS total_breaches,
        ROUND(SUM(sla_breach) * 100.0 / NULLIF(COUNT(*), 0), 2) AS breach_rate_pct
    FROM order_delivery
    GROUP BY city
    HAVING COUNT(*) >= 50
)
SELECT
    city,
    total_orders,
    total_breaches,
    breach_rate_pct,
    DENSE_RANK() OVER (ORDER BY breach_rate_pct DESC) AS rank
FROM city_sla
ORDER BY rank;