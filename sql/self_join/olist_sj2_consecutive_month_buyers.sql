-- =====================================================================================================================
-- Introducing - Self-JOINs Practice
-- ✅ SJ2 - Theme - Self-JOIN
-- Consecutive Month Buyers | Myntra | Growth & Retention:
-- I need to identify customers who show genuine repeat purchase behaviour — specifically those
-- who placed at least one order in two consecutive calendar months. Not just any two months — they must
-- be back-to-back (e.g. Jan then Feb, not Jan then March). Show: customer_unique_id, first_month,
-- second_month, days_between_orders (between first order of month 1 and first order of month 2), and
-- label them as Consecutive Buyers. Order by days_between_orders ascending — shortest gap first."
-- =====================================================================================================================

WITH cust_month AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS first_month,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1, 2
)
SELECT
    c1.customer_unique_id,
    TO_CHAR(c1.first_month,'YYYY-MM') AS first_month,
    TO_CHAR(c2.first_month,'YYYY-MM') AS second_month,
    DATE(c2.first_order_date) - DATE(c1.first_order_date) AS days_between_orders,
    'Consecutive Buyer' AS label
FROM first_month c1
JOIN first_month c2
    ON c1.customer_unique_id = c2.customer_unique_id
    AND c2.first_month = c1.first_month + INTERVAL '1 month'
ORDER BY days_between_orders ASC;

-- ============================================================
-- SJ2 FINDINGS: Consecutive Month Buyers
-- Self-JOIN: cust_month c1 JOIN c1 ON month + INTERVAL '1 month'
-- Definition: ordered in month M AND month M+1
-- Total consecutive buyers found: ~370 customers
-- ============================================================

-- FINDING 1: Consecutive buyers are extremely rare — confirms PGQ5
-- Total consecutive buyer pairs found: ~370
-- Total unique customers in dataset: ~99,000
-- Consecutive buyer rate: < 0.4% of all customers
-- This directly confirms PGQ5 (99%+ monthly churn) from a
-- completely different angle — the self-JOIN approach shows
-- only 370 customers ever ordered in two back-to-back months
-- These are the platform's highest-value retention events

-- FINDING 2: November-December 2017 is the peak consecutive period
-- Multiple rows show first_month=2017-11, second_month=2017-12
-- Black Friday (Nov 2017) brought in customers who returned in Dec
-- This is the only month pair where promotional lift converted
-- into a consecutive purchase — every other period is sparse
-- Implication: November is not just an acquisition event —
-- it is the single best retention window on the platform

-- FINDING 3: Days between orders ranges from 1 to 59 days
-- Minimum: 1 day (customer ordered day 31 of month M
--          and day 1 of month M+1 — technically consecutive months
--          but only 1 day apart)
-- Maximum: 59 days (ordered on day 1 of month M
--          and day 30 of month M+1)
-- The days_between metric confirms these are genuine
-- re-purchase decisions, not same-session corrections
-- (days_between >= 2 filter from PGQ9 not needed here
--  because month boundary naturally enforces separation)

-- FINDING 4: customer 8d50f5eadf appears 8 times in output
-- This customer shows consecutive pairs across multiple months:
-- Jul-Aug 2017, Aug-Sep 2017, Sep-Oct 2017, Oct-Nov 2017,
-- Nov-Dec 2017 (possibly more)
-- This is a genuine repeat buyer — extremely rare in OLIST
-- Their pattern suggests a business account or reseller
-- Cross-reference with order values and categories to confirm

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Rohan Gupta — Myntra Growth):
-- 1. The 370 consecutive buyers are your highest-value segment
--    Identify them by customer_unique_id and tag in CRM
--    These customers have demonstrated willingness to return
--    Re-engagement campaigns should target them specifically
-- 2. November is the only reliable retention window
--    Post-Black Friday December campaigns should be built
--    around re-engaging November buyers — not acquiring new ones
--    The data shows Nov-Dec is the only month pair with
--    meaningful consecutive buyer volume
-- 3. Investigate customer 8d50f5eadf as a case study
--    Multi-month consecutive buyer is almost unique in OLIST
--    What category? What price point? What state?
--    This customer's profile = the ideal acquisition target
-- ============================================================