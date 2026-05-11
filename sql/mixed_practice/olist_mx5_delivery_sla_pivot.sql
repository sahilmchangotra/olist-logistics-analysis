-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX5 - Theme - Logistics
-- Delivery SLA Breach Pivot — Month x Breach Category | JET SODA Amsterdam | Network Planning:
-- I present a monthly SLA report to the board in pivot format. Categorise each delivered order by
-- how late it was: On Time (delivered on or before estimated), Slightly Late (1-3 days over), Moderately
-- Late (4-7 days over), Very Late (8+ days over). For each month, show a pivot with these 4 categories as
-- columns and the count of orders in each. Also include total_orders and pct_on_time for that month. Order
-- by order_month ascending.
-- =====================================================================================================================

WITH sla_base AS(
    SELECT
        DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))/86400 AS late_days
    FROM olist_orders o
    WHERE o.order_status = 'delivered'
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN late_days <= 0 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN late_days BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS slightly_late,
    SUM(CASE WHEN late_days BETWEEN 4 AND 7 THEN 1 ELSE 0 END) AS moderately_late,
    SUM(CASE WHEN late_days >= 8 THEN 1 ELSE 0 END) AS very_late,
    ROUND(SUM(CASE WHEN late_days <= 0 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*),0),2) AS pct_on_time
FROM sla_base
GROUP BY 1
ORDER BY order_month;

-- ============================================================
-- MX5 FINDINGS: Delivery SLA Breach Pivot
-- Categories: On Time (<=0 days) | Slightly Late (1-3) |
--             Moderately Late (4-7) | Very Late (8+)
-- ============================================================

-- FINDING 1: March 2018 is the worst month on record
-- 78.64% on time — lowest in entire dataset
-- 652 very late orders — highest single month ever
-- Total breach orders: 1,166 (slightly + moderately + very late)
-- Crucially: March 2018 has FEWER total orders than Nov 2017
-- (7,003 vs 7,288) yet produces MORE breach orders (1,166 vs 783)
-- This proves March failure is NOT a volume problem
-- It is a carrier capacity breakdown — the network was already
-- broken before March orders even arrived

-- FINDING 2: November 2017 Black Friday is the root cause
-- Nov 2017: 7,288 orders — largest single month to that point
-- 445 very late, 85.69% on time — first major breach event
-- The holiday surge overwhelmed carrier capacity in November
-- Carriers could not recover — backlog accumulated through Dec/Jan/Feb
-- March 2018 = 3-month consequence of November 2017 promotional event
-- This is a carrier capacity cascade failure, not a routing problem
-- All three breach categories rise together Feb-Mar 2018:
--   Feb: slightly=146, moderately=175, very=486
--   Mar: slightly=235, moderately=279, very=652
-- When all categories rise simultaneously = systemic capacity failure
-- If it were routing, you would see only one category spike

-- FINDING 3: June 2018 recovery is volume-driven not improvement-driven
-- Jun 2018: 98.64% on time — best month in 2018
-- very_late drops to just 37 orders
-- Corpus Christi holiday (late May/early June) suppresses demand
-- Fewer orders = carrier capacity buffer restored
-- Not a genuine logistics improvement — confirmed by Aug 2018:
-- Aug 2018: 89.61% on time, very_late=57 — rate deteriorates again
-- when demand returns to normal levels post-holiday
-- The platform has not solved the carrier capacity problem
-- it has only benefited temporarily from reduced demand

-- FINDING 4: Very late orders are the most damaging breach category
-- Very late (8+ days) accounts for the majority of all breach orders
-- Nov 2017: very_late=445 out of total_breach=783 = 56.8%
-- Mar 2018: very_late=652 out of total_breach=1,166 = 55.9%
-- Customers waiting 8+ days beyond estimated delivery
-- are the highest churn risk and most likely to leave 1-star reviews
-- Cross-reference with olist_order_reviews for very_late orders
-- to quantify the review score impact of carrier breakdown

-- FINDING 5: The platform shows a two-speed pattern
-- Normal months (May-Oct 2017): consistently 94-97% on time
-- Shock months (Nov 2017, Feb-Mar 2018): 78-85% on time
-- Recovery months (Jun 2018): 98% on time (suppressed demand)
-- The platform has no buffer — one demand event breaks the system
-- Normal capacity headroom is too thin for promotional surges

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Emma Clarke — JET SODA):
-- 1. Pre-position carrier capacity before Black Friday
--    Nov 2017 cascade lasted 4 months into Mar 2018
--    Contract surge capacity with carriers in October
--    before the November spike hits — not reactively after
-- 2. Add a very_late SLA alert in operations dashboard
--    When very_late > 100 orders in a month → automatic escalation
--    Nov 2017 hit 445 — no early warning system existed
--    Threshold trigger would have flagged November immediately
-- 3. Do not report June as performance improvement
--    98.64% on time in June is a holiday suppression effect
--    Board presentations should exclude holiday-impacted months
--    Use May and July as the true performance baseline months
-- 4. Cross-reference very_late orders with review scores
--    652 very late orders in March 2018 likely drove 1-star reviews
--    Quantify: what is the average review score for very_late orders?
--    This connects MX5 logistics findings to revenue impact
-- ============================================================