-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ5 -   JET SODA Network Planning
--  I'm doing a process efficiency review across our entire order fulfilment pipeline. I need to understand exactly where
--  time is being lost at each stage of the order journey. Break the order lifecycle into three stages: Stage 1 = Purchase
--  to Approval (order_purchase_timestamp → order_approved_at), Stage 2 = Approval to Dispatch (order_approved_at →
--  order_delivered_carrier_date), Stage 3 = Dispatch to Delivery (order_delivered_carrier_date → order_delivered_customer_date).
--  For each stage show the average days, the network average, and flag any stage that takes more than 1.5x the network
--  average as a bottleneck. Output: stage_name, avg_days, network_avg, bottleneck_flag.
-- =====================================================================================================================


WITH delivery_base AS(
    SELECT
        order_id,
        EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))/86400 AS stage1_days,
        EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at))/86400 AS stage2_days,
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date))/86400 AS stage3_days
    FROM olist_db.kaggle.olist_orders
    WHERE order_status = 'delivered'
        AND order_purchase_timestamp::DATE IS NOT NULL
        AND order_approved_at::DATE IS NOT NULL
        AND order_delivered_carrier_date::DATE IS NOT NULL
        AND order_delivered_customer_date::DATE IS NOT NULL
),
    stage_avg AS(
        SELECT
            'Stage 1 - Purchase to Approval' AS stage_name,
            ROUND(AVG(stage1_days)::NUMERIC, 2) AS avg_days
        FROM delivery_base
        UNION ALL
        SELECT
            'Stage 2 - Approval to Dispatch' AS stage_name,
            ROUND(AVG(stage2_days)::NUMERIC, 2) AS avg_days
        FROM delivery_base
        UNION ALL
        SELECT
            'Stage 3 - Dispatch to Delivery' AS stage_name,
            ROUND(AVG(stage3_days)::NUMERIC, 2) AS avg_days
        FROM delivery_base
    )
SELECT
    stage_name,
    avg_days,
    ROUND(AVG(avg_days) OVER (), 2) AS network_avg,
    CASE
        WHEN avg_days > ROUND(AVG(avg_days) OVER(), 2) * 1.5
        THEN 'Bottleneck'
        ELSE 'Normal'
    END AS bottleneck_flag
FROM stage_avg
ORDER BY avg_days DESC;