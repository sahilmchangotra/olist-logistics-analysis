-- =====================================================================================================================
-- Introducing - Customer Logistics Questions
-- ✅ CQ3 - Myntra Growth:
--  I need a cohort retention analysis. Group customers by their acquisition month — the month they placed their first
--  ever order. Then for each cohort show how many customers returned in month 1, month 2 and month 3 after acquisition.
--  Show both absolute numbers and retention percentages. Output: cohort_month, cohort_size, retained_month1,
--  retained_month2, retained_month3, pct_month1, pct_month2, pct_month3.
-- =====================================================================================================================

WITH cohort_base AS(
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date,
        DATE_TRUNC('month',MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
),
    cohort_size AS(
        SELECT
            cohort_month,
            COUNT(DISTINCT customer_unique_id) AS cohort_customers
        FROM cohort_base
        GROUP BY cohort_month
    ),
    retention_joins AS(
        SELECT
            cb.customer_unique_id,
            cb.cohort_month,
            o1.order_id AS order_month1,
            o2.order_id AS order_month2,
            o3.order_id AS order_month3
        FROM cohort_base cb
        JOIN olist_customers c
            ON c.customer_unique_id = cb.customer_unique_id
        LEFT JOIN olist_orders o1
            ON o1.customer_id = c.customer_id
            AND o1.order_status = 'delivered'
            AND DATE_TRUNC('month', o1.order_purchase_timestamp) = cb.cohort_month + INTERVAL '1 month'
        LEFT JOIN olist_orders o2
            ON o2.customer_id = c.customer_id
            AND o2.order_status = 'delivered'
            AND DATE_TRUNC('month',o2.order_purchase_timestamp) = cb.cohort_month + INTERVAL '2 month'
        LEFT JOIN olist_orders o3
            ON o3.customer_id = c.customer_id
            AND o3.order_status = 'delivered'
            AND DATE_TRUNC('month',o3.order_purchase_timestamp) = cohort_month + INTERVAL '3 month'
    )
SELECT
    TO_CHAR(cs.cohort_month, 'YYYY-MM') AS cohort_month,
    cs.cohort_customers AS cohort_size,
    COUNT(DISTINCT rj.customer_unique_id) FILTER ( WHERE rj.order_month1 IS NOT NULL ) AS retained_month1,
    COUNT(DISTINCT rj.customer_unique_id) FILTER ( WHERE rj.order_month2 IS NOT NULL ) AS retained_month2,
    COUNT(DISTINCT rj.customer_unique_id) FILTER ( WHERE rj.order_month3 IS NOT NULL ) AS retained_month3,
    ROUND((COUNT(DISTINCT rj.customer_unique_id) FILTER (
        WHERE rj.order_month1 IS NOT NULL )) * 100.0 / NULLIF(cs.cohort_customers,0),2) AS pct_month1,
    ROUND((COUNT(DISTINCT rj.customer_unique_id) FILTER (
        WHERE rj.order_month2 IS NOT NULL )) * 100.0 / NULLIF(cs.cohort_customers,0),2) AS pct_month2,
    ROUND((COUNT(DISTINCT rj.customer_unique_id) FILTER (
        WHERE rj.order_month3 IS NOT NULL )) * 100.0 / NULLIF(cs.cohort_customers,0),2) AS pct_month3
FROM cohort_size cs
LEFT JOIN retention_joins rj
    ON cs.cohort_month = rj.cohort_month
GROUP BY cs.cohort_month, cs.cohort_customers
HAVING cs.cohort_customers >= 100
ORDER BY cs.cohort_month;