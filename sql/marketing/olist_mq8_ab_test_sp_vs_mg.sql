-- =====================================================================================================================
-- Introducing - Marketing Questions
-- ✅ MQ8 - BOL Category Marketing:
--  I want to run an A/B test framework on our two main seller states — São Paulo (SP) as test group and Minas Gerais (MG)
--  as control group. Is the revenue per order significantly different between SP and MG sellers? Calculate the mean,
--  standard deviation, sample size, t-score and interpret the result. Output: group, mean_order_value, std_dev, sample_size,
--  t_score, significant.
-- =====================================================================================================================

WITH order_base AS(
    SELECT
        s.seller_state,
        o.order_id,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON s.seller_id = oi.seller_id
    WHERE s.seller_state IN ('SP', 'MG')
        AND o.order_status = 'delivered'
    GROUP BY s.seller_state, o.order_id
),
    sp_base AS(
        SELECT
            ROUND(AVG(order_value),2) AS mean_order_value,
            STDDEV(order_value) AS std_dev,
            COUNT(*) AS n
        FROM order_base
        WHERE seller_state = 'SP'
    ),
    mg_base AS(
        SELECT
            ROUND(AVG(order_value), 2) AS mean_order_value,
            STDDEV(order_value) AS std_dev,
            COUNT(*) AS n
        FROM order_base
        WHERE seller_state = 'MG'
    ),
    ttest AS(
        SELECT
            sp.mean_order_value AS mean_sp,
            sp.std_dev AS std_sp,
            sp.n AS n_sp,
            mg.mean_order_value AS mean_mg,
            mg.std_dev AS std_mg,
            mg.n AS n_mg,
            (sp.mean_order_value - mg.mean_order_value) / SQRT((sp.std_dev^2/sp.n) + (mg.std_dev^2/mg.n)) AS t_score
        FROM sp_base sp
        CROSS JOIN mg_base mg
    )
SELECT
    'SP (Test)' AS group,
    mean_sp AS mean_order_value,
    std_sp AS std_dev,
    n_sp AS sample_size,
    ROUND(t_score::NUMERIC, 4) AS t_score,
    CASE WHEN ABS(t_score) > 1.96 THEN 'Significant' ELSE 'Not Significant' END AS result
FROM ttest

UNION ALL

SELECT
    'MG (Control)' AS group,
    mean_mg,
    std_mg,
    n_mg,
    ROUND(t_score::NUMERIC, 4),
    CASE WHEN ABS(t_score) > 1.96 THEN 'Significant' ELSE 'Not Significant' END AS result
FROM ttest;