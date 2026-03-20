-- ============================================================
-- 🚚 Logistics & Delivery Performance Analytics
-- FILE: 01_logistics_performance.sql
-- DESCRIPTION: JET SODA Style — SLA breach analysis,
--              delivery time trends, seller performance
-- STAKEHOLDERS: Carlos Mendes (ShopBrasil Revenue Analytics)
--               Emma Clarke (RetailIQ London)
-- DATASET: OLIST Brazilian E-Commerce — kaggle schema
-- MIRRORS: Just Eat Takeaway SODA team analytics framework
-- ============================================================


-- ============================================================
-- Q1: SLA Breach Rate by City
-- Business Question: Which cities have the worst delivery
-- SLA performance? SLA breach = delivered > 3 days late
-- Stakeholder: Carlos Mendes
-- JET Relevance: Primary courier network health KPI
--               Used daily to trigger zone interventions
-- ============================================================

-- One row in base CTE = one order

WITH order_delivery AS (
    SELECT
        c.customer_city                             AS city,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        CASE
            WHEN o.order_delivered_customer_date >
                o.order_estimated_delivery_date
                + INTERVAL '3 days'
            THEN 1 ELSE 0
        END                                         AS sla_breach
    FROM kaggle.olist_orders o
    JOIN kaggle.olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
),
city_sla AS (
    SELECT
        city,
        COUNT(DISTINCT order_id)                    AS total_orders,
        SUM(sla_breach)                             AS total_breaches,
        ROUND(SUM(sla_breach) * 100.0
            / NULLIF(COUNT(*), 0), 2)               AS breach_rate_pct
    FROM order_delivery
    GROUP BY city
    HAVING COUNT(*) >= 50
)
SELECT
    city,
    total_orders,
    total_breaches,
    breach_rate_pct,
    DENSE_RANK() OVER (
        ORDER BY breach_rate_pct DESC
    )                                               AS rank
FROM city_sla
ORDER BY rank;

-- FINDING: Maceio worst — 25% breach rate (1 in 4 orders late!)
--          Sao Paulo best large city — 3.35% breach rate
--          Northeast Brazil cities dominate worst performers
-- INSIGHT: Logistics infrastructure weakest in Northeast
--          Courier capacity investment needed urgently
-- JET ACTION: Cities > 15% breach → performance warning
--             Cities > 25% breach → immediate intervention
-- NOTE: Always use EXPLICIT JOIN — comma join = cartesian product!
--       Always filter IS NOT NULL on date columns for INTERVAL


-- ============================================================
-- Q2: Monthly Delivery Time Trend + 3-Month Rolling Average
-- Business Question: Is our delivery network improving?
-- Show monthly avg delivery days + rolling average + alert flag
-- Stakeholder: Emma Clarke
-- JET Relevance: Network capacity planning and maturity KPI
-- ============================================================

-- One row in base CTE = one order

WITH delivery_days AS (
    SELECT
        order_id,
        TO_CHAR(order_purchase_timestamp,
            'YYYY-MM')                              AS year_month,
        DATE_PART('day',
            order_delivered_customer_date -
            order_purchase_timestamp)               AS delivery_days
    FROM kaggle.olist_orders
    WHERE order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
        AND order_purchase_timestamp IS NOT NULL
),
monthly_avg AS (
    -- One row = one month
    SELECT
        year_month,
        COUNT(order_id)                             AS total_orders,
        ROUND(AVG(delivery_days)::NUMERIC, 2)       AS avg_delivery_days
    FROM delivery_days
    GROUP BY year_month
),
rolling_calc AS (
    SELECT
        *,
        ROUND(AVG(avg_delivery_days) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2)                              AS rolling_3m_avg,
        CASE
            WHEN avg_delivery_days > 15
                THEN 'Performance Alert'
            ELSE 'Within Target'
        END                                         AS performance_flag
    FROM monthly_avg
)
SELECT
    year_month,
    total_orders,
    avg_delivery_days,
    rolling_3m_avg,
    performance_flag
FROM rolling_calc
ORDER BY year_month;

-- FINDING: Oct 2016 — 19 days (network just launched)
--          Feb-Mar 2018 — Performance Alert (post Black Friday
--          backlog + Brazilian Carnival season overlap)
--          Aug 2018 — 7.29 days (best performance — 63%
--          improvement from network launch!)
-- INSIGHT: Steady network maturity 2016→2018
--          Rolling average reveals Feb-Mar 2018 sustained
--          pressure — not just single month spike
-- JET ACTION: Months > 15 days trigger capacity review
--             Rolling avg used for forecasting courier needs
-- NOTE: DATE_PART('day', timestamp - timestamp) = delivery days
--       ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = 3 month window


-- ============================================================
-- Q3: Seller Performance Scorecard
-- Business Question: Which sellers cause most delivery delays?
-- Show seller KPIs — orders, delivery time, breach rate,
-- review score. Rank by breach rate.
-- Stakeholder: Emma Clarke
-- JET Relevance: Seller/courier quality intervention programme
-- ============================================================

-- One row in base CTE = one order

WITH seller_orders AS (
    SELECT
        s.seller_id,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        DATE_PART('day',
            o.order_delivered_customer_date -
            o.order_purchase_timestamp)::NUMERIC    AS delivery_days,
        r.review_score
    FROM kaggle.olist_orders o
    JOIN kaggle.olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN kaggle.olist_sellers s
        ON oi.seller_id = s.seller_id
    JOIN kaggle.olist_order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
),
seller_stats AS (
    -- One row = one seller
    SELECT
        seller_id,
        COUNT(DISTINCT order_id)                    AS total_orders,
        ROUND(AVG(delivery_days), 2)                AS avg_delivery_days,
        ROUND(AVG(review_score::NUMERIC), 2)        AS avg_review_score,
        ROUND(SUM(CASE
            WHEN order_delivered_customer_date >
                order_estimated_delivery_date
                + INTERVAL '3 days'
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*), 2)                AS breach_rate_pct
    FROM seller_orders
    GROUP BY seller_id
    HAVING COUNT(DISTINCT order_id) >= 50
)
SELECT
    seller_id,
    total_orders,
    avg_delivery_days,
    avg_review_score,
    breach_rate_pct,
    DENSE_RANK() OVER (
        ORDER BY breach_rate_pct DESC
    )                                               AS rank
FROM seller_stats
ORDER BY rank;

-- FINDING: Worst seller — 31.58% breach + 3.07 review score
--          (both speed AND quality failing simultaneously)
--          20+ sellers at 0% breach rate — model performers
--          High breach rate inversely correlates with review
--          score — proves: faster delivery = happier customers
-- INSIGHT: Breach rate is a leading indicator of review score
--          Intervening on delivery performance improves
--          customer satisfaction — causal relationship!
-- JET ACTION: Breach > 15% → automated performance warning
--             Breach > 25% → temporary suspension review
--             0% breach sellers → study their process
--             Share best practices across seller network
-- NOTE: 4-table JOIN needed — orders + items + sellers + reviews
--       HAVING on COUNT(DISTINCT order_id) for quality gate