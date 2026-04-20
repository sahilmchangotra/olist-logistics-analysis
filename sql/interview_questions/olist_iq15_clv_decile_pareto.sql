-- =====================================================================================================================
-- Introducing - Interview Questions
-- ✅ IQ15 - Zalando Customer Analytics Interview :
-- This is from our customer value team — it's the question we use to close every senior analyst interview. Calculate the
-- Customer Lifetime Value for each customer — total spend across all delivered orders. Then use NTILE to divide customers
-- into 10 equal buckets. Show each decile, the number of customers in it, total revenue, average CLV, and
-- most importantly — what percentage of total revenue that decile contributes.
-- We want to validate the Pareto principle — do the top 10% of customers generate 80% of revenue? Output: clv_decile,
-- customers, total_revenue, avg_clv, revenue_share_pct, cumulative_revenue_pct."
-- =====================================================================================================================


WITH customer_base AS(
    SELECT
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS clv
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
    quantile AS(
        SELECT
            *,
            NTILE(10) OVER (ORDER BY clv DESC) AS clv_decile
        FROM customer_base
    ),
    aggregating AS(
        SELECT
            clv_decile,
            COUNT(*) AS customers,
            SUM(clv) AS total_revenue,
            ROUND(AVG(clv)::NUMERIC, 2) AS avg_clv
        FROM quantile
        GROUP BY clv_decile
    )
        SELECT
           clv_decile,
           customers,
           total_revenue,
           avg_clv,
           ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share_pct,
           ROUND(SUM(total_revenue) OVER (
               ORDER BY clv_decile
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
               ) * 100.0 / SUM(total_revenue) OVER (), 2) AS cumulative_revenue_pct
        FROM aggregating
        ORDER BY clv_decile;