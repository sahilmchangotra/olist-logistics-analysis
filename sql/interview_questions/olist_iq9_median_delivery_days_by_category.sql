-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ9 - Nykaa — Analytics Engineering Interview
-- This is a classic SQL question we use to test fundamentals. Calculate the median delivery time in days for
-- each product category — but you cannot use PERCENTILE_CONT or PERCENTILE_DISC. You must
-- calculate the median manually using ROW_NUMBER and COUNT. Delivery time =
-- order_delivered_customer_date - order_purchase_timestamp in days. Output: product_category_name,
-- median_delivery_days, avg_delivery_days, total_orders. Only include categories with at least 100 orders.
-- Order by median_delivery_days DESC.
-- =====================================================================================================================

WITH delivery_times AS (SELECT p.product_category_name,
                               o.order_id,
                               EXTRACT(EPOCH FROM (o.order_delivered_customer_date -
                                                   o.order_purchase_timestamp)) / 86400 AS delivery_days
                        FROM olist_orders o
                                 JOIN olist_order_items oi
                                      ON o.order_id = oi.order_id
                                 JOIN olist_products p
                                      ON p.product_id = oi.product_id
                        WHERE o.order_status = 'delivered'
                          AND p.product_category_name IS NOT NULL
                        ),
    ranking AS(
        SELECT
            product_category_name,
            delivery_days,
            ROW_NUMBER() OVER (
                PARTITION BY product_category_name
                ORDER BY delivery_days
                ) AS rn,
            COUNT(*) OVER (PARTITION BY product_category_name) AS total_orders
        FROM delivery_times
    ),
    median_candidates AS(
        SELECT
            product_category_name,
            delivery_days,
            total_orders
        FROM ranking
        WHERE total_orders >= 100
            AND rn IN (
                FLOOR((total_orders + 1) / 2),
                CEIL((total_orders + 1) / 2)
            )
    )
SELECT
    mc.product_category_name,
    ROUND(AVG(mc.delivery_days), 2) AS median_delivery_days,
    ROUND(AVG(db.delivery_days), 2) AS avg_delivery_days,
    mc.total_orders
FROM median_candidates mc
JOIN delivery_times db
    USING (product_category_name)
GROUP BY mc.product_category_name,mc.total_orders
ORDER BY median_delivery_days DESC;