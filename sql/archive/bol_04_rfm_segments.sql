-- ============================================================
-- BOL Q4: RFM Customer Segmentation
-- Stakeholder: Noor Bakker — bol performance marketing
-- Business question: Which customer segments should we prioritise
-- for the next promotion campaign based on RFM scoring?
-- Key concepts: NTILE(4) for R/F/M scores, period flag before NTILE,
-- MAX(order_purchase_timestamp) as reference date (NOT CURRENT_DATE)
-- One row in base CTE = one customer
-- ============================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        oi.price,
        o.order_purchase_timestamp
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_customers c    ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
),
rfm_base AS (
-- One row per customer — recency, frequency, monetary
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id)::BIGINT        AS frequency,
        SUM(price)::NUMERIC                     AS monetary,
        DATE_PART('day',
            (SELECT MAX(order_purchase_timestamp) FROM olist_orders)
            - MAX(order_purchase_timestamp)
        )::NUMERIC                              AS recency
    FROM customer_orders
    GROUP BY customer_unique_id
),
quantile_range AS (
-- Apply NTILE at raw row level — NEVER group before NTILE
-- Recency: DESC so score 4 = most recent = best
-- Monetary: DESC so score 4 = highest spend = best
-- Frequency: DESC so score 4 = most orders = best
    SELECT
        *,
        NTILE(4) OVER (ORDER BY recency  DESC) AS r_score,
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_score,
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_score
    FROM rfm_base
),
rfm_score AS (
    SELECT
        *,
        CASE
            WHEN r_score = 4 AND m_score = 4        THEN 'Champions'
            WHEN r_score >= 3 AND m_score >= 3       THEN 'Loyals'
            WHEN r_score <= 2 AND m_score >= 3       THEN 'At Risk High Value'
            WHEN r_score <= 2 AND m_score <= 2       THEN 'Churn'
            ELSE                                          'Needs Attention'
        END AS rfm_segment
    FROM quantile_range
)
SELECT
    rfm_segment,
    COUNT(customer_unique_id)           AS total_customers,
    ROUND(AVG(monetary), 2)             AS avg_revenue,
    ROUND(AVG(recency), 2)              AS avg_recency_days,
    ROUND(AVG(frequency), 2)            AS avg_frequency
FROM rfm_score
GROUP BY rfm_segment
HAVING COUNT(customer_unique_id) >= 10
ORDER BY avg_revenue DESC;

-- Key findings:
-- Champions: 5,832 customers — most recent (104 days), high spend
-- At Risk High Value: 23,131 — high revenue R$236 but 411 days since last order
-- Churn: 23,549 — low revenue R$47, 412 days gone
-- All segments show avg frequency ~1 — confirms OLIST 1-2% repeat rate
-- Campaign priority: At Risk High Value → win-back | Loyals → retain | Champions → VIP treat
-- Note: reference date = MAX(order_purchase_timestamp) not CURRENT_DATE (historical dataset rule)