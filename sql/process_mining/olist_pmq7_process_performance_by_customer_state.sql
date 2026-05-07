-- =====================================================================================================================
-- Introducing - Process Mining Questions
-- ✅ PMQ7 - Myntra Growth & Retention:
-- Delivery experience varies massively by geography. For each customer state show me: total orders,
-- average total delivery days, late delivery rate, average review score, and a composite performance score defined
-- as: (on_time_rate/100) * avg_review_score. Rank states by this composite score. Flag top 5 as Elite, bottom 5 as
-- At Risk. Only include states with at least 200 orders. Output: customer_state, total_orders, avg_delivery_days,
-- late_rate_pct, avg_review_score, composite_score, state_rank, performance_flag.
-- =====================================================================================================================

WITH customer_base AS(
    SELECT
        c.customer_state,
        o.order_id,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400 AS delivery_days,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0
        END AS is_late,
        CASE
            WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 1 ELSE 0
        END AS on_time,
        r.review_score
    FROM olist_orders o
    JOIN olist_customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score FROM olist_order_reviews GROUP BY order_id ) r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
),
    aggregating AS(
        SELECT
            customer_state,
            COUNT(DISTINCT order_id) AS total_orders,
            ROUND(AVG(delivery_days),2) AS avg_delivery_days,
            ROUND(SUM(is_late) * 100.0 / COUNT(is_late),2) AS late_rate_pct,
            ROUND(AVG(review_score),2) AS avg_review_score,
            ROUND(((SUM(on_time) * 100.0 / COUNT(on_time))/100) * AVG(review_score),2) AS composite_score
        FROM customer_base
        GROUP BY customer_state
        HAVING COUNT(DISTINCT order_id) >= 200
    ),
    ranking AS(
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY composite_score DESC) AS state_rank_desc,
            DENSE_RANK() OVER (ORDER BY composite_score ASC) AS state_rank_asc
        FROM aggregating
    )
SELECT
    customer_state,
    total_orders,
    avg_delivery_days,
    late_rate_pct,
    avg_review_score,
    composite_score,
    state_rank_desc AS state_rank,
    CASE
        WHEN state_rank_desc <= 5 THEN 'Elite'
        WHEN state_rank_asc <= 5 THEN 'At Risk'
        ELSE 'Standard'
    END AS performance_flag
FROM ranking
ORDER BY state_rank_desc;