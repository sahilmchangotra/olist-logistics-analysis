# 🚚 Logistics & Delivery Performance Analytics
## SQL Case Study | JET SODA Style | Brazilian E-Commerce

End-to-end SQL analysis of logistics and delivery performance
using the OLIST Brazilian E-Commerce dataset — mirroring the
analytical framework used by logistics operations teams at
companies like Just Eat Takeaway, Picnic and Booking.com.

---

### 📌 Project Overview
**Dataset:** OLIST Brazilian E-Commerce (Kaggle)
**Tool:** PostgreSQL
**Schema:** kaggle
**Period:** 2016-2018
**Focus:** Courier performance, SLA monitoring,
           delivery time trends, seller quality scoring

---

### 🛠️ Skills Demonstrated
| Skill | Details |
|---|---|
| INTERVAL calculations | SLA breach detection — delivered vs estimated |
| Window Functions | DENSE_RANK, rolling averages, LAG |
| Multi-table JOINs | 4-table joins for seller scorecards |
| CTEs | Multi-layer CTE chains with granularity control |
| Business Analytics | KPI design, performance flagging, trend analysis |

---

### 📂 Repository Structure
| File | Description |
|---|---|
| `sql/01_logistics_performance.sql` | SLA breach, delivery trends, seller scorecard |

---

### 💡 Key Business Findings

**SLA Breach Analysis**
- Maceio worst performer — 25% breach rate
- Northeast Brazil cities dominate worst performers
- Sao Paulo (15K orders) maintains 3.35% breach rate
- Logistics infrastructure weakest in Northeast Brazil

**Delivery Time Trend**
- Network improved 63% — 19 days (2016) → 7 days (2018)
- Feb-Mar 2018 Performance Alert — post Black Friday backlog
  overlapping with Brazilian Carnival season demand spike
- Rolling 3-month average reveals sustained pressure
  vs single month anomalies

**Seller Performance Scorecard**
- Worst seller — 31.58% breach + 3.07/5 review score
- High breach rate inversely correlates with review score
- Proves: faster delivery = higher customer satisfaction
- 20+ sellers maintain 0% breach rate — model performers

---

### 🎯 JET SODA Relevance
This analysis directly mirrors the work of JET's Global
Scoober Operations Data Analytics (SODA) team:
- SLA monitoring by courier zone
- Network performance trend analysis
- Courier/seller quality intervention scoring
- Delivery time KPI tracking for capacity planning

---

### 📁 Dataset Source
[OLIST Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
Period: September 2016 — October 2018