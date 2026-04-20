-- One row in base CTE = one order per customer
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price) AS order_revenue
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_customers c    ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id, o.order_id, o.order_purchase_timestamp
),
customer_with_next AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp                                AS first_order_date,
        LEAD(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        )                                                       AS second_order_date,
        order_revenue                                           AS first_order_revenue,
        LEAD(order_revenue) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        )                                                       AS second_order_revenue
    FROM customer_orders
)
SELECT
    customer_unique_id,
    DATE(first_order_date)                                              AS first_order_date,
    DATE(second_order_date)                                             AS second_order_date,
    DATE_PART('day', second_order_date - first_order_date)::NUMERIC    AS days_between,
    ROUND((first_order_revenue + second_order_revenue)::NUMERIC, 2)    AS lifetime_revenue
FROM customer_with_next
WHERE second_order_date IS NOT NULL
    AND DATE_PART('day', second_order_date - first_order_date) <= 30
    AND DATE_PART('day', second_order_date - first_order_date) > 0
ORDER BY days_between ASC;