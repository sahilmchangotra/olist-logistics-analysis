WITH item_base AS(
    SELECT
        o.order_id,
        SUM(oi.price + oi.freight_value) AS order_value,
        SUM(oi.freight_value) AS freight_value
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
),
    payment_base AS(
        SELECT
            order_id,
            MAX(payment_installments) AS installments
        FROM olist_order_payments
        GROUP BY order_id
    ),
    combining_data AS(
        SELECT
            i.order_id,
            i.order_value,
            i.freight_value,
            CASE
                WHEN p.installments = 1 THEN '1 - Single Payment'
                WHEN p.installments BETWEEN 2 AND 3 THEN '2 - 2-3 Installments'
                WHEN p.installments BETWEEN 4 AND 6 THEN '3 - 4-6 Installments'
                WHEN p.installments BETWEEN 7 AND 12 THEN '4 - 7-12 Installments'
                ELSE '5 - 12+ Installments'
            END AS installment_bucket
        FROM item_base i
        LEFT JOIN payment_base p
            ON i.order_id = p.order_id
    )
SELECT
    installment_bucket,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(order_value), 2) AS avg_order_value,
    ROUND(AVG(freight_value * 100 /
              NULLIF(order_value,0)), 2) AS avg_freight_pct,
    ROUND(SUM(order_value) * 100 /
          SUM(SUM(order_value)) OVER (), 2) AS revenue_share_pct
FROM combining_data
GROUP BY installment_bucket
ORDER BY installment_bucket;