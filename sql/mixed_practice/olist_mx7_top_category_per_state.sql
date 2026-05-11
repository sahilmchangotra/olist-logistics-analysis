-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX7 - Theme - Marketing
--   PARTITION BY 2 Columns: Category + State Revenue Rank | BOL | Performance Marketing:
-- Our regional marketing team needs to know which product categories generate the most revenue
-- in each customer state. For each customer_state + product_category_name combination (minimum 50
-- orders), compute total_revenue and order_count. Then rank categories within each state: RANK()
-- PARTITION BY customer_state ORDER BY total_revenue DESC. Show only rank 1 per state (top
-- category per state). Also show the revenue share that category holds within its state (category_revenue /
-- state_total_revenue * 100). Order by total_revenue descending.
-- =====================================================================================================================

WITH item_cat AS(
    SELECT
        oi.order_id,
        p.product_category_name,
        SUM(oi.price) AS item_revenue
    FROM olist_order_items oi
    JOIN olist_products p
        ON p.product_id = oi.product_id
    GROUP BY 1,2
),
    state_cat AS (
        SELECT
            c.customer_state,
            ic.product_category_name,
            SUM(ic.item_revenue) AS total_revenue,
            COUNT(DISTINCT o.order_id) AS order_count,
            SUM(SUM(ic.item_revenue)) OVER (PARTITION BY c.customer_state) AS state_total
        FROM olist_orders o
        JOIN olist_customers c
            ON o.customer_id = c.customer_id
        JOIN item_cat ic
            ON o.order_id = ic.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY 1,2
        HAVING COUNT(DISTINCT o.order_id) >= 50
    ),
    ranked AS (
        SELECT
            *,
            RANK() OVER (PARTITION BY customer_state ORDER BY total_revenue DESC) AS state_rank
        FROM state_cat
    )
SELECT
    customer_state,
    COALESCE(product_category_name,'Unknown') AS product_category_name,
    total_revenue,
    order_count,
    state_rank,
    ROUND(total_revenue * 100.0 / NULLIF(state_total,0),2) AS category_revenue_share_pct
FROM ranked
WHERE state_rank = 1
ORDER BY total_revenue DESC;

-- ============================================================
-- MX7 FINDINGS: Top Category per State — Revenue Rank + Share
-- RANK() PARTITION BY customer_state ORDER BY total_revenue DESC
-- Filter: >= 50 orders per state-category combination
-- ============================================================

-- FINDING 1: Four states show 100% revenue concentration — data limitation
-- PB, RN, AL, PI all show beleza_saude at 100% revenue share
-- Root cause: HAVING >= 50 filters out all other categories
-- in these states — only beleza_saude meets the minimum threshold
-- state_total = beleza_saude revenue only → 100% share by definition
-- This is not a genuine finding — it is a filter artefact
-- Fix: lower HAVING to >= 20 for smaller states OR
-- add a state_total_orders filter to exclude states with thin data
-- These 4 states have 50-75 qualifying orders total — too thin
-- for reliable category concentration analysis

-- FINDING 2: beleza_saude dominates 12 of 20 states — structural need
-- Leads in MG, BA, PE, CE, PA, PB, MT, RN, AL, MA, MS, PI
-- Health and hygiene is a needs-based, non-seasonal category
-- Customers repurchase regardless of income level or geography
-- This breadth of dominance (12 states, all sizes) confirms
-- beleza_saude is the platform's most universal demand driver
-- Single category concentration risk applies at platform level:
-- if a regulatory change, supplier issue or competitor enters
-- beleza_saude, 12 states simultaneously lose their top revenue driver
-- Recommendation: diversify category investment in these 12 states
-- to reduce structural dependency on one category

-- FINDING 3: Revenue concentration decreases as market size grows
-- Small states (PE: 22.99%, CE: 23.79%, PA: 27.45%) show high
-- concentration — top category holds nearly 1 in 4 revenue dollars
-- Large states (SP: 9.44%, RS: 9.60%) show lower concentration
-- Top category holds less than 1 in 10 revenue dollars
-- Pattern: as customer base grows, purchasing diversifies naturally
-- SP and RS have more categories qualifying at >= 50 orders
-- giving customers more options and spreading revenue across categories
-- Small states are not yet diversified — single category risk is real
-- Implication for marketing: small states need category expansion
-- campaigns to reduce concentration before a competitor targets
-- the dominant category specifically

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Noor Bakker — BOL Performance):
-- 1. Fix the 100% concentration artefact before board presentation
--    PB, RN, AL, PI results are filter artefacts not real findings
--    Lower HAVING to >= 20 or add minimum state volume threshold
-- 2. Treat beleza_saude dominance as a platform risk, not just success
--    12 states dependent on one category = concentrated revenue base
--    Invest in second-category development in BA, CE, PE, MA
--    Target cama_mesa_banho or esporte_lazer as growth categories
-- 3. Use SP and RS as the diversification benchmark
--    9.44% and 9.60% top-category concentration is healthy
--    Set a target: no state should have >20% in a single category
--    Current offenders: PA (27.45%), MT (27.84%), MS (31.36%)
-- ============================================================