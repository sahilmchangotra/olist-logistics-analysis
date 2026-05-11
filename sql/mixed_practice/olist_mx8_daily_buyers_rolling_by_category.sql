-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX8 - Theme - Marketing
-- Monthly Active Buyers per Category + 7-Day Rolling | BOL | Category Marketing:
-- I need to track daily buyer activity per product category to identify demand spikes before they
-- become inventory problems. For the top 5 categories by total orders, show: product_category_name,
-- order_date (daily), daily_buyers (unique customers who bought that category on that day),
-- rolling_7d_avg_buyers (7-day rolling average of daily_buyers partitioned by category). Flag days where
-- daily_buyers > rolling_7d_avg_buyers as Spike. Date range: 2018-01-01 to 2018-08-31. Order by
-- product_category_name, order_date.
-- =====================================================================================================================

WITH top_5_cat AS(
    SELECT
        p.product_category_name
    FROM olist_order_items oi
    JOIN olist_products p
        ON oi.product_id = p.product_id
    GROUP BY 1
    ORDER BY COUNT(DISTINCT oi.order_id) DESC
    LIMIT 5
),
    daily AS (
        SELECT
            p.product_category_name,
            DATE(o.order_purchase_timestamp) AS order_date,
            COUNT(DISTINCT c.customer_unique_id) AS daily_buyers
        FROM olist_orders o
        JOIN olist_customers c
            ON o.customer_id = c.customer_id
        JOIN olist_order_items oi
            ON o.order_id = oi.order_id
        JOIN olist_products p
            ON oi.product_id = p.product_id
        WHERE o.order_status = 'delivered'
            AND p.product_category_name IN (SELECT product_category_name FROM top_5_cat)
            AND o.order_purchase_timestamp BETWEEN '2018-01-01' AND '2018-08-31'
        GROUP BY 1, 2
    ),
    rolling AS (
        SELECT
            *,
            AVG(daily_buyers) OVER (PARTITION BY product_category_name
                ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW ) AS rolling_7d_avg
        FROM daily
    )
SELECT
    COALESCE(product_category_name,'Unknown') AS product_category_name,
    order_date,
    daily_buyers,
    ROUND(rolling_7d_avg,2) AS rolling_7d_avg,
    CASE
        WHEN daily_buyers > rolling_7d_avg THEN 'Spike'
        ELSE 'Normal'
    END AS flag
FROM rolling
ORDER BY product_category_name, order_date;

-- ============================================================
-- MX8 FINDINGS: Daily Active Buyers per Category + 7-Day Rolling
-- Top 5 categories by order count
-- Date range: 2018-01-01 to 2018-08-31
-- Spike = daily_buyers > rolling_7d_avg
-- ============================================================

-- FINDING 1: Need-driven vs discretionary categories recover differently
-- beleza_saude (health/hygiene): drops in late May, recovers fully by June
--   2018-05-24: 12 buyers → 2018-06-08: 35 buyers (192% recovery)
-- informatica_acessorios (computer accessories): drops late May
--   2018-05-24: 1 buyer → Jun 2018 averages only 10-18 buyers
--   Recovery is slow and fragmented — never returns to Jan-Mar peak
-- Health/hygiene is need-driven — customers return as soon as the
-- purchase trigger (product runs out) occurs regardless of season
-- Computer accessories are discretionary — customers delay purchase
-- when uncertain, resulting in a slower, uneven recovery
-- Implication: beleza_saude inventory can be restocked confidently
-- after a dip. Informatica restocking needs demand signal first

-- FINDING 2: Rolling average limitation is confirmed in cama_mesa_banho
-- Mid-July dip: cama_mesa_banho drops to 6-7 buyers (July 7-12)
-- Rolling avg follows down to ~7-8 over those days
-- Recovery to 34 buyers (July 18) flags as Spike
-- But 34 buyers is not exceptional — it is the normal Jan-Jun level
-- The Spike flag is triggered by the depressed rolling avg
-- not by genuinely abnormal demand
-- Same pattern observed in MX3 (RS state) and MX5 (June recovery)
-- This is a structural limitation of 7-day rolling avg:
-- It cannot distinguish between genuine spikes and
-- recovery from temporary suppression
-- Fix: use 4-week same-weekday average as baseline
-- or flag rolling avg standard deviation as the threshold
-- instead of a simple greater-than comparison

-- FINDING 3: moveis_decoracao confirms durable goods low-frequency pattern
-- Peak daily buyers: 30 (2018-05-16) — lowest peak of all 5 categories
-- beleza_saude peak: 45 buyers | esporte_lazer peak: 32 buyers
-- moveis_decoracao consistently operates at 5-25 buyers per day
-- Furniture and decoration are durable goods — customers buy once
-- and do not return for 90-180 days minimum
-- This connects directly to PGQ5 and PGQ9 findings:
-- 99% monthly churn + 50% of returners take 90+ days
-- moveis_decoracao buyers are exactly those 90+ day returners
-- Low daily volume is not underperformance — it is the expected
-- purchase frequency for this category
-- Do not apply the same spike detection thresholds to moveis_decoracao
-- as to beleza_saude — the baseline purchase frequency is fundamentally
-- different and requires category-specific benchmarks

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Sophie van Dijk — BOL):
-- 1. Segment spike detection by purchase frequency type
--    Need-driven (beleza_saude): 7-day rolling is appropriate
--    Discretionary (informatica): use 14-day rolling for smoother baseline
--    Durable goods (moveis_decoracao, cama_mesa_banho): use 30-day rolling
--    One rolling window for all categories produces misleading flags
-- 2. beleza_saude inventory restocking is safe after dips
--    Need-driven recovery is predictable and fast
--    Stock up 2 weeks after any volume drop — recovery is reliable
-- 3. Informatica recovery is slow — do not over-invest post-dip
--    Late May collapse: 1 buyer on May 24
--    Never returned to Jan-Feb peak of 35-41 buyers/day
--    Indicates structural demand softening not just holiday effect
--    Investigate whether competitor activity or price sensitivity
--    is causing the sustained lower volume
-- ============================================================