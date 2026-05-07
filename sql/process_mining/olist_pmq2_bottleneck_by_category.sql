-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ2 - JET SODA Logistics Operations:
-- I want to understand where time is being lost in the order process. For each product category, show me
-- the average time (in days) for each of the 3 stages: Stage 1 Purchase→Approval, Stage 2 Approval→Dispatch,
-- Stage 3 Dispatch→Delivery. Then flag the dominant bottleneck stage — the one that takes the most time. Also
-- show what % of total time each stage contributes. Output: category, avg_stage1, avg_stage2, avg_stage3,
-- total_avg_days, bottleneck_stage, stage1_pct, stage2_pct, stage3_pct.
-- =====================================================================================================================

WITH category_base AS(
    SELECT
        COALESCE(p.product_category_name,'Unknown') AS product_category_name,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp))/86400::NUMERIC),2) AS avg_stage1,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400::NUMERIC),2) AS avg_stage2,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date))/86400::NUMERIC),2) AS avg_stage3,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC),2) AS total_avg_days,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp))/86400::NUMERIC) * 100.0 /
              NULLIF(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC),0),2) AS stage1_pct,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400::NUMERIC) * 100.0 /
              NULLIF(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC),0),2) AS stage2_pct,
        ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date))/86400::NUMERIC) * 100.0 /
              NULLIF(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400::NUMERIC),0),2) AS stage3_pct
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_approved_at IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
    GROUP BY COALESCE(p.product_category_name,'Unknown')
)
SELECT
    product_category_name AS category,
    avg_stage1,
    avg_stage2,
    avg_stage3,
    total_avg_days,
    CASE
        WHEN avg_stage1 = GREATEST(avg_stage1, avg_stage2,avg_stage3) THEN 'Stage 1'
        WHEN avg_stage2 = GREATEST(avg_stage1, avg_stage2,avg_stage3) THEN 'Stage 2'
        ELSE 'Stage 3'
    END AS bottleneck_stage,
    stage1_pct,
    stage2_pct,
    stage3_pct
FROM category_base
ORDER BY total_avg_days DESC;