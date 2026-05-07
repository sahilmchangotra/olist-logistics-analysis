-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ9 - Time-to-Second-Purchase  | Myntra | Growth & Retention:
-- We run re-engagement email campaigns at 7, 14, and 30 days after first purchase. To optimise the
-- timing, I need to know: for customers who DID make a second purchase, how many days after their first
-- order did it happen? Show: a distribution in buckets: 0-7 days, 8-14 days, 15-30 days, 31-60 days, 61-90
-- days, 90+ days. For each bucket: bucket_label, customer_count, pct_of_returning_customers. Only
-- include customers who made at least 2 delivered orders. Time = order_purchase_timestamp of order 2
-- minus order_purchase_timestamp of order 1
-- =====================================================================================================================

-- one row in base cte = one customer unique id

-- Using Filter WHERE days_to_reorder >= 2
-- Excludes same-day/next-day reorders (likely corrections or splits)

WITH ranking AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LEAD(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS next_order_ts,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS rn
    FROM olist_orders o
    JOIN olist_customers c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
    days_calc AS(
        SELECT
            customer_unique_id,
            ROUND(EXTRACT(EPOCH FROM (next_order_ts - order_purchase_timestamp))/86400::NUMERIC, 2) AS days_to_reorder
        FROM ranking
        WHERE rn = 1
            AND next_order_ts IS NOT NULL
    ),
    bucketed AS(
        SELECT
            customer_unique_id,
            CASE
                WHEN days_to_reorder <= 7 THEN '0-7 days'
                WHEN days_to_reorder BETWEEN 8 AND 14 THEN '8-14 days'
                WHEN days_to_reorder BETWEEN 15 AND 30 THEN '15-30 days'
                WHEN days_to_reorder BETWEEN 31 AND 60 THEN '31-60 days'
                WHEN days_to_reorder BETWEEN 61 AND 90 THEN '61-90 days'
                ELSE '90+ days'
            END AS bucket_label,
            days_to_reorder
        FROM days_calc
    )
SELECT
    bucket_label,
    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(COUNT(DISTINCT customer_unique_id) * 100.0 / SUM(COUNT(DISTINCT customer_unique_id)) OVER(),2) AS pct_of_returning_customers
FROM bucketed
WHERE days_to_reorder >= 2
GROUP BY bucket_label
ORDER BY
    CASE bucket_label
        WHEN '0-7 days'   THEN 1
        WHEN '8-14 days'  THEN 2
        WHEN '15-30 days' THEN 3
        WHEN '31-60 days' THEN 4
        WHEN '61-90 days' THEN 5
        ELSE 6
    END;

-- ASSUMPTION DOCUMENTED:
-- days_to_reorder >= 2 applied to exclude same-day reorders
-- These 890 rapid reorders (< 2 days) are likely corrections
-- or system splits — not responses to re-engagement triggers
-- They are excluded to avoid inflating the 0-7 day bucket
-- and misleading campaign timing decisions
--
-- RECOMMENDATION TO STAKEHOLDER:
-- Current campaigns at day 7, 14, and 30 are poorly timed
-- Only 18.45% of genuine returners come back within 30 days
-- Largest segment (50.29%) returns after 90 days
-- Suggested new timing:
--   Email 1: Day 45  (captures 31-60 day segment)
--   Email 2: Day 75  (captures 61-90 day segment)
--   Email 3: Day 120 (nurtures 90+ day segment)