-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ3 -   BOL Performance Marketing :
--   I need to understand how our payment method mix affects revenue. For each payment type show total revenue,
--   average order value, average installments, and what percentage of total revenue each payment type represents.
--   Also flag if average installments are above the platform average — high installment usage signals price-sensitive
--   customers. Output: payment_type, total_revenue, avg_order_value, avg_installments, revenue_share_pct, installment_flag.
-- =====================================================================================================================

WITH payment_base AS(
    SELECT
        p.payment_type,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        ROUND(AVG(oi.price + oi.freight_value), 2) AS average_order_value,
        ROUND(AVG(p.payment_installments),2) AS avg_installment
    FROM olist_orders o
    JOIN olist_order_payments p
        ON o.order_id = p.order_id
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.payment_type
),
    aggregating AS(
        SELECT
            *,
            AVG(avg_installment) OVER () AS platform_average,
            ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share_pct
        FROM payment_base
    )
SELECT
    payment_type,
    total_revenue,
    average_order_value,
    avg_installment,
    platform_average,
    revenue_share_pct,
    CASE
        WHEN avg_installment > platform_average THEN 'High Installments'
        ELSE 'Normal' END AS installment_flag
FROM aggregating
ORDER BY revenue_share_pct DESC;