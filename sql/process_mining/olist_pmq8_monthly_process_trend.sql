-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ8 - Myntra Head of Logistics:
-- I want a monthly trend showing all 3 process stages over time. For each month show the average days
-- for Stage 1 (Purchase→Approval), Stage 2 (Approval→Dispatch), Stage 3 (Dispatch→Delivery), and total days.
-- Add MoM change for total days using LAG. Flag each month as Faster or Slower vs previous. Also show which
-- stage was the bottleneck that month (highest avg days). This is the executive summary of our entire process
-- mining work. Output: month, avg_stage1, avg_stage2, avg_stage3, avg_total, prev_total, mom_change_days,
-- trend_flag, monthly_bottleneck.
-- =====================================================================================================================

WITH month_trend_base AS(
    SELECT
        DATE_TRUNC('month',o.order_purchase_timestamp)::DATE AS month,
        EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp))/86400 AS stage_1,
        EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at))/86400 AS stage_2,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date))/86400 AS stage_3,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400 AS delivery_days
    FROM olist_orders o
    WHERE o.order_status = 'delivered'
        AND o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
),
    aggregating AS(
        SELECT
            TO_CHAR(month,'YYYY-MM') AS month,
            ROUND(AVG(stage_1),2) AS avg_stage1,
            ROUND(AVG(stage_2),2) AS avg_stage2,
            ROUND(AVG(stage_3),2) AS avg_stage3,
            ROUND(AVG(delivery_days),2) AS avg_total
        FROM month_trend_base
        GROUP BY TO_CHAR(month,'YYYY-MM')
    ),
    month_over_month AS(
        SELECT
            *,
            LAG(avg_total) OVER (ORDER BY month) AS prev_total,
            (avg_total - LAG(avg_total) OVER (ORDER BY month)) AS mom_change_days
        FROM aggregating
    )
SELECT
    month,
    avg_stage1,
    avg_stage2,
    avg_stage3,
    avg_total,
    prev_total,
    mom_change_days,
    CASE
        WHEN avg_total > prev_total THEN 'Slower'
        ELSE 'Faster'
    END AS trend_flag,
    CASE
        WHEN avg_stage1 = GREATEST(avg_stage1,avg_stage2,avg_stage3) THEN 'Stage 1: Purchase→Approval'
        WHEN avg_stage2 = GREATEST(avg_stage1,avg_stage2,avg_stage3) THEN 'Stage 2: Approval→Dispatch'
        ELSE 'Stage 3: Dispatch→Delivery'
    END AS monthly_bottleneck
FROM month_over_month
ORDER BY month;
