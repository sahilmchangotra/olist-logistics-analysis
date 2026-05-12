-- =====================================================================================================================
-- Introducing - Self-JOINs Practice
-- ✅ SJ5 - Theme - Self-JOIN
-- Category Revenue Gap | BOL | Category Marketing:
-- I need to compare each category's revenue this month to last month using a self-JOIN approach
-- — not LAG. For each category + month (minimum 50 orders per category per month), join to the same
-- category's prior month to get: product_category_name, order_month, monthly_revenue,
-- prev_month_revenue, revenue_gap (absolute difference), gap_pct, and direction: Growing (>5%), Stable
-- (-5% to +5%), Shrinking (<-5%). Show only months where both current AND prior month data exists. This
-- is the self-JOIN equivalent of LAG — understand the difference. Order by order_month, gap_pct descending.
-- =====================================================================================================================

WITH item_cat AS (
    SELECT
        oi.order_id,
        p.product_category_name,
        SUM(oi.price) AS item_revenue
    FROM olist_order_items oi
    JOIN olist_products p
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id, p.product_category_name
),
    monthly_cat AS (
        SELECT
            ic.product_category_name,
            DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
            SUM(ic.item_revenue) AS monthly_revenue
        FROM item_cat ic
        JOIN olist_orders o
            ON o.order_id = ic.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY 1, 2
        HAVING COUNT(DISTINCT o.order_id) >= 50
    )
SELECT
    m1.product_category_name,
    TO_CHAR(m1.order_month,'YYYY-MM') AS order_month,
    ROUND(m1.monthly_revenue,2) AS monthly_revenue,
    ROUND(m2.monthly_revenue,2) AS prev_month_revenue,
    ROUND((m1.monthly_revenue - m2.monthly_revenue)::NUMERIC,2) AS revenue_gap,
    ROUND((m1.monthly_revenue - m2.monthly_revenue) * 100.0 /
          NULLIF(m2.monthly_revenue,0)::NUMERIC,2) AS gap_pct,
    CASE
        WHEN ROUND((m1.monthly_revenue - m2.monthly_revenue) * 100.0 /
          NULLIF(m2.monthly_revenue,0)::NUMERIC,2) > 5 THEN 'Growing'
        WHEN ROUND((m1.monthly_revenue - m2.monthly_revenue) * 100.0 /
          NULLIF(m2.monthly_revenue,0)::NUMERIC,2) BETWEEN -5 AND 5 THEN 'Stable'
        ELSE 'Shrinking'
    END AS direction_flag
FROM monthly_cat m1
JOIN monthly_cat m2
    ON m1.product_category_name = m2.product_category_name
    AND m2.order_month = m1.order_month - INTERVAL '1 month'
ORDER BY m1.order_month, gap_pct DESC;

-- ============================================================
-- SJ5 FINDINGS: Category Revenue Gap — Self-JOIN as LAG
-- Self-JOIN: monthly_cat m1 JOIN m1 ON month - INTERVAL '1 month'
-- INNER JOIN: filters to months where both current + prior exist
-- Fan-out fix: item_cat CTE aggregates order_items first
-- Filter: >= 50 orders per category per month
-- ============================================================

-- FINDING 1: November 2017 is a universal growth event
-- Every single category shows Growing in Nov 2017
-- eletronicos: +195.97% | utilidades_domesticas: +113.25%
-- papelaria: +113.15% | moveis_decoracao: +106.9%
-- beleza_saude: +92.33% | cama_mesa_banho: +91.18%
-- This confirms MX6 finding — November lift is platform-wide
-- not category-specific. No individual category marketing team
-- can claim credit for November growth
-- It is a Black Friday demand event lifting all categories equally

-- FINDING 2: December 2017 shows the sharpest universal decline
-- Every category turns Shrinking or Stable in December
-- telefonia: -51.07% | moveis_decoracao: -49.96%
-- informatica_acessorios: -46.28% | cama_mesa_banho: -43.06%
-- The November spike was borrowing demand from December
-- Customers pulled purchases forward into Black Friday
-- December collapse is the predictable hangover
-- This is the SJ5 equivalent of the MX5 SLA cascade finding

-- FINDING 3: beleza_saude is the most structurally resilient
-- Never posts a catastrophic decline — worst month: -31.64% (Jun 2017)
-- Recovers within 1-2 months in every instance
-- By Aug 2018 it reaches R$119,391 — highest monthly revenue
-- of any category in the dataset
-- Confirms SJ1/MX6/MX7/MX8 findings from four different angles:
-- beleza_saude is the platform's anchor category

-- FINDING 4: Self-JOIN vs LAG — key difference in this dataset
-- LAG would include months where prior month had < 50 orders
-- (below HAVING threshold) and return NULL for those months
-- INNER JOIN on monthly_cat naturally excludes those rows —
-- both months must meet the >= 50 order threshold to appear
-- This makes SJ5 results cleaner than LAG for threshold-filtered data
-- Use self-JOIN when both periods must meet the same quality filter
-- Use LAG when you want to show NULL for missing periods explicitly

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Sophie van Dijk — BOL):
-- 1. November planning must account for December hangover
--    Every year Black Friday pulls demand forward
--    Do not set December targets based on November actuals
--    Use Oct average as the December baseline, not Nov peak
-- 2. beleza_saude is the only category to invest in year-round
--    It grows through promotions AND recovers independently
--    All other top categories are either seasonal or volatile
-- 3. brinquedos structural decline is confirmed
--    Jun -33.11% → Jul -19.31% in 2018 (from MX block)
--    SJ5 shows the same pattern emerged earlier in 2017
--    Post-holiday toy demand collapses every summer
--    This is a structural seasonal category not a growth category
--    Reduce inventory investment in Q2-Q3 for brinquedos
-- ============================================================