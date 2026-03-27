-- ============================================================
-- BOL Q5: Campaign Incrementality — Lift Analysis
-- Stakeholder: Daan — bol product & assortment operations
-- Business question: Did the campaign lift conversion rate in
-- the exposed group vs control group? Calculate lift %.
-- Simulation: RJ state = exposed group | MG state = control group
-- Key concepts: CROSS JOIN for lift calculation, UNION ALL for
-- 3-row output (exposed + control + lift summary row)
-- One row in base CTE = one customer
-- Lift formula: (exposed_conversion - control_conversion)
--               / control_conversion × 100
-- ============================================================

WITH customer_base AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id)::BIGINT  AS customer_orders,
        SUM(oi.price)::NUMERIC              AS customer_revenue
    FROM olist_orders o
    JOIN olist_customers c    ON o.customer_id = c.customer_id
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
        AND c.customer_state IS NOT NULL
    GROUP BY c.customer_unique_id, c.customer_state
),
exposed_group AS (
    SELECT
        'Rio de Janeiro'                                            AS group_type,
        COUNT(customer_unique_id)::BIGINT                          AS total_customers,
        SUM(customer_orders)                                       AS total_orders,
        ROUND(SUM(customer_orders) * 100.0 /
              NULLIF(COUNT(customer_unique_id), 0)::NUMERIC, 2)   AS conversion_rate_pct,
        ROUND(SUM(customer_revenue) /
              NULLIF(SUM(customer_orders), 0)::NUMERIC, 2)        AS avg_order_value,
        ROUND(SUM(customer_revenue)::NUMERIC, 2)                  AS total_revenue
    FROM customer_base
    WHERE customer_state = 'RJ'
),
controlled_group AS (
    SELECT
        'Minas Gerais'                                              AS group_type,
        COUNT(customer_unique_id)::BIGINT                          AS total_customers,
        SUM(customer_orders)                                       AS total_orders,
        ROUND(SUM(customer_orders) * 100.0 /
              NULLIF(COUNT(customer_unique_id), 0)::NUMERIC, 2)   AS conversion_rate_pct,
        ROUND(SUM(customer_revenue) /
              NULLIF(SUM(customer_orders), 0)::NUMERIC, 2)        AS avg_order_value,
        ROUND(SUM(customer_revenue)::NUMERIC, 2)                  AS total_revenue
    FROM customer_base
    WHERE customer_state = 'MG'
),
lift AS (
-- CROSS JOIN brings both groups onto one row for lift calculation
    SELECT
        ROUND(
            (e.conversion_rate_pct - c.conversion_rate_pct) * 100.0 /
            NULLIF(c.conversion_rate_pct, 0)::NUMERIC
        , 2) AS lift_pct
    FROM exposed_group e
    CROSS JOIN controlled_group c
)
-- Final output: 3 rows — exposed, control, lift summary
SELECT
    group_type,
    total_customers,
    total_orders,
    conversion_rate_pct,
    avg_order_value,
    total_revenue,
    NULL::NUMERIC           AS lift_pct
FROM exposed_group

UNION ALL

SELECT
    group_type,
    total_customers,
    total_orders,
    conversion_rate_pct,
    avg_order_value,
    total_revenue,
    NULL::NUMERIC
FROM controlled_group

UNION ALL

SELECT
    'Lift (RJ vs MG)',
    NULL::BIGINT,
    NULL::BIGINT,
    lift_pct,
    NULL::NUMERIC,
    NULL::NUMERIC,
    lift_pct
FROM lift

ORDER BY group_type;

-- Key findings:
-- RJ (exposed): 11,917 customers, conversion 103.63%, avg order R$14,248
-- MG (control): 11,001 customers, conversion 103.21%, avg order R$13,673
-- Lift: +0.41% — positive but small
-- Revenue difference: R$207,169 in favour of RJ
-- Note: conversion >100% because some customers placed multiple orders
-- Recommendation: Weigh campaign cost vs R$207K revenue uplift before full rollout