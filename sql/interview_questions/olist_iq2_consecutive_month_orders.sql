-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ2 - Flipkart Product Analytics Interview:
-- This is a question from our customer retention team's technical screen. Find all customers who placed orders in at
-- least 3 consecutive calendar months. Return the customer_id, streak start month, streak end month, and streak length
-- in months. We use this to identify our most engaged customers for our loyalty programme. This tests whether candidates
-- understand the gaps-and-islands pattern.
-- =====================================================================================================================

WITH order_base AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
        AND o.order_purchase_timestamp IS NOT NULL
),
ranking AS (
    SELECT
        customer_unique_id,
        order_month,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_month) AS rn
    FROM order_base
),
aggregation AS (
    SELECT
        customer_unique_id,
        order_month,
        order_month::TIMESTAMP - (rn * INTERVAL '1 month') AS streak_group
    FROM ranking
)
SELECT
    customer_unique_id,
    COUNT(*)         AS streak_length,
    MIN(order_month) AS streak_start,
    MAX(order_month) AS streak_end
FROM aggregation
GROUP BY customer_unique_id, streak_group
HAVING COUNT(*) >= 3
ORDER BY streak_length DESC;