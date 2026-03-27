# 🚚 Logistics & Delivery Performance Analytics
## SQL Case Study | JET SODA Style | Brazilian E-Commerce

End-to-end SQL analysis of logistics, delivery performance, seller quality, freight costs,
customer behaviour and repeat purchase patterns using the OLIST Brazilian E-Commerce dataset
(2016–2018). Framed around the analytical work of operations and marketplace analytics teams
at companies like Just Eat Takeaway (JET SODA), Picnic, and Booking.com.

**Analyst:** Sahil Changotra
**Period:** March 2026
**Database:** PostgreSQL (olist_db → kaggle schema)
**Tools:** DataGrip, VS Code, GitHub, Tableau Public

---

## 📋 Stakeholders & Business Context

| Stakeholder | Company | Focus Area |
|---|---|---|
| Carlos Mendes | ShopBrasil Revenue Analytics | SLA monitoring, seasonality, Black Friday impact |
| Emma Clarke | RetailIQ London | Delivery trends, seller performance, YoY comparisons |
| Beatriz Souza | JET SODA Senior Logistics | Freight cost efficiency, holiday season trade-offs |
| Lars Visser | JET SODA Courier Operations | Repeat purchase cohorts, weekday vs weekend behaviour |
| Sophie van Dijk | bol category marketing | Order status analysis, payment type breakdown |

These stakeholders simulate real JET SODA and BOL analytics requests — translating
business questions into SQL with measurable outcomes.

---

## 📊 Tableau Dashboard

> 🔗 **Publishing Saturday — link will be added here**

Planned dashboard views:

| Dashboard | Key Metric |
|---|---|
| SLA Breach Rate by City | Maceió 25% worst — Northeast cities dominate |
| Delivery Time Trend | 19 days (Oct 2016) → 7.29 days (Aug 2018) — 63% improvement |
| Seller Performance Scorecard | Worst seller 31.58% breach, 3.07 avg review |
| Customer Segment Distribution | VIP / Regular / Occasional — revenue + delivery quality |
| NTILE Delivery Speed Tiers | Fast tier improved, slow tier worsened after July 2017 |

---

## 🔢 Key Numerical Highlights

| Area | Finding |
|---|---|
| Delivery performance | ~92% of delivered orders arrived **early** — estimated dates were padded |
| City SLA — worst | **Maceió 25% breach rate** vs São Paulo 3.35% among large cities |
| Network improvement | Avg delivery: **19 days (Oct 2016) → 7.29 days (Aug 2018)** — 63% improvement |
| Alert periods | Feb–Mar 2018 flagged as breach alert months; late Dec 2017–Jan 2018 sustained deterioration |
| Rolling SLA spikes | 2017-09-19 spiked to **18.44% daily breach**; July 2018 recovered to ~1% |
| Seller risk | Worst seller: **31.58% SLA breach**, 3.07 avg review. 20+ sellers at 0% breach |
| Customer quality | VIP customers (>R$1,000): **0% SLA breach**, review scores above 4 |
| Top VIP customer | R$7,388 revenue, 2 orders, 5-star review, 15-day delivery |
| Freight — top category | `cama_mesa_banho`: 9,417 orders, **R$204,693 freight**, 16.49% freight share |
| Freight — highest burden | `artigos_de_natal` 26.84%, `sinalizacao_e_seguranca` 23.23%, `alimentos_bebidas` 22.90% |
| Repeat purchase rate | 30-day repeat rate mostly **1–2%** — 2018-02 best at 1.99%, 2018-08 weakest at 0.47% |
| Fastest repeat buyer | **1 day** between first and second order |
| NTILE fast tier | Improved: 4.32 days → 3.99 days after July 2017 |
| NTILE slow tier | Worsened: 24.02 → 24.21 days, review score dropped 3.77 → 3.57 |
| Payment breakdown | Credit card **~75%**, Boleto ~19%, Debit card ~1.5%, Voucher ~3.7% |

---

## 🗂️ SQL Files

