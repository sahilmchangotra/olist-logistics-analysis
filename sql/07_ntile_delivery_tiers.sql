-- One row in base CTE = one delivered order (raw, not grouped)
WITH order_base AS (
    SELECT
        o.order_id,
        DATE_PART('day', o.order_delivered_customer_date -
                         o.order_purchase_timestamp)::NUMERIC   AS delivery_days,
        r.avg_review,
        CASE
            WHEN DATE(o.order_purchase_timestamp) < '2017-07-01'
                THEN 'Before July 2017'
            ELSE 'July 2017 onwards'
        END                                                     AS period_label
    FROM olist_orders o
    LEFT JOIN (
        SELECT order_id, AVG(review_score) AS avg_review
        FROM olist_order_reviews
        GROUP BY order_id
    ) r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
),
order_with_tier AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY delivery_days ASC) AS tier
    FROM order_base
),
tier_summary AS (
    SELECT
        tier,
        period_label,
        COUNT(DISTINCT order_id)              AS total_orders,
        ROUND(AVG(delivery_days)::NUMERIC, 2) AS avg_delivery_days,
        ROUND(AVG(avg_review)::NUMERIC, 2)    AS avg_review_score
    FROM order_with_tier
    GROUP BY tier, period_label
)
SELECT
    tier,
    period_label,
    total_orders,
    avg_delivery_days,
    avg_review_score
FROM tier_summary
ORDER BY tier, period_label;