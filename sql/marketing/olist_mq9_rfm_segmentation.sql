-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ9 - Myntra Growth Analyst:
-- I need a full RFM segmentation of our customers. Score each customer on Recency (days since last order),
-- Frequency (total orders) and Monetary (total spend) using NTILE(4). Then classify them as Champions, Loyals,
-- At Risk or Lost. Output: customer_unique_id, recency_days, frequency, monetary, r_score, f_score, m_score, rfm_segment.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        c.customer_unique_id,
        '2018-09-01'::DATE - MAX(o.order_purchase_timestamp)::DATE AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price + oi.freight_value) AS monetary
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
            NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
            NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
            NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
        FROM order_base
    ),
    segment AS(
        SELECT
            *,
            CASE
                WHEN r_score = 4 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
                WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
                WHEN r_score >= 2 AND f_score >= 2 THEN 'At Risk'
                ELSE 'Lost'
            END AS rfm_segment
        FROM quantile
    )

SELECT
    customer_unique_id,
    recency AS recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_segment
FROM segment
ORDER BY rfm_segment;