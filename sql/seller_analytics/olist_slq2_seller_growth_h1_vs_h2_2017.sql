-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ2 - Myntra Seller Success:
--  I want to understand seller growth trajectories. For each seller compare their revenue in H1 2017 (Jan-Jun) vs H2 2017
--  (Jul-Dec) and show the growth rate. Flag sellers as High Growth (>50% increase), Stable (-10% to +50%),
--  Declining (>10% decrease). Only include sellers active in both halves with at least 30 orders each.
--  Output: seller_id, seller_state, h1_revenue, h2_revenue, growth_rate_pct, growth_flag."
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        SUM(oi.price + oi.freight_value) FILTER ( WHERE o.order_purchase_timestamp::DATE BETWEEN '2017-01-01' AND '2017-06-30') AS h1_2017,
        SUM(oi.price + oi.freight_value) FILTER ( WHERE o.order_purchase_timestamp::DATE BETWEEN '2017-07-01' AND '2017-12-31') AS h2_2017
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY s.seller_id, s.seller_state
    HAVING COUNT(DISTINCT o.order_id) >= 30
),
    seller_growth AS(
        SELECT
            *,
            ROUND((h2_2017 - h1_2017) * 100.0 / NULLIF(h1_2017,0),2) AS growth_rate_pct
        FROM seller_base
    )
SELECT
    seller_id,
    seller_state,
    h1_2017 AS h1_revenue,
    h2_2017 AS h2_revenue,
    growth_rate_pct,
    CASE
        WHEN growth_rate_pct > 50 THEN 'High Growth'
        WHEN growth_rate_pct < -10 THEN 'Declining'
        ELSE 'Stable'
    END AS growth_flag
FROM seller_growth
WHERE h1_2017 IS NOT NULL
    AND h2_2017 IS NOT NULL
ORDER BY growth_rate_pct DESC;