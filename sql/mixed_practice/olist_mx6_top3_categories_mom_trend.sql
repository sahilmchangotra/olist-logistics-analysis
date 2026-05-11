-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX6 - Theme - Marketing
--  Top 3 Revenue Categories per Month with MoM Trend Flag | BOL | Category Marketing:
-- I track which categories are driving revenue each month. For the top 3 revenue categories in each
-- month, show: order_month, product_category_name, monthly_revenue, rank_in_month (DENSE_RANK
-- — 1 = highest revenue), prev_month_revenue (LAG), mom_change_pct, and trend_label: Growing
-- (>5%), Stable (-5% to +5%), Declining (<-5%). Use SUM(oi.price) as revenue — fan-out fix required.
-- Minimum 100 orders per category per month. Order by order_month, rank_in_month.
-- =====================================================================================================================

WITH item_cat AS(
    SELECT
        oi.order_id,
        p.product_category_name,
        SUM(oi.price) AS item_revenue
    FROM olist_order_items oi
    JOIN olist_products p
        ON oi.product_id = p.product_id
    GROUP BY 1,2
),
    monthly AS(
        SELECT
            DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
            ic.product_category_name,
            SUM(ic.item_revenue) AS monthly_revenue,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM olist_orders o
        JOIN item_cat ic
            ON o.order_id = ic.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY 1,2
        HAVING COUNT(DISTINCT o.order_id) >= 100
    ),
    ranking AS (
        SELECT
            *,
            DENSE_RANK() OVER (PARTITION BY order_month ORDER BY monthly_revenue DESC) AS rank_in_month
        FROM monthly
    ),
    prev_revenue AS(
        SELECT
           *,
           LAG(monthly_revenue) OVER (PARTITION BY product_category_name ORDER BY order_month) AS prev_month_revenue
        FROM ranking
    )
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    COALESCE(product_category_name,'Unknown') AS product_category_name,
    prev_month_revenue,
    monthly_revenue,
    rank_in_month,
    ROUND((monthly_revenue - prev_month_revenue) * 100.0 /
          NULLIF(prev_month_revenue,0),2) AS mom_change_pct,
    CASE
        WHEN prev_month_revenue IS NULL THEN 'No Prior Data'
        WHEN ROUND((monthly_revenue - prev_month_revenue) * 100.0 /
          NULLIF(prev_month_revenue,0),2) > 5 THEN 'Growing'
        WHEN ROUND((monthly_revenue - prev_month_revenue) * 100.0 /
          NULLIF(prev_month_revenue,0),2) BETWEEN -5 AND 5 THEN 'Stable'
        ELSE 'Declining'
    END AS flag
FROM prev_revenue
WHERE rank_in_month <= 3
ORDER BY order_month, rank_in_month;

-- ============================================================
-- MX6 FINDINGS: Top 3 Revenue Categories per Month with MoM Trend
-- Fan-out fix: item_cat CTE aggregates order_items first
-- Filter: >= 100 orders per category per month
-- ============================================================

-- FINDING 1: beleza_saude is the most structurally reliable category
-- Appears in top 3 in 15 of 20 months — consistent demand driver
-- Never collapses below top 3 for more than one consecutive month
-- This is a needs-based category (hygiene/health) — not event-driven
-- Customers repurchase regardless of season or promotional calendar
-- Contrast with relogios_presentes (watches/gifts) which swings
-- between rank 1 and absent based purely on gift-giving occasions
-- beleza_saude = the platform's most dependable revenue pillar
-- Recommendation: use as anchor category for marketing spend baseline

-- FINDING 2: November 2017 growth is platform-wide, not category-specific
-- relogios_presentes: +46.89% | cama_mesa_banho: +91.18%
-- beleza_saude: +92.33% — all three in top 3 simultaneously
-- Growth of 46-92% across completely different categories
-- in the same month confirms this is a demand event, not category trend
-- Black Friday promotional surge lifted all categories equally
-- This matters for marketing attribution — no single category
-- should claim credit for November revenue growth
-- The lift was platform-level, not driven by category campaigns

-- FINDING 3: NULL mom_change_pct rows are incorrectly flagged Declining
-- moveis_decoracao (2017-01), esporte_lazer (2017-02),
-- informatica_acessorios (2017-03) all show NULL and flag Declining
-- These are first appearances in top 3 — no prior month to compare
-- NULL falling to ELSE in CASE WHEN gives misleading Declining label
-- Fix: add WHEN prev_month_revenue IS NULL THEN 'No Prior Data'
-- as the first condition in CASE WHEN before all other checks
-- Without this fix, any board report using this flag would show
-- new category entrants as declining — factually incorrect

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Sophie van Dijk — BOL):
-- 1. Protect beleza_saude marketing budget year-round
--    It is the only category with consistent top-3 presence
--    Cutting its budget in Q1 (post-holiday) risks losing
--    the platform's most reliable non-seasonal revenue driver
-- 2. Do not attribute November revenue spikes to category campaigns
--    All categories grew 46-92% simultaneously in Nov 2017
--    This is Black Friday platform effect — not category marketing
--    Separate promotional lift analysis from organic category growth
-- 3. Fix the NULL flag before presenting to board
--    Incorrect Declining labels on new category entrants will be
--    challenged immediately in any executive review
-- ============================================================