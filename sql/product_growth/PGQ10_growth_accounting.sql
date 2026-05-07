-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ10 - Growth Accounting — New, Retained, Resurrected, Churned Users Each Month  | BOL | Performance Marketing:
-- This is the gold standard of growth analytics. For each month, I want to classify every user
-- movement: New = first ever order this month. Retained = ordered last month AND this month.
-- Resurrected = ordered this month, was inactive last month, but had ordered before. Churned = ordered
-- last month, did NOT order this month (negative count). Show: order_month, new_users, retained_users,
-- resurrected_users, churned_users, net_change (new + resurrected - churned). This is the hardest
-- question in the PGQ block. State your plan carefully before writing.
-- =====================================================================================================================

-- One row in my base CTE = one customer + month

WITH customer_month AS(
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
),
    first_order AS(
        SELECT
            customer_unique_id,
            MIN(order_month) AS first_month
        FROM customer_month
        GROUP BY 1
    ),
    classified_user AS(
        SELECT
            cm.customer_unique_id,
            cm.order_month,
            fo.first_month,
            LAG(cm.order_month) OVER (PARTITION BY cm.customer_unique_id ORDER BY cm.order_month) AS prev_active_month
        FROM customer_month cm
        JOIN first_order fo
            ON cm.customer_unique_id = fo.customer_unique_id
    ),
    user_type AS(
        SELECT
            customer_unique_id,
            order_month,
            CASE
                WHEN order_month = first_month THEN 'New'
                WHEN prev_active_month = order_month - INTERVAL '1 month' THEN 'Retained'
                ELSE 'Resurrected'
            END AS user_status
        FROM classified_user
    ),
    churned AS(
        SELECT
            cm.order_month + INTERVAL '1 month' AS churn_month,
            COUNT(DISTINCT cm.customer_unique_id) AS churned_users
        FROM customer_month cm
        LEFT JOIN customer_month cm2
            ON cm.customer_unique_id = cm2.customer_unique_id
            AND cm2.order_month = cm.order_month + INTERVAL '1 month'
        WHERE cm2.customer_unique_id IS NULL
        GROUP BY 1
    )
SELECT
    TO_CHAR(ut.order_month,'YYYY-MM') AS order_month,
    COUNT(*) FILTER ( WHERE ut.user_status = 'New') AS new_users,
    COUNT(*) FILTER ( WHERE ut.user_status = 'Retained') AS retained_users,
    COUNT(*) FILTER ( WHERE ut.user_status = 'Resurrected') AS resurrected_users,
    MAX(COALESCE(ch.churned_users,0)) AS churned_users,
    COUNT(*) FILTER ( WHERE ut.user_status = 'New') + COUNT(*) FILTER ( WHERE ut.user_status = 'Retained')
                            + COUNT(*) FILTER ( WHERE ut.user_status = 'Resurrected')
                            - MAX(COALESCE(ch.churned_users,0)) AS net_change
FROM user_type ut
LEFT JOIN churned ch
    ON ut.order_month = ch.churn_month
GROUP BY ut.order_month
ORDER BY ut.order_month;

-- ============================================================
-- PGQ10 FINDINGS: Growth Accounting
-- Definition:
--   New        = first ever order this month
--   Retained   = active last month AND this month (consecutive)
--   Resurrected = active this month, inactive last month, had prior orders
--   Churned    = active last month, absent this month
-- Period: Sep 2016 — Aug 2018
-- ============================================================

-- FINDING 1: New users dominate every single month
-- Retained users never exceed 45 in any month
-- Resurrected users never exceed 145 in any month
-- New users range from 717 to 7,060
-- The platform runs almost entirely on first-time buyers
-- Retained + Resurrected combined never exceed 5% of New users

-- FINDING 2: Retained users are critically low
-- Peak retained: 45 (May 2018) out of 6,506 active users = 0.69%
-- This means fewer than 1 in 100 active users ordered
-- in two consecutive months — confirms PGQ5/PGQ6 structurally
-- The retention engine is essentially non-functional

-- FINDING 3: Resurrected users growing slowly but consistently
-- Sep 2016:   0 resurrected
-- Aug 2018: 129 resurrected
-- Small absolute numbers but the trend is positive
-- Customers who skipped months are gradually returning
-- This is the healthier retention signal — long-cycle buyers
-- coming back when a new need arises

-- FINDING 4: Nov 2017 Black Friday — largest single-month inflow
-- New: 7,060 | Retained: 37 | Resurrected: 86
-- Net change: +2,803 — largest positive net change in dataset
-- But 99.4% of that inflow was new users — not retention
-- Black Friday = acquisition event, not retention event
-- Dec 2017 net_change: -1,692 — immediate reversal after spike

-- FINDING 5: Churned users consistently dwarf all inflows
-- Every month churned > retained + resurrected by massive margin
-- Example May 2018: retained=45, resurrected=142 → inflow=187
--                   churned=6,699 → outflow=6,699
-- Net non-new movement: -6,512 every month
-- New users are the only reason the platform sustains any MAU

-- FINDING 6: Net change is positive only when New users spike
-- Positive net months: coincide with marketing/promotional events
-- Negative net months: natural state without promotional spend
-- Platform has no organic growth engine — entirely promo-dependent

-- FINDING 7: GROUP BY churned_users causes duplicate rows risk
-- Note: GROUP BY ut.order_month, ch.churned_users can produce
-- duplicate rows if a month has multiple churned values from JOIN
-- Safer pattern: GROUP BY ut.order_month only and use
-- MAX(COALESCE(ch.churned_users,0)) in SELECT
-- Current output looks clean but document this for production code

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Noor Bakker — BOL Performance):
-- 1. Growth accounting exposes the structural truth:
--    This is a New user treadmill — without constant acquisition
--    spend the platform shrinks every month
--    Retained + Resurrected combined cannot offset monthly churn
--
-- 2. The Resurrected trend is the only positive signal
--    Growing from 0 to 129/month over 2 years
--    These are long-cycle buyers — worth a dedicated campaign
--    Tag them separately from churned users in CRM
--    They respond to need-based triggers, not time-based emails
--
-- 3. Reframe the growth KPI
--    Current: MAU (hides the churn problem)
--    Better:  New / Retained / Resurrected / Churned separately
--    This growth accounting framework makes the problem visible
--    A dashboard showing all four lines is the honest view
--
-- 4. The retention target should be Resurrected not Retained
--    For a durable goods marketplace, monthly retention is
--    structurally impossible (who buys a TV two months in a row?)
--    Resurrected users = the realistic retention win
--    Target: grow Resurrected from 129 to 500/month by end 2019
--    That is achievable. Monthly Retained of 500 is not.
-- ============================================================