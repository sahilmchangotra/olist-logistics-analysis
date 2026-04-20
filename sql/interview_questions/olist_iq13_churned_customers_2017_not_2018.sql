-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ13 - Lazada Customer Analytics Interview :
-- This is from our churn analytics team. We want to identify customers who were active in 2017 — placed at least one
-- delivered order — but completely disappeared in 2018 with zero orders. These are our churned customers and we want to
-- target them with a win-back campaign. Return the customer_unique_id, their last order date in 2017, total orders in 2017,
-- total spend in 2017, and days since last order (calculated from 2018-01-01). Only show customers who had at least
-- 2 orders in 2017 so we focus on genuinely engaged customers who then churned. Order by total spend descending.
-- =====================================================================================================================

WITH order_2017 AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE AS last_order_date_2017,
        COUNT(DISTINCT o.order_id) AS total_orders_2017,
        SUM(oi.price + oi.freight_value) AS total_spend_2017
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND EXTRACT(YEAR FROM o.order_purchase_timestamp) = '2017'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) >= 2
),
    order_2018 AS(
        SELECT
            c.customer_unique_id
        FROM olist_orders o
        JOIN olist_customers c
            ON o.customer_id = c.customer_id
        WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = '2018'
            AND o.order_status = 'delivered'
    ),
    aggregating AS(
        SELECT
            y17.customer_unique_id,
            y17.last_order_date_2017,
            y17.total_orders_2017,
            y17.total_spend_2017,
            '2018-01-01'::DATE - y17.last_order_date_2017 AS days_since_last_order
        FROM order_2017 y17
        LEFT JOIN order_2018 y18
            ON y17.customer_unique_id = y18.customer_unique_id
        WHERE y18.customer_unique_id IS NULL
    )
SELECT
    customer_unique_id,
    last_order_date_2017,
    total_orders_2017,
    total_spend_2017,
    days_since_last_order
FROM aggregating
ORDER BY total_spend_2017 DESC;