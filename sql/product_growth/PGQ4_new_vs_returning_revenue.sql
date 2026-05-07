-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ4 - New vs Returning Revenue Split  | Myntra | Growth & Retention:
-- A key growth question: are we living off new customer acquisition, or are existing customers
-- coming back and spending more? For each month, classify each order as from a New customer
-- (first-ever order from that customer_unique_id) or Returning (had at least one prior delivered order).
-- Show: order_month, new_customer_revenue, returning_customer_revenue, total_revenue,
-- returning_revenue_pct. Order by month ascending.
-- =====================================================================================================================

WITH pay_agg AS(
    SELECT
        order_id,
        SUM(payment_value) AS order_revenue
    FROM olist_order_payments
    GROUP BY order_id
),
    order_classified AS(
        SELECT
            DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
            p.order_revenue,
            ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS order_num
        FROM olist_orders o
        JOIN olist_customers c
            ON o.customer_id = c.customer_id
        JOIN pay_agg p
            ON o.order_id = p.order_id
        WHERE o.order_status = 'delivered'
            AND o.order_purchase_timestamp IS NOT NULL
    )
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    ROUND(SUM(order_revenue) FILTER ( WHERE order_num = 1 ),2) AS new_customer_revenue,
    ROUND(SUM(order_revenue) FILTER ( WHERE order_num > 1 ),2) AS returning_customer_revenue,
    ROUND(SUM(order_revenue),2) AS total_revenue,
    ROUND(SUM(order_revenue) FILTER ( WHERE order_num > 1 ) * 100.0 / NULLIF(SUM(order_revenue),0),2) AS returning_revenue_pct
FROM order_classified
GROUP BY order_month
HAVING ROUND(SUM(order_revenue) FILTER ( WHERE order_num = 1 ),2) > 20
ORDER BY order_month;

-- ============================================================
-- PGQ4 FINDINGS: New vs Returning Customer Revenue Split
-- Period: Oct 2016 — Aug 2018
-- Fan-out fix: pay_agg CTE applied
-- ============================================================

-- FINDING 1: Returning revenue never exceeds 3.69% of total
-- Peak returning revenue share: 3.69% (Feb 2018)
-- This means 96%+ of revenue comes from first-time buyers
-- every single month — throughout the entire 2-year period
-- Platform is structurally dependent on new customer acquisition

-- FINDING 2: Returning revenue is growing slowly but consistently
-- Oct 2016: 1.10% returning share
-- Aug 2018: 3.16% returning share
-- Absolute growth: +2.06pp over 22 months
-- Direction is positive but the base is critically low

-- FINDING 3: Nov 2017 Black Friday — returning share held at 2.79%
-- Despite MAU spike to 7,183 (PGQ1) and revenue spike to R$1.15M
-- Returning revenue grew in absolute terms (R$32,240)
-- but share stayed flat — new buyers flooded in proportionally
-- Black Friday acquires new customers, does not activate returning ones

-- FINDING 4: Returning revenue in absolute terms is growing
-- Jan 2017: R$3,137 returning revenue
-- Aug 2018: R$31,113 returning revenue
-- 10x growth in absolute returning revenue over 20 months
-- But total revenue grew faster — so share % stayed low

-- FINDING 5: Dec 2016 anomaly — NULL returning revenue
-- Single delivered order in Dec 2016 — order_num = 1 only
-- No returning customers possible with 1 order
-- Exclude from trend analysis

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Rohan Gupta — Myntra Growth):
-- 1. Retention is the critical gap — 96%+ revenue from new buyers
--    is unsustainable without continuous acquisition spend
--    Customer acquisition cost (CAC) is being paid every month
--    with minimal lifetime value (LTV) recovery
-- 2. Returning revenue trending up (+2pp over 22 months) is a
--    positive signal — but needs to reach 10%+ to be meaningful
--    Target: double returning revenue share to 6-7% by end 2019
-- 3. Black Friday strategy insight (cross-reference PGQ1 + PGQ2):
--    Nov 2017 brought 7,183 MAU but returning share stayed flat
--    Post-Black Friday re-engagement campaign needed in Dec/Jan
--    to convert one-time buyers into returning customers
-- 4. Cross-reference with PGQ9 (time to second purchase)
--    to understand how long returning customers take to reorder
--    and set re-engagement email timing accordingly
-- ============================================================