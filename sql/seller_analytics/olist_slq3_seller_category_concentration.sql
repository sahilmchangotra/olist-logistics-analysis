-- =====================================================================================================================
-- Introducing - Seller Analytics
-- ✅ SLQ3 - Myntra Growth:
--  I need a seller category concentration analysis. For each seller show how many distinct product categories they sell in,
--  their primary category (highest revenue), and what percentage of their revenue comes from their primary category.
--  Sellers heavily concentrated in one category are more vulnerable to category downturns.
--  Output: seller_id, seller_state, total_categories, primary_category, primary_category_revenue, total_revenue,
--  concentration_pct, risk_flag."
-- =====================================================================================================================

WITH seller_base AS(
    SELECT
        s.seller_id,
        s.seller_state,
        COALESCE(p.product_category_name, 'Unknown') AS category,
        SUM(oi.price + oi.freight_value) AS category_revenue,
        COUNT(DISTINCT o.order_id) AS category_orders
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    JOIN olist_products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id, s.seller_state, COALESCE(p.product_category_name, 'Unknown')
),
    seller_totals AS (
        SELECT
            seller_id,
            COUNT(*) AS total_categories,
            SUM(category_revenue) AS total_revenue,
            SUM(category_orders) AS total_orders
        FROM seller_base
        GROUP BY seller_id
    ),
    ranking AS(
        SELECT
            sb.seller_id,
            sb.seller_state,
            sb.category,
            sb.category_revenue,
            st.total_categories,
            st.total_revenue,
            st.total_orders,
            DENSE_RANK() OVER (PARTITION BY sb.seller_id ORDER BY sb.category_revenue DESC) AS rank
        FROM seller_base sb
        JOIN seller_totals st
            ON sb.seller_id = st.seller_id
    )
SELECT
    seller_id,
    seller_state,
    total_categories,
    category AS primary_category,
    category_revenue AS primary_category_revenue,
    total_revenue,
    ROUND(category_revenue * 100.0 / total_revenue, 2) AS concentration_pct,
    CASE
        WHEN category_revenue * 100.0 / total_revenue > 90 THEN 'High Risk'
        WHEN category_revenue * 100.0 / total_revenue > 70 THEN 'Low Risk'
        ELSE 'Low Risk'
    END AS risk_flag
FROM ranking
WHERE rank = 1
    AND total_orders >= 50
ORDER BY concentration_pct DESC;