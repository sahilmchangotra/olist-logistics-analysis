-- ============================================================
-- BOL Q2: Customer Conversion Funnel by Product Category
-- Stakeholder: Noor Bakker — bol performance marketing
-- Business question: Which categories convert browsers into
-- repeat buyers within 30 days of first purchase?
-- Key concepts: MIN first order date per category, INTERVAL 30 days,
-- MAX(CASE WHEN) conversion flag, conversion rate %
-- One row in base CTE = one customer + category combination
-- ============================================================

WITH customer_category_first_order AS (
-- Step 1: Find each customer's first order date per category
    SELECT
        c.customer_unique_id,
        p.product_category_name,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM olist_orders o
    JOIN olist_order_items oi   ON o.order_id = oi.order_id
    JOIN olist_products p       ON oi.product_id = p.product_id
    JOIN olist_customers c      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND p.product_category_name IS NOT NULL
    GROUP BY c.customer_unique_id, p.product_category_name
),
customer_all_orders AS (
-- Step 2: All delivered order dates per customer
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp AS any_order_date
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
conversion_base AS (
-- Step 3: Check if customer returned within 30 days
    SELECT
        cf.customer_unique_id,
        cf.product_category_name,
        cf.first_order_date,
        MAX(CASE
            WHEN ao.any_order_date > cf.first_order_date
            AND  ao.any_order_date <= cf.first_order_date + INTERVAL '30 days'
            THEN 1 ELSE 0
        END) AS converted
    FROM customer_category_first_order cf
    JOIN customer_all_orders ao
        ON cf.customer_unique_id = ao.customer_unique_id
    GROUP BY cf.customer_unique_id, cf.product_category_name, cf.first_order_date
)
-- Step 4: Aggregate by category
SELECT
    product_category_name,
    COUNT(DISTINCT customer_unique_id)                                  AS total_customers,
    SUM(converted)                                                      AS converted_customers,
    ROUND(SUM(converted) * 100.0 /
          NULLIF(COUNT(DISTINCT customer_unique_id), 0)::NUMERIC, 2)   AS conversion_rate_pct,
    RANK() OVER (
        ORDER BY ROUND(SUM(converted) * 100.0 /
                 NULLIF(COUNT(DISTINCT customer_unique_id), 0)::NUMERIC, 2) DESC
    )                                                                   AS rank
FROM conversion_base
GROUP BY product_category_name
HAVING COUNT(DISTINCT customer_unique_id) >= 100
ORDER BY rank;

-- Key findings:
-- Best converting: eletrodomesticos — 3.34% conversion rate
-- cama_mesa_banho: 9,008 customers, 2.33% — high volume + decent conversion
-- Worst: construcao_ferramentas_seguranca — 0% conversion
-- Overall low rates (0-3.34%) consistent with OLIST 1-2% repeat purchase finding