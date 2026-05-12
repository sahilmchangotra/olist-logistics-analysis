-- =====================================================================================================================
-- Introducing - Self-JOINs Practice
-- ✅ SJ3 - Theme - Self-JOIN
-- Cohort Revenue Benchmarking | BOL | Performance Marketing:
-- Our CRM team wants to identify high-value customers within each acquisition cohort. Group
-- customers by their acquisition month (first delivered order month). Then compare each customer's total
-- lifetime revenue to their cohort average. Show: customer_unique_id, cohort_month,
-- customer_total_revenue, cohort_avg_revenue, revenue_vs_cohort_pct (how much % above or below
-- cohort average), and value_flag: Champion (>50% above cohort avg), Strong (10-50% above), Average
-- (-10% to +10%), Below Average (<-10%). Only cohorts with at least 50 customers. Order by
-- cohort_month, revenue_vs_cohort_pct descending.
-- =====================================================================================================================

WITH pay_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM olist_order_payments
    GROUP BY order_id
),
    cust_base AS (
        SELECT
            c.customer_unique_id,
            DATE_TRUNC('month',MIN(o.order_purchase_timestamp)) AS cohort_month,
            SUM(pa.order_value) AS total_revenue
        FROM olist_orders o
        JOIN olist_customers c
            ON c.customer_id = o.customer_id
        JOIN pay_agg pa
            ON pa.order_id = o.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
    ),
    cohort_stats AS (
        SELECT
            cohort_month,
            COUNT(DISTINCT customer_unique_id) AS cohort_size,
            ROUND(AVG(total_revenue),2) AS cohort_avg_revenue
        FROM cust_base
        GROUP BY cohort_month
        HAVING COUNT(DISTINCT customer_unique_id) >= 50
    )
SELECT
    c.customer_unique_id,
    TO_CHAR(c.cohort_month,'YYYY-MM') AS cohort_month,
    c.total_revenue,
    cs.cohort_avg_revenue,
    ROUND((c.total_revenue - cs.cohort_avg_revenue) * 100.0 /
          NULLIF(cs.cohort_avg_revenue,0),2) AS revenue_vs_cohort_pct,
    CASE
        WHEN (c.total_revenue - cs.cohort_avg_revenue) * 100.0 /
          NULLIF(cs.cohort_avg_revenue,0) > 50 THEN 'Champion'
        WHEN (c.total_revenue - cs.cohort_avg_revenue) * 100.0 /
          NULLIF(cs.cohort_avg_revenue,0) BETWEEN 10 AND 50 THEN 'Strong'
        WHEN  (c.total_revenue - cs.cohort_avg_revenue) * 100.0 /
          NULLIF(cs.cohort_avg_revenue,0) BETWEEN -10 AND 10 THEN 'Average'
        ELSE 'Below Average'
    END AS value_flag
FROM cust_base c
JOIN cohort_stats cs
    ON c.cohort_month = cs.cohort_month
ORDER BY cohort_month , revenue_vs_cohort_pct DESC;

-- ============================================================
-- SJ3 FINDINGS: Cohort Revenue Benchmarking
-- Pre-aggregated cohort_stats CTE (not self-JOIN cross product)
-- Fan-out fix: pay_agg SUM(payment_value) per order
-- Filter: cohort >= 50 customers | order_status = 'delivered'
-- ============================================================

-- FINDING 1: Oct 2016 cohort is heavily Champion-skewed
-- Cohort avg: R$184.42 | Top customer: R$1,423.55 (671.91% above avg)
-- 46+ Champion customers in Oct 2016 cohort alone
-- Oct 2016 is the platform's earliest cohort — early adopters
-- tend to be higher-value buyers who sought out the platform
-- before mass marketing existed
-- These are not promotional buyers — they found OLIST organically
-- Early adopter cohorts almost always outspend later cohorts
-- because they have stronger product-market fit alignment

-- FINDING 2: Champion threshold (>50% above avg) is easily cleared
-- Multiple Oct 2016 customers exceed 100%, 200%, even 600% above avg
-- R$1,423.55 vs cohort avg R$184.42 = 7.7x the average customer
-- This extreme skew confirms e-commerce revenue follows a
-- power law distribution — a small number of customers
-- generate disproportionate revenue
-- The Champion flag at 50% threshold correctly isolates this group

-- FINDING 3: Strong band (10-50% above) is a narrow transition zone
-- The output shows a sharp cliff from Champion (46+ rows at >50%)
-- to Strong (R$273 and R$270 at ~46-48%)
-- Very few customers land in the 10-50% band for Oct 2016
-- This bimodal distribution (many Champions, few Strong) is typical
-- of early cohorts — buyers are either high-intent (Champions)
-- or average (bought once at typical price point)

-- FINDING 4: Cohort avg of R$184.42 in Oct 2016 is the baseline
-- Later cohorts (2017-2018) will show lower cohort averages
-- as the platform scaled and attracted more price-sensitive buyers
-- Cross-reference with PGQ2 (ARPU declining as MAU grew) confirms:
-- as cohort size grows, cohort avg revenue falls
-- The Champion % within each cohort is expected to shrink
-- as the platform moves from early adopters to mass market

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Noor Bakker — BOL Performance):
-- 1. Champions in early cohorts (Oct 2016 - Jan 2017) are
--    your highest LTV customers — identify and protect them
--    Even if they haven't ordered recently (PGQ9 — 90+ day returners)
--    they may still be active but infrequent buyers
--    Do not let them lapse without a re-engagement campaign
-- 2. The cohort avg benchmark reveals ARPU erosion over time
--    Use cohort_avg_revenue trend across cohorts to quantify
--    how much monetisation has declined per acquisition cohort
--    This is the cohort-level version of PGQ2's ARPU finding
-- 3. Champions (>50% above cohort avg) should receive:
--    Priority customer service | Early access to new categories
--    Personalised recommendations based on purchase history
--    These customers are 7x more valuable than average —
--    the cost of special treatment is minimal vs revenue at risk
-- ============================================================