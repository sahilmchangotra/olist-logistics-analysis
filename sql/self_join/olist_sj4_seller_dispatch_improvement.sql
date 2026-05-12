-- =====================================================================================================================
-- Introducing - Self-JOINs Practice
-- ✅ SJ4 - Theme - Self-JOIN
--  Seller Dispatch Improvement  | BOL | Product Operations:
-- Our seller improvement programme tracks whether sellers are getting faster at dispatching over
-- time. Dispatch time = days between order_approved_at and order_delivered_carrier_date. For each
-- seller (minimum 10 orders), compare each order's dispatch days to their previous order's dispatch days.
-- Show: seller_id, order_id, order_date, dispatch_days, prev_dispatch_days, improvement_days (positive
-- = faster), and trend: Improving (dispatched faster), Worsening (slower), Same. Only include rows where
-- previous order exists. Order by seller_id, order_date.
-- =====================================================================================================================

WITH seller_base AS (
    SELECT
        s.seller_id,
        o.order_id,
        DATE(o.order_purchase_timestamp)            AS order_date,
        ROUND(EXTRACT(EPOCH FROM
            (o.order_delivered_carrier_date
            - o.order_approved_at))/86400::NUMERIC, 2)
                                                    AS dispatch_days,
        ROW_NUMBER() OVER (
            PARTITION BY s.seller_id
            ORDER BY o.order_purchase_timestamp
        )                                           AS order_rank
    FROM olist_orders o
    JOIN (
        -- Deduplicate: one row per seller per order
        SELECT DISTINCT order_id, seller_id
        FROM olist_order_items
    ) oi ON o.order_id = oi.order_id
    JOIN olist_sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
),
    qualified AS (
        SELECT
            seller_id
        FROM seller_base
        GROUP BY 1
        HAVING COUNT(*) >= 10
    )
SELECT
    o1.seller_id,
    o1.order_id,
    o1.order_date,
    o1.dispatch_days,
    o2.dispatch_days AS prev_dispatch_days,
    ROUND((o2.dispatch_days - o1.dispatch_days)::NUMERIC,2) AS improvement_days,
    CASE
        WHEN o1.dispatch_days < o2.dispatch_days THEN 'Improving'
        WHEN o1.dispatch_days > o2.dispatch_days THEN 'Worsening'
        ELSE 'Same'
    END AS trend_flag
FROM seller_base o1
JOIN seller_base o2
    ON o2.seller_id = o1.seller_id
    AND o2.order_rank = o1.order_rank - 1
WHERE o1.seller_id IN (SELECT seller_id FROM qualified)
ORDER BY o1.seller_id, o1.order_date;

-- ============================================================
-- SJ4 FINDINGS: Seller Dispatch Improvement
-- Self-JOIN: seller_base o1 JOIN o1 ON order_rank - 1
-- Dispatch = order_approved_at → order_delivered_carrier_date
-- Filter: >= 10 delivered orders per seller
-- NOTE: Fix DISTINCT on order_items to remove duplicate rows
-- ============================================================

-- FINDING 1: Dispatch times are highly variable within sellers
-- Seller 001cca7ae9ae17fb1caed9dfb1094831 (ES state):
-- Dispatch ranges from 0.07 days to 5.59 days in the same period
-- Oscillates Improving → Worsening → Improving on consecutive orders
-- No sustained improvement trend visible — dispatch is order-by-order
-- This volatility suggests dispatch speed is driven by product type
-- or order complexity, not seller operational improvement over time

-- FINDING 2: improvement_days = 0 (Same) is common
-- Multiple rows show prev_dispatch = current dispatch exactly
-- This happens when the same dispatch time repeats for different orders
-- Could indicate automated fulfilment processes that dispatch
-- at a fixed time window regardless of order specifics

-- FINDING 3: Self-JOIN on order_rank is the correct pattern here
-- LAG() OVER (PARTITION BY seller ORDER BY date) would give the same result
-- but self-JOIN on order_rank is more explicit about what "previous order"
-- means — it is the immediately prior order by chronological sequence
-- not any arbitrary prior row
-- This is the key SJ4 teaching: self-JOIN on rank vs LAG on date
-- Both valid, self-JOIN clearer when rank matters more than time gap

-- FINDING 4: Fix needed before production use
-- Duplicate rows from multi-item orders inflate the row count
-- and create false "Same" trend flags when the same order_id
-- appears multiple times in the base CTE
-- Add DISTINCT on order_items join before applying ROW_NUMBER

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Daan — BOL Product Ops):
-- 1. Fix the duplicate rows issue first
--    Run the DISTINCT fix and recheck the trend distribution
--    What % of orders are Improving vs Worsening vs Same?
-- 2. Segment sellers by sustained improvement
--    One Improving order means nothing — look for sellers
--    with 3+ consecutive Improving rows
--    These are sellers genuinely optimising their dispatch process
-- 3. Dispatch variability (0.07 to 5.59 days) is the real problem
--    Not the direction of change but the inconsistency
--    A seller who dispatches in 1 day then 5 days then 1 day
--    creates unpredictable customer experience even if the average is fine
--    Add a dispatch_std_dev metric to the seller scorecard
-- ============================================================