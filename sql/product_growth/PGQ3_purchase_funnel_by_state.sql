-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ3 - Purchase Funnel by State | BOL | Product Ops:
-- We want to understand regional conversion differences. For the top 10 states by total orders, I
-- want a simple 3-stage funnel: Stage 1 = orders placed (all statuses), Stage 2 = orders approved
-- (order_approved_at IS NOT NULL), Stage 3 = orders delivered (order_status = delivered). For each state
-- show: customer_state, stage1_orders, stage2_orders, stage3_orders, stage1_to_2_pct (approval rate),
-- stage2_to_3_pct (delivery conversion), overall_conversion_pct (stage3/stage1). Order by stage1_orders
-- descending, limit to top 10 states.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS stage1_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_approved_at IS NOT NULL) As stage2_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_status = 'delivered') AS stage3_orders
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
    )
SELECT
    customer_state,
    stage1_orders,
    stage2_orders,
    stage3_orders,
    ROUND((stage2_orders) * 100.0 / NULLIF(stage1_orders,0),2) AS stage1_to_2_pct,
    ROUND((stage3_orders) * 100.0 / NULLIF(stage2_orders,0),2) AS stage2_to_3_pct,
    ROUND((stage3_orders) * 100.0 / NULLIF(stage1_orders,0),2) AS overall_conversion_pct
FROM order_base
ORDER BY stage1_orders DESC
LIMIT 10;


-- ============================================================
-- PGQ3 FINDINGS: Purchase Funnel by State (Top 10)
-- No base filter — all statuses needed for Stage 1
-- ============================================================

-- FINDING 1: Stage 1 → Stage 2 (Approval rate) is near-perfect
-- All 10 states show 99.81–99.94% approval rate
-- Orders are almost universally approved once placed
-- This stage is not a bottleneck — no action needed here

-- FINDING 2: Stage 2 → Stage 3 (Delivery conversion) is where
-- drop-off happens — range is 96–98% across states
-- ES (Espírito Santo) leads at 98% delivery conversion
-- RJ (Rio de Janeiro) and BA (Bahia) lowest at 96%
-- 4% of approved orders in RJ/BA never reach delivered status

-- FINDING 3: Overall conversion range is narrow — 96.09% to 98.13%
-- No state has a catastrophically broken funnel
-- But at SP scale (41,746 orders) even 2.98% loss =
-- ~1,244 orders never delivered — significant in absolute terms

-- FINDING 4: SP dominates by volume — 41,746 orders
-- 3.4x larger than RJ (12,852) — São Paulo is the core market
-- SP overall conversion: 97.02% — slightly below ES benchmark
-- Fixing SP by 1pp = ~417 additional delivered orders

-- FINDING 5: No state shows a Stage 1→2 problem
-- The funnel leaks entirely at Stage 2→3 (delivery)
-- This points to logistics/carrier issues, not platform issues
-- Approval infrastructure is working — last-mile delivery is not

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Daan — BOL Product Ops):
-- 1. Delivery conversion is the only lever worth pulling
--    Stage 1→2 is near-perfect across all states — ignore it
-- 2. Prioritise SP and RJ for last-mile investigation
--    SP: largest absolute loss (~1,244 undelivered)
--    RJ: lowest conversion rate (96.09%) — structural issue?
-- 3. Use ES (98.13%) as the delivery benchmark
--    What does Espírito Santo's carrier network do differently?
--    Apply that model to SP and RJ first
-- 4. Cross-reference with late delivery data (DataCo pattern)
--    Are the 4% undelivered orders cancelled, lost, or returned?
--    ORDER BY stage2 - stage3 DESC to find worst absolute gaps
-- ============================================================