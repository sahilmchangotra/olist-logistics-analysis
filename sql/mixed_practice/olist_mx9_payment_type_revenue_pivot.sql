-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX9 - Theme - Marketing
-- Payment Type Revenue Pivot: Month x Payment Type | BOL | Product Operations:
-- Our checkout team wants a monthly pivot showing revenue by payment type side by side. Each
-- row = one month. Columns: order_month, credit_card_revenue, boleto_revenue, voucher_revenue,
-- debit_card_revenue, total_revenue, credit_card_pct (credit card share of total). Fan-out fix required —
-- aggregate payments to order level first. Exclude payment_type = not_defined. Order by order_month
-- ascending.
-- =====================================================================================================================

WITH payment_base AS(
    SELECT
        order_id,
        payment_type,
        SUM(payment_value) AS order_value
    FROM olist_order_payments
    WHERE payment_type != 'not_defined'
    GROUP BY 1, 2
),
    joined AS (
        SELECT
            DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
            pb.payment_type,
            pb.order_value
        FROM olist_orders o
        JOIN payment_base pb
            ON o.order_id = pb.order_id
        WHERE o.order_status = 'delivered'
            AND o.order_purchase_timestamp IS NOT NULL
    )
SELECT
    TO_CHAR(order_month,'YYYY-MM') AS order_month,
    SUM(CASE WHEN payment_type = 'credit_card' THEN order_value ELSE 0 END) AS credit_card_revenue,
    SUM(CASE WHEN payment_type = 'boleto' THEN order_value ELSE 0 END) AS boleto_revenue,
    SUM(CASE WHEN payment_type = 'voucher' THEN order_value ELSE 0 END) AS voucher_revenue,
    SUM(CASE WHEN payment_type = 'debit_card' THEN order_value ELSE 0 END) AS debit_card_revenue,
    ROUND(SUM(order_value),2) AS total_revenue,
    ROUND(SUM(CASE WHEN payment_type = 'credit_card' THEN order_value ELSE 0 END) * 100.0 /
          NULLIF(SUM(order_value),0),2) AS credit_card_pct
FROM joined
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- MX9 FINDINGS: Payment Type Revenue Pivot — Month x Payment Type
-- Fan-out fix: SUM(payment_value) per order + payment_type
-- Filter: payment_type != 'not_defined' | order_status = 'delivered'
-- ============================================================

-- FINDING 1: Debit card shows sudden 3-4x growth in Jun-Aug 2018
-- Jan-May 2018: debit card R$2,000–R$11,000/month
-- Jun 2018: R$35,605 | Jul 2018: R$38,863 | Aug 2018: R$45,390
-- This is not seasonal — it appears only in the final 3 months
-- Two possible explanations:
-- (a) Consumer shift toward budgeting post Black Friday debt
--     Customers who over-spent on credit in Nov-Dec 2017
--     are now avoiding credit card usage in mid-2018
-- (b) Credit card transaction limits being reached
--     High-volume buyers hitting monthly credit limits
--     and switching to debit for overflow purchases
-- Either way this signals a change in consumer financial behaviour
-- that the platform should monitor — debit card orders may have
-- lower average values and fewer installments than credit card
-- Cross-reference: if debit card AOV < credit card AOV in these months
-- total revenue per order is declining despite stable order volume

-- FINDING 2: Credit card share dips post-holiday as boleto rises
-- May 2017: credit_card_pct = 74.68% (lowest point)
--   boleto_revenue: R$124,668 — highest relative share to that point
-- Jul 2018: credit_card_pct = 75.48%
--   boleto_revenue: R$193,413 — highest absolute boleto month
-- Pattern: post-holiday period consumers shift to boleto and vouchers
-- Likely cause: credit card limits exhausted after holiday spending
-- Boleto (bank slip) allows customers to pay without credit exposure
-- This is a Brazil-specific behaviour — boleto is used as a
-- credit card alternative for budget-conscious consumers
-- Implication for platform: boleto conversion rate needs monitoring
-- Boleto requires customers to physically pay at a bank — higher dropout
-- If boleto share rises post-holiday, abandoned boletos may inflate
-- order creation numbers without matching revenue

-- FINDING 3: Voucher revenue is stable — signals mixed payment behaviour
-- Range: R$4,023 (Jan 2017) to R$28,531 (Jan 2018)
-- 2018 average: R$20,000–R$28,000/month consistently
-- Vouchers do not spike during Black Friday (Nov 2017: R$18,667)
-- and do not collapse post-holiday — entirely flat seasonal pattern
-- This confirms vouchers are used as a payment complement
-- not as a standalone payment type
-- Customers combine voucher + credit card or voucher + boleto
-- to offset a portion of their order value
-- The fan-out fix captures this correctly — one order can have
-- multiple payment_type rows — voucher appears alongside credit card
-- Implication: voucher campaigns drive incremental revenue
-- not substitution of other payment types
-- A R$50 voucher does not replace R$50 of credit card spend
-- it reduces the credit card portion while keeping total order value

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Daan — BOL Product Ops):
-- 1. Investigate Jun-Aug 2018 debit card surge immediately
--    R$45,390 in Aug 2018 vs R$3,068 in Aug 2017 — 14x growth
--    Determine if this is new customers or existing customers switching
--    If existing customers are shifting from credit to debit
--    their installment usage drops → lower AOV → lower monthly revenue
--    per customer despite same order frequency
-- 2. Pre-position boleto capacity before Black Friday
--    Post-holiday boleto surge is predictable from this data
--    Ensure boleto processing SLAs are not degraded by volume
--    Track boleto abandonment rate separately from payment completion
-- 3. Use voucher campaigns strategically — not as discounts
--    Stable voucher revenue proves they are used as payment complements
--    A voucher campaign increases total basket size
--    not substitutes existing payment — positive ROI signal
--    Design vouchers with minimum order value to maximise basket lift
-- ============================================================