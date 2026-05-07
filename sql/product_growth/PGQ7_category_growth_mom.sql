-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ7 - Product Category Growth | Myntra | BOL | Category Marketing:
--  I manage category performance. I need to see which product categories are gaining momentum
-- and which are losing it. For the top 10 categories by total revenue, show their last 3 months of data (Jun,
-- Jul, Aug 2018) and compute: category_name, month, monthly_revenue, mom_revenue_change_pct, and
-- a trend label: Growing (>5% MoM), Stable (-5% to +5%), Declining (<-5%). Use product_category_name
-- from olist_products. Fan-out fix required — aggregate items before joining payments.
-- =====================================================================================================================

WITH item_cat AS (
    SELECT
        oi.order_id,
        COALESCE(p.product_category_name,'Unknown') AS product_category_name,
        SUM(oi.price) AS item_revenue
    FROM olist_order_items oi
    JOIN olist_products p
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id, p.product_category_name
),
    monthly_cat AS(
        SELECT
            DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
            ic.product_category_name,
            SUM(ic.item_revenue) AS monthly_revenue
        FROM olist_orders o
        JOIN item_cat ic
            ON o.order_id = ic.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY 1,2
    ),
    top_10 AS(
        SELECT
            product_category_name
        FROM monthly_cat
        GROUP BY 1
        ORDER BY SUM(monthly_revenue) DESC
        LIMIT 10
    ),
    mom AS(
        SELECT
            *,
            LAG(monthly_revenue) OVER (
                PARTITION BY product_category_name
                ORDER BY order_month
                ) AS prev_revenue
        FROM monthly_cat
        WHERE product_category_name IN (SELECT product_category_name FROM top_10)
    )
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    product_category_name,
    ROUND(monthly_revenue,2) AS monthly_revenue,
    ROUND((monthly_revenue - prev_revenue) * 100.0 / NULLIF(prev_revenue,0),2) AS mom_revenue_change_pct,
    CASE
        WHEN (monthly_revenue - prev_revenue) * 100.0 /
             NULLIF(prev_revenue,0) > 5 THEN 'Growing'
        WHEN (monthly_revenue - prev_revenue) * 100.0 /
             NULLIF(prev_revenue,0) < - 5 THEN 'Declining'
        ELSE 'Stable'
    END AS trend_label
FROM mom
WHERE TO_CHAR(order_month, 'YYYY-MM') IN ('2018-06','2018-07','2018-08')
ORDER BY product_category_name, order_month;

-- ============================================================
-- PGQ7 FINDINGS: Category Growth MoM — Jun/Jul/Aug 2018
-- Top 10 categories by total revenue | is_price_outlier N/A
-- Fan-out fix: item_cat CTE aggregates order_items first
-- ============================================================

-- FINDING 1: Only ONE category shows consistent growth
-- beleza_saude (Health & Beauty):
--   Jun: +12.92% Growing
--   Jul: -3.02%  Stable
--   Aug: +15.33% Growing
-- Most resilient category in the top 10 — two strong growth months
-- Only category that did not post a Declining month in this window

-- FINDING 2: brinquedos (Toys) is in structural decline
-- Jun: -33.11% Declining
-- Jul: -19.31% Declining
-- Aug: -0.58%  Stable (barely)
-- Three consecutive months of heavy negative momentum
-- -33% and -19% are not noise — this is a demand collapse
-- Likely seasonal (toys peak in Nov/Dec — this is post-season)

-- FINDING 3: relogios_presentes (Watches & Gifts) most volatile
-- Jun: -28.77% Declining
-- Jul: +11.92% Growing
-- Aug: -26.69% Declining
-- Wild swings of ±28% month to month — extremely unstable
-- Gift categories are event-driven — hard to forecast
-- Not a reliable revenue base for planning

-- FINDING 4: No category shows 3 consecutive Growing months
-- Even the best performer (beleza_saude) had a Stable month
-- The Q3 2018 market is broadly flat-to-declining
-- Matches PGQ1 MAU plateau (6,000–7,000 MAU stable in 2018)
-- Revenue plateau mirrors the user growth plateau

-- FINDING 5: cool_stuff and moveis_decoracao show whipsaw pattern
-- cool_stuff:      Declining → Growing → Declining
-- moveis_decoracao: Declining → Growing → Declining
-- Both reverse sharply each month — demand is inconsistent
-- These categories likely have high promotional sensitivity
-- Revenue spikes when discounted, collapses when not

-- FINDING 6: informatica_acessorios (Computers & Accessories)
-- Most stable category in absolute terms
-- Jun: -17.43% Declining (single bad month)
-- Jul: -1.78%  Stable
-- Aug: -2.46%  Stable
-- Stabilised after June drop — consistent demand floor
-- Lower volatility than gift/toy categories

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Sophie van Dijk — BOL Category):
-- 1. Invest in beleza_saude — only category with sustained
--    growth in a broadly declining Q3 market
--    Increase inventory + marketing spend for this category
-- 2. Flag brinquedos for seasonal budget reallocation
--    -33% and -19% in consecutive months is post-season collapse
--    Pull spend in Q3, reinvest in Q4 (Nov/Dec peak)
-- 3. Stabilise relogios_presentes promotional calendar
--    ±28% swings suggest unplanned discounting is driving
--    boom-bust cycles — smooth out with planned promotions
-- 4. Monitor cool_stuff and moveis_decoracao for 3 months
--    Whipsaw pattern needs longer window to confirm trend
--    Do not make investment decisions on 3-month volatile data
-- 5. Q3 2018 is broadly a plateau market
--    Cross-reference with PGQ1 (MAU plateau) and PGQ2
--    (stable ARPU) — platform-wide growth has stalled,
--    category mix optimisation is the lever, not acquisition
-- ============================================================