| File | Business Question | Key Techniques |
|---|---|---|
| `01_sla_breach_rate_by_city.sql` | Which cities have the worst SLA performance? Min 50 orders. | INTERVAL 3 days, breach flag, DENSE_RANK, HAVING |
| `02_monthly_delivery_time_trend.sql` | Is the delivery network improving? 3-month rolling avg + alert flag. | DATE_PART, ROWS BETWEEN 2 PRECEDING, CASE flag |
| `03_seller_performance_scorecard.sql` | Which sellers cause the most delays? 4-table JOIN scorecard. | 4-table JOIN, HAVING, DENSE_RANK, INTERVAL |
| `04_freight_cost_by_category.sql` | Which categories drive the highest freight spend and burden %? | SUM/COUNT DISTINCT, freight %, RANK |
| `05_customer_scorecard.sql` | VIP / Regular / Occasional customer segmentation. Revenue, review, SLA breach per customer. | LEFT JOIN subquery, CASE segmentation, HAVING >= 2 |
| `06_repeat_buyers_lead.sql` | Customers with a second order within 30 days of first delivered order. | LEAD() before filter, PARTITION BY customer, INTERVAL 30 days |
| `07_ntile_delivery_tiers.sql` | Delivery speed tiers (NTILE 4) compared before/after July 2017. | Period flag before NTILE, raw row level, GROUP BY after NTILE |
| `08_union_all_combined.sql` | 3-part analysis: orders/revenue by status + avg delivery days + orders by payment type. | Single CTE reused 3x, NULL type casting, one ORDER BY at end |
| `bol_01_roas_by_category.sql` | Which product categories deliver best ROAS? Revenue / freight cost proxy. Min 100 orders. | SUM/NULLIF, RANK() DESC |
| `bol_02_conversion_funnel.sql` | Which categories convert customers to repeat buyers within 30 days? | MIN first order, INTERVAL 30 days, MAX CASE WHEN flag |
| `bol_03_ab_test_framework.sql` | Is the revenue difference between SP (test) and other states (control) statistically significant? | AVG, STDDEV, t-score formula, CROSS JOIN |
| `bol_04_rfm_segments.sql` | Segment customers into Champions, Loyals, At Risk, Churn using RFM scoring. | NTILE(4) R/F/M scores, MAX ref date, CASE segmentation |
| `bol_05_campaign_incrementality.sql` | Did RJ campaign lift conversion vs MG control group? Calculate lift %. | CROSS JOIN lift formula, UNION ALL 3-row output |

---

## 📝 Questions Covered

**Core Logistics (Q1–Q5)**
- Monthly orders, revenue, late delivery count with 7-day INTERVAL breach flag
- Same period last year revenue — YoY growth % using LAG(12)
- 7-day rolling average of daily orders and revenue
- Monthly seasonality — avg revenue per month across all years, ranked
- Weekday vs weekend revenue + Black Friday impact

**JET SODA Logistics (LQ1–LQ3)**
- SLA breach rate by city — Maceió 25% worst, São Paulo 3.35%
- Monthly delivery time trend + 3-month rolling avg + Performance Alert flag
- Seller performance scorecard — 4-table JOIN, worst seller 31.58% breach

**Cohort & Retention Analysis**
- 30-day repeat purchase rate by first-order cohort month (mostly 1–2%)
- Weekday vs weekend first-order cohort comparison
- Daily rolling SLA breach trend with 7-day and 30-day signals

**Revision & Gap Drilling**
- Customer VIP scorecard — total orders, revenue, avg review, SLA breach, segment
- LEAD() repeat buyer analysis — customers with 2nd order within 30 days
- NTILE(4) delivery speed tiers across time periods (before/after July 2017)
- Multi-part UNION ALL from single shared CTE (orders + delivery + payments)

**BOL Retail Media Advertising (Completed)**
- BOL Q1: ROAS by category — pcs leads at 22.62, relogios_presentes best volume+ROAS balance
- BOL Q2: Conversion funnel — eletrodomesticos best at 3.34%, overall low rates confirm 1-2% repeat finding
- BOL Q3: A/B test framework — SP t-score -15.18, statistically significant underperformance vs control
- BOL Q4: RFM segmentation — At Risk High Value (R$236 avg, 411 days gone) = top win-back target
- BOL Q5: Campaign incrementality — RJ vs MG lift +0.41%, R$207K revenue uplift

---

## 🧠 Key SQL Concepts Practiced

| Concept | Applied In |
|---|---|
| Window before filter | LEAD(), ROW_NUMBER(), NTILE() all applied before WHERE |
| Two-layer aggregation | Daily → Monthly → Market average nested CTEs |
| PERCENTILE_CONT | Separate GROUP BY CTE (PostgreSQL limitation) |
| LAG granularity | Aggregation must happen before LAG is applied |
| NTILE granularity | Never GROUP BY before NTILE — needs raw row level |
| NULL type casting | NULL::BIGINT, NULL::NUMERIC, NULL::VARCHAR in UNION ALL |
| NULLIF(col, 0) | Always defensive division — prevents divide by zero |
| COUNT DISTINCT | Always COUNT(DISTINCT order_id) when joining order_items |
| DATE_PART vs EXTRACT | DATE_PART('day', ts1-ts2) = duration vs EXTRACT(DAY FROM date) = day number |
| INTERVAL logic | INTERVAL '3 days' for SLA breach, INTERVAL '30 days' for repeat buyers |
| LEFT JOIN subquery | Collapse duplicate reviews before joining to orders |
| CASE segmentation | VIP / Regular / Occasional tier logic |

---

## 🔗 Related Projects

| Repository | Description |
|---|---|
| [online-retail-sql-analysis](https://github.com/sahilmchangotra/online-retail-sql-analysis) | Window functions, cohorts, revenue trends on UK Online Retail dataset + Tableau dashboard |
| [urbannest-rental-analytics](https://github.com/sahilmchangotra/urbannest-rental-analytics) | HousingAnywhere Italian listings — SQL + Python EDA, hypothesis testing, regression |

---

## 🎯 Target Roles

This project directly targets the analytical requirements of:
- **Data Analyst — JET SODA Amsterdam** — logistics domain, SLA monitoring, delivery analytics, cohort analysis, seller performance
- **Senior Data Analyst — BOL Retail Media Netherlands** — advertising analytics, ROAS, incrementality (BOL questions in progress)