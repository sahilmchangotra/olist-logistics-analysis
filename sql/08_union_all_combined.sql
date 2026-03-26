-- One row in base CTE = one order_item joined with payment and order
WITH order_base AS (
    SELECT
        o.order_id,
        o.order_status,
        oi.price,
        DATE_PART('day', o.order_delivered_customer_date -
                         o.order_purchase_timestamp)::NUMERIC AS delivery_days,
        p.payment_type
    FROM olist_orders o
    JOIN olist_order_items oi    ON o.order_id = oi.order_id
    JOIN olist_order_payments p  ON o.order_id = p.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
)

-- Part 1: Orders and revenue by order status
SELECT
    'Part 1 - Orders and revenue by order status'  AS analysis,
    order_status                                    AS label,
    NULL::VARCHAR                                   AS payment_type,
    COUNT(DISTINCT order_id)                        AS total_orders,
    ROUND(SUM(price)::NUMERIC, 2)                  AS total_revenue,
    NULL::NUMERIC                                   AS avg_delivery_days
FROM order_base
GROUP BY order_status

UNION ALL

-- Part 2: Avg delivery days (delivered only)
SELECT
    'Part 2 - Avg delivery days by order status',
    order_status,
    NULL::VARCHAR,
    NULL::BIGINT,
    NULL::NUMERIC,
    ROUND(AVG(delivery_days)::NUMERIC, 2)
FROM order_base
WHERE order_status = 'delivered'
    AND delivery_days IS NOT NULL
GROUP BY order_status

UNION ALL

-- Part 3: Orders by payment type
SELECT
    'Part 3 - Orders by payment type',
    NULL::VARCHAR,
    payment_type,
    COUNT(DISTINCT order_id),
    NULL::NUMERIC,
    NULL::NUMERIC
FROM order_base
GROUP BY payment_type

ORDER BY analysis, label;