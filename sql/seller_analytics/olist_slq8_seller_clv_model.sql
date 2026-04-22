-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ8 - Myntra Seller Success:
-- I want to build a seller CLV model — lifetime value of each seller to the platform. Calculate total revenue generated,
-- total orders, active months, revenue per active month, and project their next 3-month revenue based on their last
-- 3-month average. Flag sellers as High CLV (top 25%), Medium CLV (25-75%) or Low CLV (bottom 25%).
-- Output: seller_id, seller_state, total_revenue, total_orders, active_months, revenue_per_month, projected_3m_revenue,
-- clv_tier.
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT DATE_TRUNC('month',o.order_purchase_timestamp)) AS active_months,
        ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT DATE_TRUNC('month',o.order_purchase_timestamp)), 2) AS revenue_per_month
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY s.seller_id, s.seller_state
),
    last_3_months AS(
        SELECT
            s.seller_id,
            ROUND(SUM(oi.price+oi.freight_value) / 3,2) AS projected_3m_revenue
        FROM olist_orders o
        JOIN olist_order_items oi
        ON o.order_id = oi.order_id
        JOIN olist_sellers s
            ON oi.seller_id = s.seller_id
        WHERE o.order_status = 'delivered'
            AND o.order_purchase_timestamp >= '2018-06-01'
        GROUP BY s.seller_id
    ),
    seller_quartiles AS(
        SELECT
            seller_id,
            seller_state,
            total_revenue,
            total_orders,
            active_months,
            revenue_per_month,
            NTILE(4) OVER (ORDER BY total_revenue ASC) AS clv_quartile
        FROM seller_base
    )
SELECT
    sq.seller_id,
    sq.seller_state,
    sq.total_revenue,
    sq.total_orders,
    sq.active_months,
    sq.revenue_per_month,
    COALESCE(l3.projected_3m_revenue,0) AS projected_3m_revenue,
    CASE
        WHEN sq.clv_quartile = 4 THEN 'High CLV'
        WHEN sq.clv_quartile IN (2, 3) THEN 'Medium CLV'
        WHEN sq.clv_quartile = 1 THEN 'Low CLV'
    END AS clv_tier,
    CASE
        WHEN projected_3m_revenue = 0 THEN 'Churned'
        WHEN projected_3m_revenue < revenue_per_month THEN 'At Risk'
        WHEN projected_3m_revenue > revenue_per_month THEN 'Growing'
        ELSE 'Stable'
    END AS seller_health
FROM seller_quartiles sq
LEFT JOIN last_3_months l3
    ON sq.seller_id = l3.seller_id
WHERE sq.total_orders >= 100
ORDER BY sq.total_revenue DESC;