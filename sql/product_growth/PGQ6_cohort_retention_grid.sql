-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ6 - Cohort Retention Grid — 6-Month Retention by Acquisition Cohort  | Myntra | Growth & Retention:
-- I want a cohort retention table — classic product analytics. Group customers by their acquisition
-- month (first ever delivered order). Then for months 1 through 6 after acquisition, show what % of that
-- cohort returned and ordered again. Show: cohort_month, cohort_size, retention_month_1 through
-- retention_month_6 (each as a %). Focus on cohorts from Jan 2017 to Jun 2017 so we have full 6-month
-- windows. This is the standard SaaS retention grid — the hardest question in the block.
-- =====================================================================================================================

WITH cohort AS(
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
    activity AS(
        SELECT
            c.customer_unique_id,
            DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
        FROM olist_orders o
        JOIN olist_customers c
            ON o.customer_id = c.customer_id
        WHERE o.order_status = 'delivered'
    ),
    combined AS(
        SELECT
            co.cohort_month,
            ac.order_month,
            co.customer_unique_id,
            EXTRACT(YEAR FROM AGE(ac.order_month,co.cohort_month)) * 12 +
                EXTRACT(MONTH FROM AGE(ac.order_month, co.cohort_month)) AS month_offset
        FROM cohort co
        JOIN activity ac
        USING (customer_unique_id)
    )
SELECT
    TO_CHAR(cohort_month,'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ) AS cohort_size,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 1 ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ),0),1) AS ret_month_1,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 2 ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ),0),1) AS ret_month_2,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 3 ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ),0),1) AS ret_month_3,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 4 ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ),0),1) AS ret_month_4,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 5 ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ),0),1) AS ret_month_5,
    ROUND(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 6 ) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id) FILTER ( WHERE month_offset = 0 ),0),1) AS ret_month_6
FROM combined
WHERE cohort_month BETWEEN '2017-01-01' AND '2017-06-01'
GROUP BY cohort_month
ORDER BY cohort_month;

-- ============================================================
-- PGQ6 FINDINGS: Cohort Retention Grid
-- Cohorts: Jan 2017 — Jun 2017 | Window: 6 months
-- ============================================================

-- FINDING 1: Retention never exceeds 0.6% at any month offset
-- Best single cell: April 2017 cohort Month 1 = 0.6%
-- This means fewer than 1 in 200 customers from any cohort
-- returns in any given subsequent month
-- Confirms PGQ5 churn finding from a completely different angle

-- FINDING 2: No cohort shows improvement in retention over time
-- Month 1 retention (0.2%–0.6%) is roughly equal to Month 6
-- There is no "warming up" effect — customers who don't return
-- in Month 1 are not more likely to return in Month 6
-- The retention curve is flat, not declining — already at floor

-- FINDING 3: Larger cohorts do not retain better
-- Jan 2017 cohort (717 customers): avg retention 0.27%
-- May 2017 cohort (3,451 customers): avg retention 0.38%
-- Scale does not improve retention — it is not a sample size issue

-- FINDING 4: Cross-cohort consistency confirms structural cause
-- All 6 cohorts show <1% retention at every time point
-- If it were a product issue fixed over time, later cohorts
-- would show higher retention. They don't.
-- This is a category effect — durable goods, not repeat FMCG

-- FINDING 5: Month_offset = 0 cohort sizes differ from PGQ1 MAU
-- Jan 2017: cohort_size = 717 vs PGQ1 MAU = 718
-- 1-row difference — one customer's first order is ambiguous
-- Negligible — confirms cohort methodology is consistent

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Rohan Gupta — Myntra Growth):
-- 1. Monthly cohort retention is the wrong KPI for this business
--    <1% monthly retention is expected for durable goods
--    Switch to 6-month or 12-month retention window
-- 2. The real question is not "did they return next month"
--    but "did they ever return" — lifetime reorder rate
--    PGQ9 (time to second purchase) answers this correctly
-- 3. Cross-category purchase is the retention lever
--    A customer who bought electronics may return for homeware
--    Recommendation engine across categories = the LTV driver
-- 4. Do not benchmark against SaaS retention grids
--    B2C marketplace for durable goods has fundamentally
--    different purchase frequency than software subscriptions
-- ============================================================