-- =====================================================================================================================
-- Introducing - Customer Logistics Questions
-- ✅ CQ1 - Myntra Customer Analytics:
-- I need a full customer acquisition funnel by month. For each month show total new customers (first ever order), how many
-- of those placed a second order within 30 days, how many placed a third order ever, and the drop-off rate at each stage.
-- This helps us understand where we lose customers earliest. Output: month, new_customers, second_order_30d, third_order_ever,
-- stage1_dropoff_pct, stage2_dropoff_pct.
-- =====================================================================================================================

WITH customer_first_order AS(
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS acquisition_month,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
),
    customer_second_order AS(
        SELECT
            f.customer_unique_id,
            f.acquisition_month,
            o2.order_id AS second_order_id
        FROM customer_first_order f
        JOIN olist_customers c
            ON c.customer_unique_id = f.customer_unique_id
        LEFT JOIN olist_orders o2
            ON o2.customer_id = c.customer_id
            AND o2.order_status = 'delivered'
            AND o2.order_purchase_timestamp > f.first_order_date
            AND o2.order_purchase_timestamp <= f.first_order_date + INTERVAL '30 days'

    ),
    customer_third_order AS(
        SELECT
            f.customer_unique_id
        FROM customer_first_order f
        JOIN olist_customers c
            ON c.customer_unique_id = f.customer_unique_id
        LEFT JOIN olist_orders o3
            ON o3.customer_id = c.customer_id
            AND o3.order_status = 'delivered'
        GROUP BY f.customer_unique_id
        HAVING COUNT(DISTINCT o3.order_id) >= 3
    ),
        aggregating AS (SELECT TO_CHAR(s.acquisition_month, 'YYYY-MM')                                            AS acquisition_month,
                               COUNT(DISTINCT s.customer_unique_id)                                               AS new_customers,
                               COUNT(DISTINCT s.customer_unique_id)
                               FILTER ( WHERE s.second_order_id IS NOT NULL)                                      AS second_order_30d,
                               COUNT(DISTINCT t.customer_unique_id)                                               AS third_order_ever
                        FROM customer_second_order s
                                 LEFT JOIN customer_third_order t
                                           ON s.customer_unique_id = t.customer_unique_id
                        GROUP BY TO_CHAR(s.acquisition_month, 'YYYY-MM')
                        )
SELECT
    acquisition_month,
    new_customers,
    second_order_30d,
    third_order_ever,
    ROUND((new_customers - second_order_30d) * 100.0 / NULLIF(new_customers,0),2) AS stage1_dropoff_pct,
    ROUND((second_order_30d - third_order_ever) * 100.0 / NULLIF(second_order_30d,0),2) AS stage2_dropoff_pct
FROM aggregating
ORDER BY acquisition_month;