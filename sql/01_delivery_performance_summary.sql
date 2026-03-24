-- 01. Delivery Performance Summary
-- Stakeholder question:
-- What is the overall delivery performance in terms of on-time, early, and late deliveries?
-- Count delivered orders by delivery status and show their percentage share.

SELECT
    CASE
        WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 'early'
        WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 'on_time'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM olist_orders o
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status
ORDER BY total_orders DESC;