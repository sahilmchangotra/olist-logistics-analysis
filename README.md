# 🚚 OLIST Logistics SQL Analysis

SQL case-study project using the OLIST Brazilian e-commerce dataset, framed around JET SODA-style logistics analytics.

## Project Overview

This repository contains stakeholder-style SQL analyses designed to simulate practical logistics and marketplace analytics work.

The questions focus on:
- SLA breach monitoring
- delivery network performance trends
- seller performance scorecards
- freight cost efficiency by product category

## Dataset and Tools

- **Dataset:** OLIST Brazilian E-Commerce
- **Database:** PostgreSQL
- **IDE:** DataGrip
- **Editor:** VS Code

## SQL Files

- `sql/01_sla_breach_rate_by_city.sql`  
  Which cities have the worst delivery SLA performance?

- `sql/02_monthly_delivery_time_trend.sql`  
  Is the delivery network improving over time?

- `sql/03_seller_performance_scorecard.sql`  
  Which sellers are causing the most delivery delays?

- `sql/04_freight_cost_by_category.sql`  
  Which product categories drive the highest freight spend?

## Key Skills Practiced

- multi-table joins
- CTEs
- interval logic
- aggregation at the correct grain
- window functions
- rolling averages
- ranking
- KPI design from business questions

## Key Learnings

- Always verify the grain before calculating averages.
- Average freight per order is not the same as average freight per order item.
- Window functions are useful for trends, ranking, and rolling metrics.
- Business questions need to be translated carefully into SQL definitions.

## Next Steps

- Continue the remaining OLIST SQL practice bank
- Add time-series and BOL-style advertising questions
- Publish Tableau dashboards from selected query outputs