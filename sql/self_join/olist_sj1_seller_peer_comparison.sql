-- =====================================================================================================================
-- Introducing - Self-JOINs Practice
-- ✅ SJ1 - Theme - Self-JOIN
-- Seller Peer Comparison | JET SODA Amsterdam | Logistics Operations:
-- I want to identify which sellers are underperforming relative to their state peers on customer
-- satisfaction. For each seller, compare their average review score to the average review score of all other
-- sellers in the same state. Show: seller_id, seller_state, seller_avg_score, state_avg_score,
-- score_difference, peer_flag (Above Average / Below Average / At Average). Only include sellers with at
-- least 20 delivered orders. Order by seller_state, score_difference descending."
-- =====================================================================================================================

WITH seller_base AS (
    SELECT
        s.seller_id,
        s.seller_state,
        ROUND(AVG(r.review_score),2) AS seller_avg,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    JOIN olist_sellers s
        ON oi.seller_id = s.seller_id
    LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score FROM olist_order_reviews GROUP BY 1) r
        ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT o.order_id) >= 20
)
SELECT
    s1.seller_id,
    s1.seller_state,
    s1.seller_avg,
    ROUND(AVG(s2.seller_avg)::NUMERIC,2) AS state_avg,
    ROUND((s1.seller_avg - AVG(s2.seller_avg)),2) AS score_difference,
    CASE
        WHEN s1.seller_avg > AVG(s2.seller_avg) + 0.1 THEN 'Above Average'
        WHEN s1.seller_avg < AVG(s2.seller_avg) - 0.1 THEN 'Below Average'
        ELSE 'At Average'
    END AS peer_flag
FROM seller_base s1
JOIN seller_base s2
    ON s1.seller_state = s2.seller_state
GROUP BY s1.seller_id, s1.seller_state , s1.seller_avg
ORDER BY s1.seller_state, score_difference DESC;

-- ============================================================
-- SJ1 FINDINGS: Seller Peer Comparison — Review Score vs State Avg
-- Self-JOIN: seller_base s1 JOIN seller_base s2 ON seller_state
-- Filter: >= 20 delivered orders per seller
-- ============================================================

-- FINDING 1: SP worst seller (2.27) poses critical platform risk
-- SP state avg: 4.10 | Worst seller: 2.27 | Gap: -1.83
-- A seller scoring 2.27 out of 5 is delivering a consistently
-- poor customer experience across a minimum of 20 orders
-- In SP — the platform's largest market — this directly damages
-- brand perception for thousands of customers
-- At -1.83 below state average this is not a bad month —
-- it is a structural quality failure
-- Threshold for platform review: any seller > 1.0 below state avg
-- SP alone has 12 sellers below -0.5 score difference
-- Immediate escalation required for sellers below 3.5 avg score

-- FINDING 2: PR seller base is highly inconsistent
-- PR state avg: 4.18
-- Best seller: 5.0 (+0.82 above avg) — perfect score at 20+ orders
-- Worst seller: 3.07 (-1.11 below avg) — among worst in dataset
-- Score range within one state: 5.0 to 3.07 = 1.93 point spread
-- This is the widest intra-state range in the dataset
-- A 5.0 seller and a 3.07 seller operating in the same state
-- under the same logistics conditions tells you the problem is
-- seller-specific (product quality, packing, communication)
-- not state-level infrastructure
-- PR needs seller-specific coaching — not a state-level fix

-- FINDING 3: Single-seller states (CE, RN) are data artefacts
-- CE: 1 qualifying seller, avg 4.59, score_difference = 0
-- RN: 1 qualifying seller, avg 4.96, score_difference = 0
-- When only one seller qualifies in a state, they join to themselves
-- AVG(s2.seller_avg) = their own score → difference always = 0
-- Both get flagged At Average regardless of actual performance
-- RN seller at 4.96 is actually one of the best in the entire
-- dataset but appears identical to CE at 4.59 in the flag column
-- Fix: add a HAVING COUNT(DISTINCT s2.seller_id) >= 3 in outer query
-- to exclude states with fewer than 3 qualifying sellers from results
-- Or add a peer_count column to flag thin state benchmarks

-- FINDING 4: MG has the most granular peer distribution
-- MG state avg: 4.15 — 100+ qualifying sellers
-- Scores range from 3.04 to 4.58 — full bell curve visible
-- This is the only state with enough sellers to make peer
-- comparison statistically meaningful at every score level
-- MG is the reference state for setting platform-wide benchmarks
-- A score of 4.15 in MG = exactly average in the largest seller pool

-- ============================================================
-- STAKEHOLDER RECOMMENDATION (Lars Visser — JET SODA):
-- 1. Flag all sellers > 0.5 below state average for review
--    SP: 12+ sellers qualify | PR: 8+ sellers qualify
--    These sellers are not noise — they are consistent underperformers
-- 2. Add peer_count to output to identify thin state benchmarks
--    CE (1 seller) and RN (1 seller) are not comparable to SP (300+)
--    State average is only meaningful with >= 5 qualifying peers
-- 3. Use PR's best seller (5.0) as a case study
--    What does the top PR seller do differently from the 3.07 seller?
--    Product category, packaging, response time, return rate
--    This comparison drives more actionable insight than state averages
-- ============================================================