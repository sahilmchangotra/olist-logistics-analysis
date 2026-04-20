-- ============================================================
-- BOL Q3: A/B Test Framework — Statistical Significance
-- Stakeholder: Daan — bol product & assortment operations
-- Business question: Did the promotion campaign generate
-- statistically significant revenue difference between
-- test and control groups?
-- Simulation: SP state = test group, all others = control group
-- Key concepts: AVG, STDDEV, t-score formula, CROSS JOIN
-- One row in base CTE = one customer
-- T-score > 1.96 = statistically significant at 95% confidence
-- ============================================================

WITH customer_base AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        o.order_id,
        oi.price,
        CASE
            WHEN c.customer_state = 'SP' THEN 'test group'
            ELSE                              'control group'
        END AS group_type
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_customers c    ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
customer_revenue AS (
-- Aggregate to one row per customer
    SELECT
        customer_unique_id,
        group_type,
        SUM(price) AS total_revenue
    FROM customer_base
    GROUP BY customer_unique_id, group_type
),
test_stats AS (
    SELECT
        AVG(total_revenue)                  AS avg_test,
        STDDEV(total_revenue)               AS sd_test,
        COUNT(DISTINCT customer_unique_id)  AS n_test
    FROM customer_revenue
    WHERE group_type = 'test group'
),
control_stats AS (
    SELECT
        AVG(total_revenue)                  AS avg_control,
        STDDEV(total_revenue)               AS sd_control,
        COUNT(DISTINCT customer_unique_id)  AS n_control
    FROM customer_revenue
    WHERE group_type = 'control group'
)
-- T-score formula: (avg_test - avg_control) / SQRT((sd_test²/n_test) + (sd_control²/n_control))
SELECT
    ROUND(t.avg_test::NUMERIC, 2)       AS avg_revenue_test,
    ROUND(c.avg_control::NUMERIC, 2)    AS avg_revenue_control,
    ROUND(t.sd_test::NUMERIC, 2)        AS stddev_test,
    ROUND(c.sd_control::NUMERIC, 2)     AS stddev_control,
    t.n_test                            AS customers_test,
    c.n_control                         AS customers_control,
    ROUND(
        (t.avg_test - c.avg_control) /
        NULLIF(
            SQRT(
                (t.sd_test ^ 2 / t.n_test) +
                (c.sd_control ^ 2 / c.n_control)
            )
        , 0)::NUMERIC
    , 2)                                AS t_score
FROM test_stats t
CROSS JOIN control_stats c;

-- Key findings:
-- T-score: -15.18 — highly statistically significant (threshold: ±1.96)
-- SP (test) avg revenue: R$129.42 — 14% LOWER than control
-- Control avg revenue: R$150.39
-- Conclusion: SP customers spend significantly less — promotion did not lift revenue
-- Action: Investigate SP market saturation or price sensitivity before next campaign