-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX2 - Theme - Logistics
-- Slow seller dispatch is our biggest controllable delay. Dispatch time = days between order_approved_at (payment confirmed)
-- and carrier_delivery_date (seller hands to carrier). For each seller, compute: seller_id, seller_state,
-- avg_dispatch_days, total_orders. Minimum 20 orders per seller. Rank sellers within their state using
-- ROW_NUMBER — rank 1 = slowest dispatch. Flag sellers with avg_dispatch_days > 2 as Slow,
-- otherwise Fast. Show only rank 1 (slowest) per state. Order by avg_dispatch_days descending.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400)::NUMERIC,2) AS avg_dispatch_days,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date > o.order_approved_at
    GROUP BY 1,2
    HAVING COUNT(DISTINCT o.order_id) >= 20
),
    ranking AS(
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY seller_state ORDER BY avg_dispatch_days DESC) AS rank
        FROM seller_base
    )
SELECT
    seller_id,
    seller_state,
    avg_dispatch_days,
    total_orders,
    rank,
    CASE
        WHEN avg_dispatch_days > 2 THEN 'Slow'
        ELSE 'Fast'
    END AS flag
FROM ranking
WHERE rank = 1
ORDER BY rank;

-- ============================================================
-- MX2 FINDINGS: Seller Dispatch Speed Rank by State
-- Dispatch = order_approved_at → order_delivered_carrier_date
-- Filter: >= 20 orders per seller | order_status = 'delivered'
-- Shows: slowest seller (rank 1) per state
-- ============================================================

-- FINDING 1: The 2-day threshold is too strict as a platform benchmark
-- Only 2 of 15 qualifying states have a Fast seller at rank 1
-- PE: 1.70 days | RN: 1.16 days — both barely under 2 days
-- 13 of 15 slowest sellers per state exceed 2 days
-- A threshold that flags 87% of sellers as Slow is not actionable
-- Recommendation: recalibrate benchmark to median dispatch across all sellers
-- Use percentile-based tiers (P25/P50/P75) instead of fixed 2-day cutoff

-- FINDING 2: SP and PR show extreme dispatch delays
-- SP seller: 17.93 days dispatch — worst in dataset
--   Only 30 orders — small seller with critical operational failure
-- PR seller: 16.13 days dispatch — 71 orders — larger scale problem
-- DF seller: 7.67 days — 24 orders
-- These are not marginal misses — 17 days from approval to carrier
-- handoff is a fundamental process breakdown, not inefficiency

-- FINDING 3: MA is the highest-impact slow seller
-- 4.76 avg dispatch days across 370 orders
-- At 4.76 days × 370 orders = 1,761 total delayed dispatch days
-- Compare PE: 1.70 days × 330 orders = 561 total dispatch days
-- MA generates 3x more delay burden despite similar order volume
-- High volume + slow dispatch = largest absolute customer impact
-- Requires immediate contract renegotiation — not just a flag

-- FINDING 4: The problem is structural, not seller-specific
-- 13 of 15 states flagged Slow using the 2-day benchmark
-- This pattern appears across North, South, Southeast, and Northeast
-- No geographic cluster — slow dispatch is platform-wide
-- Separate KPI benchmarking needed:
--   Tier A (Fast): sellers consistently < P25 dispatch days
--   Tier B (Standard): sellers between P25 and P75
--   Tier C (Slow): sellers consistently > P75 dispatch days
-- Benchmarking against peers within the same tier is more
-- actionable than a single fixed threshold for all sellers

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Lars Visser — JET SODA):
-- 1. Replace the 2-day fixed threshold with percentile tiers
--    Current benchmark flags 87% as Slow — not actionable
--    P50 dispatch across all qualifying sellers = true benchmark
-- 2. Prioritise MA seller for immediate intervention
--    370 orders × 4.76 days = largest absolute delay impact
--    Despite PE having similar volume, PE is 3x faster
--    MA contract terms or warehouse location need investigation
-- 3. Escalate SP and PR sellers to platform compliance team
--    17.93 and 16.13 days are operational failures, not delays
--    These sellers should face SLA enforcement or delisting review
-- 4. Investigate PE and RN as best practice benchmarks
--    PE: 330 orders at 1.70 days — high volume, fast dispatch
--    RN: 20 orders at 1.16 days — efficient at minimum threshold
--    What process do these sellers follow that others don't?
-- ============================================================