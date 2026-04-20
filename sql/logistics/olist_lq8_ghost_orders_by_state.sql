-- =====================================================================================================================
-- Introducing - Logistics Operations
-- ✅ LQ8 -   JET SODA Network Planning
--  I've been hearing complaints from our carrier partners about orders sitting in seller warehouses for days after approval
--  before being handed over. I'm calling these 'ghost orders' — orders that were approved but took more than 3 days to be
--  dispatched to the carrier. I need to know how widespread this problem is. Show me the ghost order rate by seller state —
--  total approved orders, ghost orders (approval to dispatch > 3 days), ghost rate %, and average approval-to-dispatch days.
--  Only include states with at least 50 orders. Rank worst to best. Output: seller_state, total_orders, ghost_orders,
--  ghost_rate_pct, avg_dispatch_days, rank.
-- =====================================================================================================================

WITH order_base AS (SELECT s.seller_state,
                           COUNT(DISTINCT o.order_id)                                            AS total_orders,
                           COUNT(DISTINCT o.order_id)
                           FILTER ( WHERE EXTRACT(EPOCH FROM (o.order_delivered_carrier_date -
                                                              o.order_approved_at)) / 86400 > 3) AS ghost_orders,
                           ROUND(COUNT(DISTINCT o.order_id)
                                 FILTER ( WHERE EXTRACT(EPOCH FROM (o.order_delivered_carrier_date -
                                                                    o.order_approved_at)) / 86400 > 3) * 100.0 /
                                 NULLIF(COUNT(DISTINCT o.order_id), 0), 2)                       AS ghost_rate_pct,
                           ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at)) /
                                     86400 ::NUMERIC), 2)                                        AS avg_dispatch_days
                    FROM olist_orders o
                             JOIN olist_order_items oi
                                  ON o.order_id = oi.order_id
                             JOIN olist_sellers s
                                  ON oi.seller_id = s.seller_id
                    WHERE o.order_status = 'delivered'
                      AND o.order_delivered_carrier_date IS NOT NULL
                      AND o.order_approved_at IS NOT NULL
                    GROUP BY s.seller_state
                    HAVING COUNT(DISTINCT o.order_id)>= 50
                    )
SELECT
    seller_state,
    total_orders,
    ghost_orders,
    ghost_rate_pct,
    avg_dispatch_days,
    DENSE_RANK() OVER (ORDER BY ghost_rate_pct DESC) AS rank
FROM order_base
ORDER BY rank;