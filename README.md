# 🇧🇷 OLIST Brazilian E-Commerce Analytics

**End-to-end SQL analytics portfolio | 99,441 orders | 10 question blocks | 81 questions**

Sahil Changotra · The Hague, Netherlands · 2026

[![Tableau](https://img.shields.io/badge/Tableau-Published-blue)](https://public.tableau.com/app/profile/sahil.changotra/viz/OLISTBrazilianE-CommerceAnalyticsJETSODABOL/OLISTAnalyticsJETSODABOLRetailMedia)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-DataGrip-336791)](https://github.com/sahilmchangotra/olist-logistics-analysis)
[![GitHub](https://img.shields.io/badge/Status-Complete-brightgreen)](https://github.com/sahilmchangotra/olist-logistics-analysis)

---

## 📌 What This Project Is

This repository contains 81 SQL questions across 10 analytical blocks, all written against the public OLIST Brazilian E-Commerce dataset (2016–2018). Every question is framed as a real business request from a named stakeholder at companies including **BOL.com**, **JET SODA Amsterdam**, and **Myntra** — mirroring how analytics teams actually work.

The project is structured as a portfolio of applied SQL skills rather than a collection of exercises. Each query solves a real operational or product problem, includes stakeholder context, and documents findings directly in SQL comments.

**Target roles:** Data Analyst · Product Analyst · Logistics Analyst · The Hague / Amsterdam / Netherlands

---

## 📊 Tableau Dashboard

> 🔗 **[View OLIST Analytics Dashboard on Tableau Public](https://public.tableau.com/app/profile/sahil.changotra/viz/OLISTBrazilianE-CommerceAnalyticsJETSODABOL/OLISTAnalyticsJETSODABOLRetailMedia)**

Five-story dashboard covering logistics operations, freight performance, customer segmentation, RFM retention, and campaign incrementality.

---

## 🗂️ Dataset Overview

| Field | Detail |
|---|---|
| Dataset | Brazilian E-Commerce Public Dataset by Olist (Kaggle) |
| Orders | 99,441 delivered orders |
| Period | September 2016 — August 2018 |
| Database | olist_db · kaggle schema |
| SQL Stack | PostgreSQL / DataGrip |
| Tables | olist_orders · olist_customers · olist_order_items · olist_products · olist_sellers · olist_order_payments · olist_order_reviews · olist_geolocation |

---

## ⚠️ Critical SQL Rules Applied Throughout

These rules prevent silently wrong results and are enforced in every query:

| Rule | Why |
|---|---|
| `customer_unique_id` not `customer_id` | `customer_id` changes per order — using it treats every buyer as new |
| Fan-out fix: aggregate payments + items separately | Multiple rows per order in both tables — direct join inflates SUM |
| `COUNT(DISTINCT order_id)` | Multiple items per order — raw COUNT double-counts |
| `DATE_TRUNC('month')` not `EXTRACT(MONTH)` | EXTRACT loses year — Jan 2017 = Jan 2018 |
| Window functions in CTE, filter in outer query | LAG/NTILE/ROW_NUMBER must run before WHERE |
| `1.0` not `1` for division | Integer division truncates in PostgreSQL |
| `NULLIF(denominator, 0)` | Prevents divide-by-zero errors |
| `LEFT JOIN` reviews | Not every order has a review — INNER JOIN silently drops orders |

---

## 📁 Repository Structure

```
olist-logistics-analysis/
├── sql/
│   ├── logistics/              ← LQ1–LQ8
│   ├── interview_questions/    ← IQ1–IQ8
│   ├── marketing/              ← MQ1–MQ8
│   ├── customer_analytics/     ← CQ1–CQ8
│   ├── review_quality/         ← RVQ1–RVQ8
│   ├── seller_analytics/       ← SLQ1–SLQ8
│   ├── product_growth/         ← PGQ1–PGQ10
│   ├── process_mining/         ← PMQ1–PMQ8
│   ├── mixed_practice/         ← MX1–MX10
│   └── self_join/              ← SJ1–SJ5
└── README.md
```

---

## 📦 SQL Question Blocks — Complete

### Block 1 · LQ — Logistics Operations (8 questions)
**Stakeholder:** Emma Clarke — JET SODA Amsterdam | Lars Visser — JET SODA Logistics

Questions cover delivery SLA breach by state, late delivery root cause, seller dispatch speed ranking, carrier performance by state and month, and delivery funnel analysis. Focus: identifying where the logistics network breaks down and quantifying the impact.

**Key findings:**
- MA, BA, CE states account for the majority of worst-performing late delivery months
- Q1 2018 showed platform-wide SLA failure across all 5 top seller states — root cause traced to Nov 2017 Black Friday cascade
- SP seller with 17.93-day avg dispatch is the slowest in the dataset at scale
- Stage 2→3 (delivery) is the only funnel leak — approval rate is 99.8%+ platform-wide

**Concepts:** DENSE_RANK · FILTER(WHERE) · DATE_TRUNC · INTERVAL arithmetic · HAVING · EPOCH/86400 for days

---

### Block 2 · IQ — Interview Questions (8 questions)
**Stakeholder:** BOL.com · JET SODA · Myntra (company-specific interview patterns)

SQL questions modelled on real interview questions asked at Flipkart, Amazon, BOL, JET SODA, and DHL. Covers patterns that appear repeatedly in data analyst interviews: consecutive events, daily active users, running totals, rank within groups, and lag comparison.

**Concepts:** Consecutive month detection · 7-day rolling COUNT · DENSE_RANK PARTITION BY 2 columns · LAG for YoY comparison · ROW_NUMBER gap-and-islands

---

### Block 3 · MQ — Marketing Analytics (8 questions)
**Stakeholder:** Sophie van Dijk — BOL Category Marketing | Noor Bakker — BOL Performance

Revenue analysis by category, payment type breakdown, customer acquisition funnel, MoM growth trends, and promotional lift attribution.

**Key findings:**
- beleza_saude (Health & Beauty) is the only category with consistent top-3 revenue presence across 20 months
- Nov 2017 Black Friday lifted all categories 46–92% simultaneously — not category-specific performance
- Credit card 75.3% of orders | Boleto 19.4% | Voucher ~3.7%

**Concepts:** SUM(CASE WHEN) pivot · LAG PARTITION BY category · Fan-out fix · NULLIF guard · Window pct with OVER()

---

### Block 4 · CQ — Customer Analytics (8 questions)
**Stakeholder:** Priya Sharma — Myntra Customer Analytics | Rohan Gupta — Myntra Growth

Customer acquisition funnel, MoM retention rate, RFM segmentation, cohort revenue benchmarking, and VIP customer identification.

**Key findings:**
- 30-day retention never exceeds 2% — consistent with durable goods marketplace behaviour
- Monthly churn rate: 99%+ every single month for 22 months — monthly is the wrong metric
- 90-day window reveals meaningful retention — 50% of returning customers come back after 90 days

**Concepts:** ROW_NUMBER for first order · NTILE for RFM scoring · HAVING on aggregated cohorts · DATE_TRUNC month-level retention

---

### Block 5 · RVQ — Review Quality Analytics (8 questions)
**Stakeholder:** Lars Visser — JET SODA | Daan — BOL Product

Review score distribution by category and state, seller review benchmarking, correlation between delivery performance and review scores, and identification of structurally poor-quality sellers.

**Concepts:** LEFT JOIN reviews (subquery to aggregate first) · AVG review with HAVING · PERCENTILE_CONT · Cross-dimensional analysis

---

### Block 6 · SLQ — Seller Analytics (8 questions)
**Stakeholder:** Neha Agarwal — Myntra Seller Success | Lars Visser — JET SODA

Seller revenue ranking, dispatch performance, category concentration, peer comparison within state, and seller growth trends.

**Concepts:** RANK PARTITION BY state · Fan-out fix on order_items · LEAD for MoM change · Top-N per group

---

### Block 7 · PGQ — Product & Growth Analytics (10 questions)
**Stakeholder:** Noor Bakker — BOL | Rohan Gupta — Myntra | Daan — BOL Product

The most analytically complex block. Covers MAU trends, ARPU by month, purchase funnel conversion, new vs returning revenue, churn rate, cohort retention grid, category growth MoM, payment analysis, time to second purchase, and growth accounting.

**Key findings:**
- MAU peaked at 7,183 in Nov 2017 (Black Friday) then plateaued at 6,000–7,000 through 2018
- ARPU fell ~12% as MAU grew 4x — platform acquired more users but monetised them less
- 99%+ monthly churn is expected for durable goods — monthly is wrong metric, use 90-day
- Growth accounting confirms: Retained users <1% of active base; Resurrected users are the only positive retention signal
- Cohort retention: <1% at every month offset — category effect not product failure

**Concepts:** DATE_TRUNC MAU · Fan-out fix confirmed safe for SUM · FILTER(WHERE) conditional aggregation · LAG PARTITION BY category · ROW_NUMBER for new/returning classification · Self-JOIN for churn detection · Growth accounting (New/Retained/Resurrected/Churned)

---

### Block 8 · PMQ — Process Mining (8 questions)
**Stakeholder:** Emma Clarke — JET SODA | Lars Visser — JET SODA

Order lifecycle analysis: throughput by seller state, bottleneck identification by category, process deviation detection, monthly efficiency scoring, seller dispatch speed, root cause of 1-star reviews, process performance by customer state, and monthly trend.

**Concepts:** Multi-stage funnel with FILTER · Stage-level conversion rates · Efficiency scoring formula · Date arithmetic for stage durations

---

### Block 9 · MX — Mixed Practice (10 questions)
**Stakeholder:** Emma Clarke · Lars Visser · Sophie van Dijk · Noor Bakker · Daan

Two-block structure: Logistics (MX1–MX5) and Marketing (MX6–MX10). Each question combines multiple advanced concepts — rolling windows with spike detection, PARTITION BY 2 columns, pivot tables, LEAD for trend labelling, and top-N filtering.

**Logistics findings:**
- Nov 2017 Black Friday cascade → March 2018 SLA breakdown (78.64% on-time — worst month)
- SP concentration risk: 15 of 20 top sellers in SP; single carrier disruption = platform-wide impact
- 7-day rolling avg limitation: cannot distinguish genuine spikes from holiday recovery

**Marketing findings:**
- beleza_saude dominates 12 of 20 states — platform-level concentration risk
- Debit card revenue surged 14x from Aug 2017 to Aug 2018 — financial behaviour shift post-holiday
- Consecutive seller declines (2+ months) = structural revenue loss not seasonal noise

**Concepts:** ROWS BETWEEN 6 PRECEDING · SUM(CASE WHEN) pivot · LEAD trend labelling · PARTITION BY 2 columns lesson · Revenue share with SUM() OVER · Spike flag vs rolling avg

---

### Block 10 · SJ — Self-JOIN (5 questions)
**Stakeholder:** Lars Visser · Rohan Gupta · Noor Bakker · Daan · Sophie van Dijk

Five patterns where a table is joined to itself: peer comparison, consecutive event detection, cohort benchmarking, sequential improvement tracking, and LAG alternative.

**Key findings:**
- SP worst seller scores 2.27 avg review (−1.83 below state avg) — structural customer experience failure
- Only ~370 customers in 99K ever ordered in 2 consecutive months — confirms structural one-time buyer platform
- October 2016 early adopter cohort: top customer spent 7.7x the cohort average
- Self-JOIN on large tables requires pre-aggregation — direct cross-product of 99K rows causes timeout

**Concepts:** Self-JOIN peer comparison · INTERVAL '1 month' consecutive detection · Pre-aggregated cohort benchmark · ROW_NUMBER rank-minus-1 pattern · Self-JOIN as LAG alternative · INNER JOIN for bilateral month filtering

---

## 🎯 Stakeholder Index

| Stakeholder | Company | Blocks |
|---|---|---|
| Emma Clarke | JET SODA Amsterdam — Network Planning | LQ · MX · PMQ |
| Lars Visser | JET SODA Amsterdam — Logistics Ops | LQ · RVQ · SLQ · SJ · PMQ |
| Sophie van Dijk | BOL — Category Marketing | MQ · MX · SJ |
| Noor Bakker | BOL — Performance Marketing | MQ · PGQ · CQ · SJ · MX |
| Daan | BOL — Product Operations | PGQ · PMQ · SJ · MX |
| Rohan Gupta | Myntra — Growth & Retention | PGQ · CQ · SJ |
| Priya Sharma | Myntra — Customer Analytics | CQ |
| Neha Agarwal | Myntra — Seller Success | SLQ |
| Divya Sharma | Myntra — Category Analytics | MQ |
| Karan Mehta | Myntra — Head of Logistics | LQ |

---

## 🧠 SQL Concepts Reference

| Concept | Applied In |
|---|---|
| Window functions (LAG/LEAD/RANK/DENSE_RANK/NTILE/ROW_NUMBER) | All blocks |
| ROWS BETWEEN N PRECEDING rolling windows | LQ · MX |
| SUM(CASE WHEN) pivot | MX · PGQ |
| Self-JOIN patterns (peer/consecutive/cohort/sequential) | SJ |
| Fan-out fix (pre-aggregate before JOIN) | PGQ · MQ · MX · SJ |
| Growth accounting (New/Retained/Resurrected/Churned) | PGQ10 |
| Cohort retention grid | PGQ6 |
| FILTER(WHERE) conditional aggregation | LQ · PGQ · CQ |
| PERCENTILE_CONT for median | LQ · RVQ |
| DATE_TRUNC vs EXTRACT | All blocks |
| EPOCH/86400 for dispatch days | LQ · SLQ · SJ |
| HAVING vs WHERE | All blocks |
| LEFT JOIN reviews with subquery | RVQ · SJ |
| NULLIF(denominator, 0) | All blocks |
| INTERVAL arithmetic | LQ · CQ · SJ · PGQ |

---

## 🔗 Related Portfolio Projects

| Repository | Stack | Status |
|---|---|---|
| [dataco-supply-chain-analysis](https://github.com/sahilmchangotra/dataco-supply-chain-analysis) | PostgreSQL · Tableau | ✅ Published |
| [urbannest-rental-analytics](https://github.com/sahilmchangotra/urbannest-rental-analytics) | PostgreSQL · Python · Tableau | ✅ Published |
| [nyc-taxi-analytics](https://github.com/sahilmchangotra/nyc-taxi-analytics) | Python (pandas · scipy · sklearn) | ⏳ In progress |
| [online-retail-sql-analysis](https://github.com/sahilmchangotra/online-retail-sql-analysis) | PostgreSQL · Tableau | ✅ Published |

---

## 👤 About

**Sahil Changotra** — Data Analyst · The Hague, Netherlands

Available for Data Analyst and Product Analyst roles in the Netherlands and India. Focused on logistics, e-commerce, and product analytics.

[GitHub](https://github.com/sahilmchangotra) · [Tableau Public](https://public.tableau.com/app/profile/sahil.changotra) · [LinkedIn](https://www.linkedin.com/in/sahilchangotra)