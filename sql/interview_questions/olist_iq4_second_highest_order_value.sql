-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ4 - Uber Data Analyst Interview:
-- This is from our customer spend analytics team. For each customer find their second highest order value — not their
-- best order but their second best. This helps us understand whether high spenders are consistently high or just one-time
-- big buyers. Return customer_unique_id, their second highest order value, their highest order value, the gap between the
-- two, and total number of orders. Only show customers with at least 2 orders. This is a classic window function question
-- we use in every data analyst screen.
-- =====================================================================================================================


WITH customer_base AS(
    SELECT
        c.customer_unique_id,
        o.order_id,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, o.order_id
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (PARTITION BY customer_unique_id ORDER BY order_value DESC) AS rank,
            COUNT(*) OVER (PARTITION BY customer_unique_id) AS total_orders
        FROM customer_base
    ),
    second_highest_value AS(
        SELECT
            customer_unique_id,
            total_orders,
            order_value AS second_highest_order_value
        FROM ranking
        WHERE rank = 2
        AND total_orders >= 2
    ),
    highest_value AS(
        SELECT
            customer_unique_id,
            total_orders,
            order_value AS highest_order_value
        FROM ranking
        WHERE rank = 1
        AND total_orders >= 2
    ),
    joining AS(
        SELECT
            s.customer_unique_id,
            s.total_orders,
            s.second_highest_order_value,
            h.highest_order_value
        FROM second_highest_value s
        LEFT JOIN highest_value h
            ON s.customer_unique_id = h.customer_unique_id
)
SELECT
    customer_unique_id,
    total_orders,
    second_highest_order_value,
    highest_order_value,
    ROUND(highest_order_value - second_highest_order_value, 2) AS value_gap
FROM joining
ORDER BY second_highest_order_value DESC
LIMIT 10;