-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ5 - JET SODA Network Planning:
--  I need a seller geographic concentration report. For each seller state show number of active sellers, total revenue,
--  average revenue per seller, average review score, and market share % of total platform revenue.
--  Flag states as Dominant (>20% share), Major (10-20%), Minor (5-10%) or Marginal (<5%).
--  Output: seller_state, total_sellers, total_revenue, avg_revenue_per_seller, avg_review_score, market_share_pct, state_tier."
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_state,
        COUNT(DISTINCT s.seller_id) AS total_sellers,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        ROUND(SUM(oi.price + oi.freight_value) /
              COUNT(DISTINCT s.seller_id),2) AS avg_revenue_per_seller,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score FROM olist_order_reviews GROUP BY order_id) r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_state
    HAVING COUNT(DISTINCT s.seller_id) >= 2
),
    market_share AS(
        SELECT
            *,
            ROUND(total_revenue * 100 / SUM(total_revenue) OVER (), 2) AS market_share_pct
        FROM seller_base
    )
SELECT
    seller_state,
    total_sellers,
    total_revenue,
    avg_revenue_per_seller,
    avg_review_score,
    market_share_pct,
    CASE
        WHEN market_share_pct > 20 THEN 'Dominant'
        WHEN market_share_pct BETWEEN 10 AND 20 THEN 'Major'
        WHEN market_share_pct BETWEEN 5 AND 10 THEN 'Minor'
        WHEN market_share_pct < 5 THEN 'Marginal'
    END AS state_tier
FROM market_share
ORDER BY market_share_pct DESC;