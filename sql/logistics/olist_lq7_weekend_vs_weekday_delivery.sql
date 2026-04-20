-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ7 -   Myntra Head of Logistics
-- Our operations team is debating whether to offer reduced staffing on weekends. Before we make that decision I need data.
-- Do orders placed on weekends take longer to deliver and have a higher late rate compared to weekday orders? Show me the
-- comparison broken down by day type — weekday vs weekend — with total orders, avg delivery days, late orders,
-- late rate percentage, and avg days from purchase to approval (to see if approval is slower on weekends).
-- Output: day_type, total_orders, avg_delivery_days, late_orders, late_rate_pct, avg_approval_days.
-- =====================================================================================================================


    SELECT
        CASE
            WHEN EXTRACT(DOW FROM order_purchase_timestamp) IN (0,6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date -
                                      order_purchase_timestamp))/86400::NUMERIC), 2) AS avg_delivery_days,
        COUNT(DISTINCT order_id) FILTER ( WHERE order_delivered_customer_date > order_estimated_delivery_date) AS late_orders,
        ROUND(COUNT(DISTINCT order_id) FILTER ( WHERE order_delivered_customer_date > order_estimated_delivery_date) * 100.0 /
             NULLIF(COUNT(DISTINCT order_id), 0), 2) AS late_rate_pct,
        ROUND(AVG(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))/86400), 2) AS avg_approval_days
    FROM olist_orders
    WHERE order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
        AND order_approved_at IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
    GROUP BY CASE
            WHEN EXTRACT(DOW FROM order_purchase_timestamp) IN (0,6) THEN 'Weekend'
            ELSE 'Weekday'
        END;