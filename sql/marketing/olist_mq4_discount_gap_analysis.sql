-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ4 -   BOL Performance Marketing :
--  I want to understand how our discount and promotional activity impacts revenue. Some orders have a difference between
--  the item price and what the customer actually paid through payment value. I want to see a monthly breakdown showing
--  total gross revenue (sum of item prices), total payment revenue (sum of payment values), the discount gap between them,
--  and the discount rate as a percentage. Also flag months where the discount rate exceeds 10% — those are heavy promotion
--  months. Output: month, gross_revenue, payment_revenue, discount_gap, discount_rate_pct, promo_flag.
-- =====================================================================================================================

WITH item_revenue AS(
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS gross_revenue
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY o.order_id, DATE_TRUNC('month', o.order_purchase_timestamp)
),
    payment_revenue AS(
        SELECT
            order_id,
            SUM(payment_value) AS payment_revenue
        FROM olist_order_payments
        GROUP BY order_id
    ),
    monthly AS(
        SELECT
            i.month,
            SUM(i.gross_revenue) AS gross_revenue,
            SUM(p.payment_revenue) AS payment_revenue
        FROM item_revenue i
        LEFT JOIN payment_revenue p
            ON i.order_id = p.order_id
        GROUP BY i.month
    ),
    aggregating AS(
        SELECT
            *,
            ROUND(gross_revenue - payment_revenue) AS discount_gap,
            ROUND((gross_revenue - payment_revenue) * 100.0 /
                  gross_revenue, 2) AS discount_rate_pct
        FROM monthly
    )
SELECT
    TO_CHAR(month,'YYYY-MM') AS month,
    gross_revenue,
    payment_revenue,
    discount_gap,
    discount_rate_pct,
    CASE
        WHEN discount_rate_pct > 10 THEN 'Heavy Promotion Month'
        WHEN discount_rate_pct > 5 THEN 'Moderate'
        ELSE 'Normal' END AS promo_flag
FROM aggregating
ORDER BY month;