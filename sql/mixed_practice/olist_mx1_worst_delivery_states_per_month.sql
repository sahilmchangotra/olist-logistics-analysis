-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX1 - Theme - Logistics
-- Top 3 Worst Delivery States by Late Rate Per Month  | JET SODA Amsterdam | Network Planning:
-- I need to see which customer states have the worst late delivery rates each month. Late =
-- order_delivered_customer_date > order_estimated_delivery_date. For each month and state combination
-- (minimum 30 orders), compute: order_month, customer_state, total_orders, late_orders, late_rate_pct.
-- Then rank states within each month using DENSE_RANK — rank 1 = worst late rate. Show only the top 3
-- worst states per month. Order by order_month, rank ascending.
-- =====================================================================================================================

WITH customer_base AS(
    SELECT
        c.customer_state,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) AS late_orders,
        ROUND((COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date)) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0),2) AS late_rate_pct
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1,2
    HAVING COUNT(DISTINCT o.order_id) >= 30
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (PARTITION BY order_month ORDER BY late_rate_pct DESC) AS rank
        FROM customer_base
    )
SELECT
    customer_state,
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    total_orders,
    late_orders,
    late_rate_pct,
    rank
FROM ranking
WHERE rank <= 3
ORDER BY order_month, rank;