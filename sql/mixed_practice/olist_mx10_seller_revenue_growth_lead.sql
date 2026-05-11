-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX10 - Theme - Marketing
--  Seller Revenue Growth | BOL | Performance Marketing:
-- I want to identify which sellers are accelerating vs decelerating in revenue month over month. For
-- the top 20 sellers by total revenue, show their last 3 months (Jun, Jul, Aug 2018): seller_id, seller_state,
-- order_month, monthly_revenue, next_month_revenue (LEAD), revenue_change_pct, and trend:
-- Accelerating (>10% growth), Stable (-10% to +10%), Decelerating (<-10% decline). Use SUM(oi.price) as
-- revenue. Fan-out fix required. Minimum 10 orders per seller per month. Order by seller_id, order_month.
-- =====================================================================================================================

WITH item_seller AS(
    SELECT
        oi.seller_id,
        oi.order_id,
        SUM(oi.price) AS item_revenue
    FROM olist_order_items oi
    GROUP BY oi.seller_id, oi.order_id
),
    monthly AS (
        SELECT
            is2.seller_id,
            s.seller_state,
            DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
            SUM(is2.item_revenue) AS monthly_revenue,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM olist_orders o
        JOIN item_seller is2
            ON o.order_id = is2.order_id
        JOIN olist_sellers s
            ON is2.seller_id = s.seller_id
        WHERE o.order_status = 'delivered'
        GROUP BY 1, 2, 3
        HAVING COUNT(DISTINCT o.order_id) >= 10
    ),
    top_20 AS (
        SELECT
            seller_id
        FROM monthly
        GROUP BY 1
        ORDER BY SUM(monthly_revenue) DESC LIMIT 20
    ),
    lead_calc AS (
        SELECT
            *,
            LEAD(monthly_revenue) OVER (
                PARTITION BY seller_id
                ORDER BY order_month
                ) AS next_month_revenue
        FROM monthly
        WHERE seller_id IN (SELECT seller_id FROM top_20)
    )
SELECT
    seller_id,
    seller_state,
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    ROUND(monthly_revenue,2) AS monthly_revenue,
    ROUND(next_month_revenue,2) AS next_month_revenue,
    ROUND((next_month_revenue - monthly_revenue) * 100.0 /
          NULLIF(monthly_revenue,0),2) AS revenue_change_pct,
    CASE
        WHEN ROUND((next_month_revenue - monthly_revenue) * 100.0 /
            NULLIF(monthly_revenue,0),2) > 10 THEN 'Accelerating'
        WHEN ROUND((next_month_revenue - monthly_revenue) * 100.0 /
          NULLIF(monthly_revenue,0),2) < - 10 THEN 'Decelerating'
        ELSE 'Stable'
    END AS trend_flag
FROM lead_calc
WHERE TO_CHAR(order_month,'YYYY-MM') IN ('2018-06','2018-07','2018-08')
ORDER BY seller_id, order_month;

-- ============================================================
-- MX10 FINDINGS: Seller Revenue Growth — LEAD for MoM Change
-- Top 20 sellers by total revenue | Jun-Aug 2018
-- Trend: Accelerating (>10%) | Stable (-10% to +10%) | Decelerating (<-10%)
-- NOTE: Aug 2018 trend_flag unreliable — LEAD returns NULL (no Sep data)
-- ============================================================

-- FINDING 1: Consecutive decelerating sellers signal post-holiday impact
-- da8622b (SP): Jun -22.88% → Jul -28.45% — two consecutive months
-- cc419e0 (SP): Jun -11.99% → Jul -15.27% — accelerating decline
-- a1043ba (MG): Jun -43.23% → Jul -19.29% — slowing but still falling
-- A single Decelerating month could be noise or seasonal variation
-- Two consecutive Decelerating months indicates structural revenue loss
-- not a temporary dip — the seller's customer base is shrinking
-- Pattern consistent across multiple sellers in Jun-Jul 2018
-- confirms this is a platform-wide post-holiday demand correction
-- not seller-specific operational failure
-- Recommendation: flag any seller with 2+ consecutive Decelerating
-- months for account management review — proactive intervention
-- before they exit the platform entirely

-- FINDING 2: Volatile sellers (4869f7a) show holiday recovery pattern
-- Jun 2018: R$15,769 → Jul: R$8,280 (-47.49%) Decelerating
-- Jul 2018: R$8,280  → Aug: R$14,429 (+74.26%) Accelerating
-- -47% then +74% in consecutive months — not genuine volatility
-- This is the same rolling average distortion pattern from MX3/MX4
-- Post-holiday demand suppression in June collapses the baseline
-- July recovery looks like a spike because June was artificially low
-- The seller's underlying business has not changed — the seasonal
-- pattern creates an artificial boom-bust signal in the data
-- Recommendation: do not penalise or reward sellers based on
-- single-month swings during holiday transition periods (May-Jul)
-- Use 3-month rolling average revenue as the seller performance baseline

-- FINDING 3: SP concentration creates platform-wide dependency risk
-- 15 of 20 top sellers are in SP — 75% geographic concentration
-- In March 2018 SP had 22.97% late delivery rate (MX4 finding)
-- 1,186 late orders in one month from SP alone
-- If a carrier disruption, natural disaster or regulatory event
-- hits SP simultaneously — 75% of top seller revenue is at risk
-- This is not smaller state risk — it is platform concentration risk
-- The platform's highest revenue generators are all co-located
-- in one state with known delivery infrastructure problems
-- seller 46dc3b2cc (RJ) disappears after June — potential churn
-- 3 RJ sellers in top 20 — RJ had 34.56% late rate in MX4
-- Both high-concentration states have proven delivery problems

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Noor Bakker — BOL Performance):
-- 1. Flag sellers with 2+ consecutive Decelerating months
--    da8622b, cc419e0, a1043ba all qualify for account review
--    These sellers need category expansion or pricing strategy support
--    before they drop below the top 20 threshold entirely
-- 2. Use 3-month rolling average for seller performance review
--    Single-month trend flags during May-Jul are unreliable
--    Holiday suppression creates false Decelerating signals in June
--    and false Accelerating signals in July/August recovery
--    Stable performance is better assessed over 90-day windows
-- 3. Diversify top seller geographic base away from SP concentration
--    Actively recruit top sellers in MG, RS, PR, SC
--    Currently only 2 of 20 top sellers are outside SP and RJ
--    A single SP logistics event can simultaneously impact
--    R$100,000+ in monthly revenue from 15 sellers at once
--    Geographic diversification of seller base = platform resilience
-- ============================================================