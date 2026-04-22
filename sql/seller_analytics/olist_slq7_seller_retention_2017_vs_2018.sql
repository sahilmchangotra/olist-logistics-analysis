-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ7 - BOL Category Marketing:
--  I need a seller retention analysis — which sellers were active in 2017 but stopped selling in 2018? And which new sellers
--  joined in 2018? Show churned sellers, new sellers, and retained sellers count by state.
--  Output: seller_state, retained_sellers, churned_sellers, new_sellers, churn_rate_pct, growth_rate_pct.
-- =====================================================================================================================

WITH seller_2017 AS(
    SELECT
        DISTINCT oi.seller_id,
        s.seller_state
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
),
    seller_2018 AS(
        SELECT
            DISTINCT oi.seller_id,
                     s.seller_state
        FROM olist_orders o
        JOIN olist_order_items oi
            ON o.order_id = oi.order_id
        JOIN olist_sellers s
            ON oi.seller_id = s.seller_id
        WHERE o.order_status = 'delivered'
            AND EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
    ),
    joining_sellers AS(
        SELECT
            COALESCE(y17.seller_state, y18.seller_state) AS seller_state,
            COUNT(DISTINCT CASE WHEN y18.seller_id IS NOT NULL THEN y17.seller_id END) AS retained,
            COUNT(DISTINCT CASE WHEN y18.seller_id IS NULL THEN y17.seller_id END) AS churned,
            COUNT(DISTINCT CASE WHEN y17.seller_id IS NULL THEN y18.seller_id END) AS new_sellers,
            COUNT(DISTINCT y17.seller_id) AS seller_2017
        FROM seller_2017 y17
        FULL OUTER JOIN seller_2018 y18
            ON y17.seller_id = y18.seller_id
        GROUP BY COALESCE(y17.seller_state, y18.seller_state)
    )
SELECT
    seller_state,
    retained AS retained_sellers,
    churned AS churned_sellers,
    new_sellers,
    ROUND(churned * 100.0 / NULLIF(seller_2017,0),2) AS churn_rate_pct,
    ROUND(new_sellers * 100.0 / NULLIF(seller_2017,0),2) AS growth_rate_pct
FROM joining_sellers
ORDER BY seller_2017 DESC;