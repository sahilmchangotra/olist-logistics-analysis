-- =====================================================================================================================
-- Introducing - Mixed Practice - Logistics & Marketing
-- ✅ MX4 - Theme - Logistics
-- PARTITION BY 2 Columns: Carrier Performance per State per Month | JET SODA Amsterdam | Logistics Operations:
-- I need carrier performance broken down by both state AND month simultaneously. Use
-- order_delivered_customer_date vs order_estimated_delivery_date. For each seller_state + order_month
-- combination (min 20 orders), compute: seller_state, order_month, total_orders, late_orders,
-- late_rate_pct. Then rank using DENSE_RANK partitioned by BOTH seller_state AND order_month —
-- rank 1 = worst late rate within that state-month. Wait — that gives every row rank 1. Rethink: PARTITION
-- BY seller_state ORDER BY late_rate_pct DESC gives rank within state across all months. Show results
-- for top 5 seller states by total order volume. Order by seller_state, late_rate_pct descending.
-- =====================================================================================================================

WITH top_5_sellers AS (
    SELECT
        s.seller_state
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    GROUP BY 1
    ORDER BY COUNT(DISTINCT o.order_id) DESC
    LIMIT 5
),
    seller_base AS(
    SELECT
        s.seller_state,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) AS late_orders,
        ROUND(COUNT(DISTINCT o.order_id) FILTER ( WHERE o.order_delivered_customer_date >
                                                  o.order_estimated_delivery_date) * 100.0 /
                NULLIF(COUNT(DISTINCT o.order_id),0),2) AS late_rate_pct
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
        AND s.seller_state IN (SELECT seller_state FROM top_5_sellers)
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1,2
    HAVING COUNT(DISTINCT o.order_id) >= 20
),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (PARTITION BY seller_state ORDER BY late_rate_pct DESC) AS rank
        FROM seller_base
    )
SELECT
    seller_state,
    TO_CHAR(order_month, 'YYYY-MM') AS order_month,
    TO_CHAR(order_month,'YYYY') AS order_year,
    TO_CHAR(order_month,'YYYY-"Q"Q') AS quarter,
    total_orders,
    late_orders,
    late_rate_pct,
    rank
FROM ranking
ORDER BY seller_state, late_rate_pct DESC;

-- ============================================================
-- MX4 FINDINGS: Carrier Performance per Seller State per Month
-- PARTITION BY seller_state ORDER BY late_rate_pct DESC
-- Top 5 seller states: SP, MG, PR, RJ, SC
-- Filter: >= 20 orders per state-month
-- ============================================================

-- FINDING 1: RJ has the worst structural late delivery problem
-- RJ 2018-03: 34.56% late rate — 1 in 3 orders arrived late
-- Highest rate among all 5 states in any single month
-- At only 298 orders — RJ is already the smallest seller state
-- among the top 5 — and losing 34.56% to late delivery
-- compounds the problem: low volume AND poor service quality
-- SP 2018-03: 22.97% late at 5,164 orders = 1,186 late orders
-- SP has the larger ABSOLUTE impact (1,186 late orders vs 103)
-- RJ has the larger STRUCTURAL problem (rate % — 1 in 3 vs 1 in 5)
-- Both need intervention but through different mechanisms:
-- SP → scale + process improvement (volume justifies investment)
-- RJ → carrier contract audit (structural rate at low volume)

-- FINDING 2: June 2018 shows lowest late rates across all 5 states
-- MG: 2.28% | PR: 0.23% | RJ: 0.87% | SC: 0.44% | SP: 1.52%
-- Every state at or below 2.28% — best collective performance month
-- Post-holiday demand recovery: Corpus Christi (late May/early June)
-- suppresses order volume — fewer orders = easier to fulfil on time
-- Lower daily order load gives carriers capacity buffer
-- June is not a genuine logistics improvement — it is a volume effect
-- Recommendation: do not use June as the benchmark for normal performance
-- Use rolling 3-month average excluding holiday-impacted months

-- FINDING 3: Q1 2018 is a platform-wide late delivery crisis
-- SP worst month: 2018-03 at 22.97% (rank 1)
-- PR worst month: 2018-02 at 12.91% (rank 1)
-- RJ worst month: 2018-03 at 34.56% (rank 1)
-- SC worst month: 2018-01 at 14.10% (rank 1)
-- MG worst month: 2018-03 at 14.25% (rank 1)
-- All 5 states have their worst month in Jan-Mar 2018
-- This is not a seller-specific or state-specific failure
-- It is a platform-wide pattern — pointing to systemic cause:
-- Post Black Friday (Nov 2017) order surge carried into Q1 2018
-- Carrier networks overloaded by November spike volume
-- Lead times and fulfilment backlogs persisted into Q1 2018
-- Q1 2018 = delayed consequence of Nov 2017 promotional event

-- FINDING 4: PARTITION BY 2 columns insight from this question
-- If you PARTITION BY seller_state, order_month simultaneously
-- every row gets rank 1 — one row per partition after aggregation
-- The correct approach: PARTITION BY seller_state ORDER BY late_rate_pct
-- This gives rank of each month within its state across all months
-- This is the key lesson of MX4 — partition boundary must contain
-- multiple rows for ranking to be meaningful

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Lars Visser — JET SODA):
-- 1. RJ carrier audit is highest priority by rate
--    34.56% in March 2018 is structurally broken — not a spike
--    RJ appears in top 3 worst ranks consistently (ranks 1-8)
--    Carrier contract renegotiation or carrier switch needed
-- 2. SP volume management is highest priority by absolute impact
--    1,186 late orders in March 2018 — largest single-month loss
--    At 5,164 orders per month SP needs dedicated carrier capacity
--    SLA agreements must include volume-adjusted guarantees
-- 3. Q1 2018 platform-wide failure requires post-mortem
--    All 5 states worst performance in Jan-Mar 2018
--    Root cause: Black Friday Nov 2017 surge overloaded carriers
--    Solution: pre-position carrier capacity in Oct before Black Friday
--    Do not wait for November spike to hit — contract buffer capacity early
-- 4. June 2018 low rates are not a success signal
--    Post-holiday volume suppression, not genuine improvement
--    Use Aug 2018 as the baseline — full demand, moderate rates
--    MG: 3.29% | PR: 4.88% | RJ: 11.33% | SC: 9.38% | SP: 11.73%
-- ============================================================