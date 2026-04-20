-- =====================================================================================================================
-- Introducing - Customer Logistics Questions
-- ✅ CQ5 - Myntra Category Analytics:
--   I need to identify our high-value customers who are showing signs of churn. Define a high-value customer as anyone
--   in the top 25% by total spend. A churning customer is someone who was active in the first half of the dataset
--   (before July 2018) but has not placed any order in the last 90 days before the dataset ends (September 1 2018).
--   Show customer_unique_id, total spend, last order date, days since last order, and value tier.
--   Output: customer_unique_id, total_spend, last_order_date, days_since_last_order, value_tier, churn_risk.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS total_spend,
        MAX(o.order_purchase_timestamp)::DATE AS last_order_date,
        ('2018-09-01'::DATE - MAX(o.order_purchase_timestamp)::DATE) AS days_since_last_order
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_customers c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
),
    quantile AS(
        SELECT
            *,
            NTILE(4) OVER (ORDER BY total_spend ASC) AS spend_quartile
        FROM order_base
    )
SELECT
    customer_unique_id,
    total_spend,
    last_order_date,
    days_since_last_order,
    'High Value' AS value_tier,
    CASE
        WHEN days_since_last_order > 180 THEN 'High Risk'
        WHEN days_since_last_order > 90 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS churn_risk
FROM quantile
WHERE spend_quartile = 4
    AND last_order_date < '2018-07-01'
    AND days_since_last_order > 90
ORDER BY days_since_last_order DESC;