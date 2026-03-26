# 🚚 Logistics & Delivery Performance Analytics
## SQL Case Study | JET SODA Style | Brazilian E-Commerce

End-to-end SQL analysis of logistics, delivery performance, seller quality, freight costs, and customer behaviour using the OLIST Brazilian E-Commerce dataset (2016–2018). Framed around the analytical work of operations and marketplace analytics teams at companies like Just Eat Takeaway (JET SODA), Picnic, and Booking.com.

**Analyst:** Sahil Changotra
**Period:** March 2026
**Database:** PostgreSQL (olist_db → kaggle schema)
**Tools:** DataGrip, VS Code, GitHub

---

## 📋 Stakeholders & Business Context

| Stakeholder | Company | Focus Area |
|---|---|---|
| Carlos Mendes | ShopBrasil Revenue Analytics | SLA monitoring, seasonality, Black Friday impact |
| Emma Clarke | RetailIQ London | Delivery trends, seller performance, YoY comparisons |
| Beatriz Souza | JET SODA Senior Logistics | Freight cost efficiency, holiday season trade-offs |
| Lars Visser | JET SODA Courier Operations | Repeat purchase cohorts, weekday vs weekend behaviour |

These stakeholders simulate real JET SODA analytics requests — translating business questions into SQL with measurable outcomes.

---

## 📊 Key Numerical Highlights

| Area | Finding |
|---|---|
| Delivery performance | ~92% of delivered orders arrived **early** — estimated dates were padded |
| City SLA — worst | **Maceió 25% SLA breach rate** vs São Paulo 3.35% among large cities |
| Network improvement | Avg delivery time improved from **19 days (Oct 2016) → 7.29 days (Aug 2018)** — 63% improvement |
| Alert periods | Feb–Mar 2018 flagged as breach alert months; late Dec 2017–Jan 2018 sustained deterioration |
| Seller risk | Worst seller: **31.58% SLA breach**, 3.07 avg review score. 20+ sellers at 0% breach |
| Customer quality | VIP customers (>R$1,000): **0% SLA breach**, review scores above 4 |
| Freight — top category | `cama_mesa_banho`: 9,417 orders, **R$204,693 freight**, 16.49% freight share |
| Freight — highest burden | `artigos_de_natal` 26.84%, `sinalizacao_e_seguranca` 23.23%, `alimentos_bebidas` 22.90% |
| Repeat purchase rate | 30-day repeat rate mostly **1–2%** — 2018-02 best at 1.99%, 2018-08 weakest at 0.47% |
| Weekend vs weekday | Weekend first-order cohorts sometimes outperformed (e.g. 2017-01: weekend 4.14% vs weekday 2.45%) |
| SLA rolling spikes | 2017-09-19 spiked to **18.44% daily breach**; July 2018 recovered to ~1% |

---

## 🗂️ SQL Files

| File | Business Question | Key Techniques |
|---|---|---|
| `01_sla_breach_rate_by_city.sql` | Which cities have the worst SLA performance? Min 50 orders. | INTERVAL 3 days, breach flag, DENSE_RANK, HAVING |
| `02_monthly_delivery_time_trend.sql` | Is the delivery network improving? Show 3-month rolling avg + alert flag. | DATE_PART, ROWS BETWEEN 2 PRECEDING, CASE flag |
| `03_seller_performance_scorecard.sql` | Which sellers cause the most delays? 4-table JOIN scorecard. | 4-table JOIN, HAVING, DENSE_RANK, INTERVAL |
| `04_freight_cost_by_category.sql` | Which categories drive the highest freight spend and burden %? | SUM/COUNT DISTINCT, freight %, RANK |
| `05_revision_and_gap_queries.sql` | Repeat buyers, NTILE delivery tiers, UNION ALL 3-part analysis, customer scorecard | LEAD(), NTILE, UNION ALL, period flags, CASE segmentation |
| `06_cohort_analysis.sql` | 30-day repeat purchase rate by first-order cohort month. Weekday vs weekend split. | LAG, INTERVAL 30 days, DATE_TRUNC, cohort logic |
| `07_rolling_sla_breach_daily.sql` | Daily SLA breach %, 7-day and 30-day rolling avg, worsening vs improving signal. | ROWS BETWEEN 6 PRECEDING, 29 PRECEDING, signal flag |

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
- LEAD() repeat buyer analysis — customers with 2nd order within 30 days
- NTILE delivery speed tiers across time periods (before/after mid-2017)
- Multi-part UNION ALL from single shared CTE (orders + delivery + payments)
- Customer VIP scorecard — total orders, revenue, avg review, late delivery rate, segment (VIP/Regular/Occasional)

**Pending — BOL Retail Media**
- ROAS simulation by product category
- Customer conversion funnel — 30-day window
- A/B test framework — revenue significance in SQL
- RFM segments + promotion response rates
- Campaign incrementality — exposed vs control lift

---

## 🧠 Key SQL Concepts Practiced

| Concept | Applied In |
|---|---|
| Window before filter rule | LEAD(), ROW_NUMBER(), NTILE() all applied before WHERE |
| Two-layer aggregation | Daily→Monthly→Market average nested CTEs |
| PERCENTILE_CONT | Separate GROUP BY CTE (PostgreSQL limitation) |
| LAG granularity | Aggregation must happen before LAG is applied |
| NTILE granularity | Never GROUP BY before NTILE — needs raw row level |
| NULL handling | NULLIF(denominator, 0), NULLS LAST, NULL::NUMERIC casting |
| COUNT DISTINCT | Always COUNT(DISTINCT order_id) when joining order_items |
| DATE_PART vs EXTRACT | DATE_PART('day', ts1-ts2) = duration vs EXTRACT(DAY FROM date) = day number |
| INTERVAL logic | INTERVAL '3 days' for SLA breach, INTERVAL '30 days' for repeat buyers |

---

## 🔗 Related Projects

| Repository | Description |
|---|---|
| [online-retail-sql-analysis](https://github.com/sahilmchangotra/online-retail-sql-analysis) | Window functions, cohorts, revenue trends on UK Online Retail dataset + Tableau dashboard |
| [urbannest-rental-analytics](https://github.com/sahilmchangotra/urbannest-rental-analytics) | HousingAnywhere Italian listings — SQL + Python (EDA, hypothesis testing, regression) |

---

## 🎯 Target Roles

This project directly targets the analytical requirements of:
- **Data Analyst — JET SODA (Amsterdam)** — logistics domain, SLA monitoring, delivery analytics, cohort analysis
- **Senior Data Analyst — BOL Retail Media (Netherlands)** — advertising analytics, ROAS, incrementality (BOL questions in progress)