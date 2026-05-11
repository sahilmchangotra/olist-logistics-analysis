-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX3 - Theme - Logistics
-- Daily Orders + 7-Day Rolling Average by State |  BOL | Product Operations:
-- Our operations team monitors daily order volume to spot demand spikes before they create
-- fulfilment bottlenecks. For the top 5 states by total orders, show: customer_state, order_date (daily),
-- daily_orders, rolling_7d_avg (7-day rolling average of daily orders), and rank each day within its state by
-- daily_orders descending — flag days where daily_orders > rolling_7d_avg as Spike, otherwise Normal.
-- Date range: Jan 2018 to Aug 2018 only. Order by customer_state, order_date.
-- =====================================================================================================================

WITH top_5_states AS(
    SELECT
        c.customer_state
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
    ORDER BY COUNT(DISTINCT o.order_id) DESC
    LIMIT 5
),
    daily AS(
        SELECT
            c.customer_state,
            DATE(o.order_purchase_timestamp) AS order_date,
            COUNT(DISTINCT o.order_id) AS daily_orders
        FROM olist_orders o
        JOIN olist_customers c
            ON o.customer_id = c.customer_id
        WHERE o.order_status = 'delivered'
            AND c.customer_state IN (SELECT customer_state FROM top_5_states)
            AND o.order_purchase_timestamp BETWEEN '2018-01-01' AND '2018-08-31'
        GROUP BY 1,2
    ),
    rolling AS(
        SELECT
            *,
            AVG(daily_orders) OVER (PARTITION BY customer_state ORDER BY order_date
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW ) AS rolling_7d_avg
        FROM daily
    )
SELECT
    customer_state,
    order_date,
    daily_orders,
    ROUND(rolling_7d_avg,2) AS rolling_7d_avg,
    CASE
        WHEN daily_orders > rolling_7d_avg THEN 'Spike'
        ELSE 'Normal'
    END AS flag
FROM rolling
ORDER BY customer_state, order_date;

-- ============================================================
-- MX3 FINDINGS: Daily Orders + 7-Day Rolling Average by State
-- Top 5 states: SP, RJ, MG, RS, PR
-- Date range: 2018-01-01 to 2018-08-31
-- Spike = daily_orders > rolling_7d_avg
-- ============================================================

-- FINDING 1: Spike flag is not comparable across states
-- SP peaks at 178 orders (2018-08-06) — flagged Spike
-- MG peaks at 46 orders (2018-05-14) — also flagged Spike
-- RS peaks at 25 orders (2018-05-01) — also flagged Spike
-- The flag correctly identifies days above each state's own baseline
-- but cannot be used to compare spike severity across states
-- A 46-order day in MG is a genuine operational spike
-- A 46-order day in SP is a quiet Monday
-- Recommendation: add spike_magnitude = daily_orders - rolling_7d_avg
-- to rank spike severity within each state independently

-- FINDING 2: States below 100 daily orders need demand campaigns
-- PR, RS, MG regularly operate below 50 orders per day
-- These states have lower customer penetration than SP and RJ
-- Low volume = higher sensitivity to individual Spike days
-- A single promotional campaign or local event can double daily volume
-- These markets are not saturated — growth through acquisition is viable
-- Targeted regional marketing campaigns needed before assuming
-- logistics investment is justified in these states

-- FINDING 3: Late May volume drop affects rolling avg reliability
-- SP shows a sharp drop from 120+ orders in mid-May
-- to 44-68 orders in late May (2018-05-24 to 2018-05-28)
-- Rolling avg follows this drop downward
-- When orders recover in early June, the depressed rolling avg
-- makes normal days look like Spikes
-- Likely cause: Brazilian public holidays (Corpus Christi falls
-- in late May/early June) creating genuine demand suppression
-- Spike flag during recovery period is unreliable — not real demand surge
-- Hypothesis: late dispatch from SP seller (MX2: 17.93 days)
-- may have contributed to customer hesitation — needs validation
-- against review scores and cancellation data

-- FINDING 4: Rolling average limitation — no seasonality adjustment
-- RS drops to 2 orders on 2018-07-07 then recovers to 14-16 by 07-13
-- The 7-day rolling avg absorbs the low-volume days
-- Making the recovery appear as a Spike when it is just normal demand
-- returning after a brief disruption (likely weekend + holiday effect)
-- The rolling average cannot distinguish between:
--   (a) Genuine demand spikes above trend
--   (b) Recovery from temporary suppression
--   (c) Seasonal patterns (end of month, start of month)
-- A more robust baseline: 4-week same-weekday average
-- e.g. compare Monday to the average of the last 4 Mondays
-- This controls for weekly seasonality that 7-day rolling misses

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Daan — BOL Product Ops):
-- 1. Do not use Spike flag for cross-state comparison
--    Each state's baseline is independent — a Spike in RS
--    is not operationally equivalent to a Spike in SP
--    Add spike_magnitude column for within-state severity ranking
-- 2. Investigate PR, RS, MG for demand growth opportunity
--    Consistently below 50 daily orders — not logistics constrained
--    Demand acquisition campaigns likely to show high ROI
--    These markets are not saturated unlike SP
-- 3. Flag holiday periods before applying Spike detection
--    Brazilian public holidays suppress demand and distort rolling avg
--    Add a holiday calendar table and exclude those days from baseline
--    Or use 4-week same-weekday average instead of 7-day rolling
-- 4. Cross-reference SP late May drop with MX2 dispatch findings
--    SP slowest seller: 17.93 days dispatch (MX2)
--    SP late May volume drop: potential customer trust impact
--    Validate with review scores from olist_order_reviews
--    for orders placed in early-mid May 2018
-- ============================================================