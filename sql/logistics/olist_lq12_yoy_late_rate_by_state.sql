-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ12 - Myntra Head of Logistics
-- I need to close out the logistics review with a year-over-year performance comparison by seller state. For each seller
-- state show me the late rate in 2017 vs 2018, the YoY change in percentage points, and flag whether the state is
-- Improving, Worsening or Stable (within 1pp). I also want the absolute number of additional late orders in 2018 vs 2017
-- so I can quantify the business impact. Only include states with at least 100 orders in both years. Output: seller_state,
-- late_rate_2017, late_rate_2018, yoy_change_pp, additional_late_orders, trend_flag, ranked worst to best by yoy_change.
-- =====================================================================================================================

WITH orders_2017 AS(
    SELECT
        s.seller_state,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) AS late_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0), 2) AS late_rate_2017
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND TO_CHAR(o.order_purchase_timestamp, 'YYYY') = '2017'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY s.seller_state
    HAVING COUNT(DISTINCT o.order_id) >= 100
),
    order_2018 AS(
        SELECT
            s.seller_state,
            COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) AS late_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100.0 /
              NULLIF(COUNT(DISTINCT o.order_id),0), 2) AS late_rate_2018
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND TO_CHAR(o.order_purchase_timestamp, 'YYYY') = '2018'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY s.seller_state
    HAVING COUNT(DISTINCT o.order_id) >= 100
    ),
    orders_combined AS(
        SELECT
            y17.seller_state,
            y17.late_rate_2017,
            y18.late_rate_2018,
            y18.late_orders - y17.late_orders AS additional_late_orders,
            ROUND((y18.late_rate_2018 - y17.late_rate_2017), 2) AS yoy_change_pp
        FROM orders_2017 y17
        JOIN order_2018 y18
            ON y17.seller_state = y18.seller_state
    )
SELECT
    seller_state,
    late_rate_2017,
    late_rate_2018,
    additional_late_orders,
    yoy_change_pp,
    CASE
        WHEN yoy_change_pp > 1 THEN 'Worsening'
        WHEN yoy_change_pp < - 1 THEN 'Improving'
        ELSE 'Stable'
    END AS flag,
    DENSE_RANK() OVER (ORDER BY yoy_change_pp DESC) AS rank
FROM orders_combined
ORDER BY rank;