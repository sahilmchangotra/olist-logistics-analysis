-- ============================================================
-- BOL Q1: ROAS Simulation by Product Category
-- Stakeholder: Sophie van Dijk — bol category marketing
-- Business question: Which product categories deliver the best
-- return on ad spend (freight cost as proxy for ad spend)?
-- Key concepts: SUM revenue / SUM freight, NULLIF, RANK()
-- One row in base CTE = one order item
-- ============================================================

WITH order_base AS (
    SELECT
        o.order_id,
        oi.price,
        oi.freight_value,
        p.product_category_name
    FROM olist_orders o
    JOIN olist_order_items oi   ON o.order_id = oi.order_id
    JOIN olist_products p       ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
        AND p.product_category_name IS NOT NULL
),
roas_report AS (
    SELECT
        product_category_name                                       AS product_category,
        COUNT(DISTINCT order_id)                                    AS total_orders,
        ROUND(SUM(price)::NUMERIC, 2)                              AS total_revenue,
        ROUND(SUM(freight_value)::NUMERIC, 2)                      AS total_freight_cost,
        ROUND(SUM(price) /
              NULLIF(SUM(freight_value), 0)::NUMERIC, 2)           AS roas
    FROM order_base
    GROUP BY product_category_name
    HAVING COUNT(DISTINCT order_id) >= 100
)
SELECT
    product_category,
    total_orders,
    total_revenue,
    total_freight_cost,
    roas,
    RANK() OVER (ORDER BY roas DESC) AS rank
FROM roas_report
ORDER BY rank;

-- Key findings:
-- Best ROAS: pcs — 22.62 (R$218K revenue, only R$9.6K freight)
-- Worst ROAS: casa_conforto_2 — 1.85
-- Highest revenue: cama_mesa_banho — R$1,023,434 but only ROAS 5.07
-- Best volume + ROAS balance: relogios_presentes — 5,495 orders, ROAS 11.88