-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ7 - BigBasket — Customer Analytics Interview:
-- This is from our growth team's analytics screen. We define a new customer as someone placing their very
-- first order on our platform. For each month, count how many new customers placed their first ever order,
-- the total revenue from those first orders, and the average first order value. Then rank the months by new
-- customer acquisition and flag the top 3 acquisition months. Output: month, new_customers,
-- first_order_revenue, avg_first_order_value, rank, top3_flag.
-- =====================================================================================================================

WITH first_order AS(
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
),
    first_order_revenue AS(
        SELECT
            f.customer_unique_id,
            DATE_TRUNC('month', f.first_order_date) AS first_order_month,
            SUM(oi.price + oi.freight_value) AS first_order_value
        FROM first_order f
        JOIN olist_orders o
            ON o.order_purchase_timestamp = f.first_order_date
        JOIN olist_customers c
            ON c.customer_unique_id = f.customer_unique_id
        JOIN olist_order_items oi
            ON oi.order_id = o.order_id
        GROUP BY f.customer_unique_id, DATE_TRUNC('month', f.first_order_date)
    ),
    monthly_stats AS(
        SELECT
            first_order_month,
            COUNT(DISTINCT customer_unique_id) AS new_customers,
            ROUND(SUM(first_order_value)::NUMERIC, 2) AS first_order_revenue,
            ROUND(AVG(first_order_value)::NUMERIC, 2) AS avg_first_order_value
        FROM first_order_revenue
        GROUP BY first_order_month
    ),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY new_customers DESC) AS rank
        FROM monthly_stats
    )
SELECT
    TO_CHAR(first_order_month, 'YYYY-MM') AS month,
    new_customers,
    first_order_revenue,
    avg_first_order_value,
    rank,
    CASE
        WHEN rank <= 3 THEN 'Top 3' ELSE '' END AS top3_flag
FROM ranking
ORDER BY rank, month;