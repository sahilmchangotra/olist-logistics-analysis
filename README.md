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

## Key Numerical Highlights

- **Delivery performance:** ~**92%** of delivered OLIST orders arrived **early**, suggesting that estimated delivery dates were often padded.
- **City SLA performance:** **Maceió** had the worst breach rate at **25%**, while **São Paulo** had a much lower breach rate of **3.35%** among high-volume cities.
- **Network improvement over time:** average delivery time improved from **19 days** in **October 2016** to **7.29 days** in **August 2018**, a **63% improvement**.
- **Seller performance risk:** the worst-performing seller showed **31.58% SLA breach rate** with an average review score of **3.07**, while **20+ sellers** had **0% breach rate**.
- **Customer quality signal:** **VIP customers (>R$1000)** showed **0% SLA breach** and **review scores above 4**, making delivery quality a strong retention signal.
- **Freight cost concentration:** `cama_mesa_banho` was the most expensive freight category with **9,417 orders** and **R$204,693.04** in freight cost.
- **Other major freight-cost categories:** `beleza_saude` (**R$182,566.73**), `moveis_decoracao` (**R$172,749.30**), and `esporte_lazer` (**R$168,607.51**).
- **Highest freight burden categories:** `artigos_de_natal` (**26.84%**), `sinalizacao_e_seguranca` (**23.23%**), `alimentos_bebidas` (**22.90%**), and `eletronicos` (**22.52%**) had especially high freight as a share of total transaction value.

## Key Learnings

- Always verify the grain before calculating averages.
- Average freight per order is not the same as average freight per order item.
- Window functions are useful for trends, ranking, and rolling metrics.
- Business questions need to be translated carefully into SQL definitions.

## Next Steps

- Continue the remaining OLIST SQL practice bank
- Add time-series and BOL-style advertising questions
- Publish Tableau dashboards from selected query outputs
