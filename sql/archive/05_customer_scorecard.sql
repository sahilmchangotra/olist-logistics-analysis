WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)                                        AS total_orders,
        SUM(oi.price)                                                     AS total_revenue,
        ROUND(AVG(r.review_score), 2)                                     AS avg_review_score,
        ROUND(AVG(DATE_PART('day', o.order_delivered_customer_date -
                  o.order_purchase_timestamp))::NUMERIC, 2)               AS avg_delivery_days,
        ROUND(AVG(CASE
                    WHEN o.order_delivered_customer_date >
                         o.order_estimated_delivery_date + INTERVAL '3 days'
                    THEN 1 ELSE 0
                  END) * 100.0, 2)                                        AS late_delivery_pct
    FROM olist_orders o
    JOIN olist_order_items oi      ON o.order_id = oi.order_id
    JOIN olist_customers c         ON o.customer_id = c.customer_id
    LEFT JOIN (
        SELECT order_id, AVG(review_score) AS review_score
        FROM olist_order_reviews
        GROUP BY order_id
    ) r                            ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) >= 2
)
SELECT
    customer_unique_id,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2)  AS total_revenue,
    avg_review_score,
    avg_delivery_days,
    late_delivery_pct,
    CASE
        WHEN total_revenue > 1000  THEN 'VIP'
        WHEN total_revenue >= 200  THEN 'Regular'
        ELSE                            'Occasional'
    END AS customer_segment
FROM customer_orders
ORDER BY total_revenue DESC;