-- =====================================================================================================================
-- Introducing - Product & Growth Analytics
-- ✅ PGQ8 - Payment Method Analysis  | BOL | Product Ops:
--  Our checkout team wants to know if the payment method customers choose is associated with
-- higher order values — this affects our checkout UX decisions. For each payment_type, show:
-- payment_type, order_count, avg_order_value, median_order_value, avg_installments,
-- pct_of_total_orders, and rank by avg_order_value descending. Fan-out fix required. Use
-- MAX(payment_installments) per order — not SUM. Exclude payment_type = not_defined."
-- =====================================================================================================================

-- one row in base cte = one order_id

WITH pay_order AS(
    SELECT
        order_id,
        payment_type,
        SUM(payment_value) AS order_value,
        MAX(payment_installments) AS installments
    FROM olist_order_payments
    WHERE payment_type != 'not_defined'
    GROUP BY order_id, payment_type
),
    joined AS(
        SELECT
            po.*
        FROM pay_order po
        JOIN olist_orders o
            ON o.order_id = po.order_id
        WHERE o.order_status = 'delivered'
    )
SELECT
        payment_type,
        COUNT(*) AS order_count,
        ROUND(AVG(order_value),2) AS avg_order_value,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY order_value) AS median_order_value,
        ROUND(AVG(installments),1) AS avg_installments,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS pct_of_total,
        RANK() OVER (ORDER BY AVG(order_value) DESC) AS rank
FROM joined
GROUP BY payment_type
ORDER BY avg_order_value DESC;

-- ============================================================
-- PGQ8 FINDINGS: Payment Method Analysis
-- Fan-out fix: SUM(payment_value) + MAX(installments) per order+type
-- Filter: payment_type != 'not_defined' + order_status = 'delivered'
-- ============================================================

-- FINDING 1: Credit card dominates — 75.31% of all orders
-- 3 in 4 delivered orders paid by credit card
-- Avg order value R$162.86 — highest of all payment types
-- Credit card customers spend 12.8% more than boleto customers
-- Avg 3.5 installments — customers spreading large purchases

-- FINDING 2: Boleto is a significant second at 19.45%
-- Brazil-specific payment method — bank slip, offline payment
-- Avg order value R$144.33 — lower than credit card
-- Avg installments = 1 — always pays in full, no spreading
-- Boleto buyers are lower-value but more decisive — pay once, done

-- FINDING 3: Voucher customers spend least — R$93.24 avg
-- 3.73% of orders — small volume but distinct behaviour
-- R$63.68 median — nearly half of credit card median (R$106.97)
-- Vouchers attract discount-seeking, price-sensitive customers
-- Lowest order value signals promotional/redemption-driven purchases

-- FINDING 4: Debit card is marginal — 1.51% of orders
-- Similar avg value to boleto (R$140.35) but tiny volume
-- Avg installments = 1 — same as boleto, pays in full
-- May reflect younger / unbanked customers without credit access

-- FINDING 5: Installment behaviour signals purchase size
-- Credit card: 3.5 avg installments — customers financing larger items
-- All others: 1.0 installments — full payment only
-- Installment availability on credit card is a conversion lever
-- Higher installments = customers can afford higher-value items
-- → Remove installment option = credit card AOV likely drops

-- FINDING 6: Median vs mean gap reveals skew
-- Credit card: mean R$162.86 vs median R$106.97 — large gap
-- High-value outliers pull mean up — median is the better KPI
-- Boleto: mean R$144.33 vs median R$93.78 — similar pattern
-- Both distributions are right-skewed — consistent with e-commerce

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Daan — BOL Product Ops):
-- 1. Protect credit card installment feature — it drives AOV
--    3.5 avg installments = customers buying items they couldn't
--    afford in a single payment. Remove it and AOV falls.
-- 2. Boleto conversion rate needs investigation
--    19.45% of orders but unknown abandonment rate
--    Boleto requires customer to pay at a bank — high dropout
--    Cross-reference: how many boletos generated vs paid?
-- 3. Voucher strategy review
--    R$93.24 avg value = promotional customers not converting
--    to full-price purchases. Track whether voucher users
--    return as credit card customers (upgrade path) or churn.
-- 4. Use median not mean for AOV reporting
--    Right-skewed distributions make mean misleading
--    R$106.97 (credit card median) is the true typical purchase
-- ============================================================