# OLIST Logistics & Commercial SQL Analysis

SQL case study using the OLIST Brazilian e-commerce dataset in PostgreSQL, framed around JET SODA-style logistics analytics and BOL-style commercial questions.

## Project Overview

This repository contains stakeholder-driven SQL analyses based on the OLIST Brazilian e-commerce dataset.

The project is designed to simulate practical analytics work in logistics and marketplace operations, including:

- delivery SLA monitoring
- seller performance analysis
- customer experience tracking
- freight cost efficiency
- category-level operational insights

## Dataset & Tools

- **Dataset:** OLIST Brazilian E-Commerce dataset
- **Database:** PostgreSQL
- **IDE:** DataGrip
- **Editor:** VS Code
- **Focus:** Logistics, marketplace operations, and commercial analytics

## SQL Topics Practiced

- multi-table joins
- aggregation and KPI design
- granularity control
- window functions
- ranking
- percentage contribution analysis
- stakeholder-style business questions

## Repository Structure

- `sql/01_delivery_performance_summary.sql`
- `sql/02_customer_scorecard.sql`
- `sql/03_seller_performance_summary.sql`
- `sql/04_freight_cost_by_category.sql`
- `sql/99_notes_and_question_bank.md`

## Key Findings

### Freight Cost by Category
- `cama_mesa_banho` has the highest total freight spend.
- Other large freight-cost categories include `beleza_saude`, `moveis_decoracao`, `esporte_lazer`, and `informatica_acessorios`.
- Furniture-related categories show especially high average freight per order.
- Some categories have a very high freight burden relative to revenue, making them candidates for delivery-fee repricing or courier renegotiation.

## Why This Project Matters

This project is built as interview-oriented practice for logistics and operations analytics roles.

It demonstrates the ability to:
- translate stakeholder questions into SQL
- choose the correct level of aggregation
- calculate operational KPIs
- summarize findings clearly for business audiences

## Next Steps

- Continue the remaining 28-question SQL practice bank
- Add Tableau dashboards from selected outputs
- Add BigQuery versions of key analyses