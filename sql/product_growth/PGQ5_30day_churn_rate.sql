-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ5 - 30-Day Churn Rate by Month  | BOL | Performance Marketing:
-- We define a churned user as someone who was active in month M but placed zero orders in month
-- M+1. For each month (as the base month), calculate: active_users (unique customers who ordered in
-- month M), churned_users (of those, how many had zero orders in M+1), churn_rate_pct. Use a self-JOIN
-- or LEAD approach. Exclude the last month of data (no M+1 to compare against). Order by month
-- ascending.
-- =====================================================================================================================

WITH cust_month AS(
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
    churn_cal AS(
        SELECT
            m.order_month,
            COUNT(DISTINCT m.customer_unique_id) AS active_users,
            COUNT(DISTINCT m.customer_unique_id) FILTER ( WHERE m1.customer_unique_id IS NULL ) AS churned_users
        FROM cust_month m
        LEFT JOIN cust_month m1
            ON m.customer_unique_id = m1.customer_unique_id
            AND m1.order_month = m.order_month + INTERVAL '1 month'
        GROUP BY m.order_month
    )
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    active_users,
    churned_users,
    ROUND(churned_users * 100.0 / NULLIF(active_users,0),2) AS churn_rate_pct
FROM churn_cal
WHERE order_month < (SELECT MAX(order_month) FROM cust_month)
ORDER BY order_month;

-- ============================================================
-- PGQ5 FINDINGS: 30-Day Churn Rate by Month
-- Definition: active in month M, zero orders in month M+1
-- Period: Sep 2016 — Jul 2018 (last month excluded)
-- ============================================================

-- FINDING 1: Churn rate is catastrophically high — 99%+ every month
-- Range: 99.16% (Oct 2017) to 99.82% (Feb 2017)
-- This means fewer than 1 in 100 active customers
-- returns the following month — consistently, across 22 months
-- This is not a spike or a seasonal issue — it is structural

-- FINDING 2: Best churn month is still 99.16% (Oct 2017)
-- Even in the best month on record, 99 out of 100 customers
-- did not return the next month
-- The platform has no meaningful repeat purchase behaviour

-- FINDING 3: Cross-validates PGQ4 returning revenue finding
-- PGQ4: returning revenue never exceeds 3.69% of total
-- PGQ5: 99%+ of customers churn every single month
-- Both metrics tell the same structural story from different angles:
-- Olist operates as a one-time purchase platform, not a marketplace

-- FINDING 4: Dec 2016 anomaly — 0% churn (1 customer)
-- Single customer in Dec 2016 who ordered again in Jan 2017
-- Statistically meaningless — 1 row, exclude from analysis

-- FINDING 5: Churn rate barely moved despite 10x MAU growth
-- Jan 2017: 99.72% churn at 718 MAU
-- Jul 2018:  99.39% churn at 6,100 MAU
-- MAU grew 8.5x — churn improved by only 0.33pp
-- Scale did not solve the retention problem

-- FINDING 6: This is likely a category effect, not a platform failure
-- Customers buy a TV, a mattress, a blender — and don't need
-- another one next month. The product categories on Olist
-- are inherently low-frequency purchases.
-- Unlike FMCG or grocery, these are durable goods purchases.
-- Monthly churn is the wrong metric for this business model.
-- Quarterly or 6-month reorder window would be more appropriate.

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Noor Bakker — BOL Performance):
-- 1. Stop measuring monthly churn for this business
--    99% monthly churn is expected for durable goods marketplace
--    Switch to 90-day or 180-day retention window
--    Cross-reference with PGQ9 (time to second purchase)
-- 2. The retention lever is cross-category purchasing
--    A customer who bought electronics might return for home goods
--    Recommendation engine across categories = the real LTV driver
-- 3. Re-engagement timing is critical
--    PGQ9 will show when returning customers actually come back
--    Target re-engagement campaigns at that window — not 30 days
-- 4. Compare with PGQ10 (Growth Accounting)
--    Resurrected users = customers who skipped months then returned
--    This is more meaningful than monthly churn for this dataset
-- ============================================================