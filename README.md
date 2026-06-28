# SaaS Subscription Churn and Revenue Intelligence Dashboard

## Project Overview
An end-to-end BI analytics project analyzing subscription churn, monthly recurring revenue (MRR) risk,
customer usage patterns, and support burden for a fictional SaaS company called **RavenStack**.
Built to demonstrate SQL, Python, Power BI, and dashboard QA skills for Data Analyst / BI Analyst roles.

## Business Problem
RavenStack is experiencing customer churn that erodes monthly recurring revenue. Leadership needs to
identify which customer segments are most likely to churn, how much MRR is at risk, and what
retention actions should be prioritized. Usage is declining in specific segments, and support ticket
volume may be a leading indicator of churn.

## Core Business Questions
1. What is the overall churn rate and how has it trended month over month?
2. How much MRR is currently at risk from At Risk and High Value At Risk customers?
3. Which subscription plans (Basic, Pro, Enterprise) have the highest churn rates?
4. Do low-usage customers churn more than high-usage customers?
5. Does higher support ticket volume correlate with higher churn likelihood?
6. Which customer segments should be prioritized for retention action first?

## Tools Used
| Tool | Purpose |
|---|---|
| SQL Server / PostgreSQL | Data loading, cleaning views, KPI validation |
| Python + Jupyter | EDA, data profiling, metric validation, churn-risk segmentation |
| Power BI Desktop | Semantic model, DAX measures, 4-page executive dashboard |
| Git / GitHub | Version control and portfolio documentation |

## Dataset
**Source:** [SaaS Subscription & Churn Analytics Dataset — Kaggle](https://www.kaggle.com/datasets/rivalytics/saas-subscription-and-churn-analytics-dataset)
**Company Name in Data:** RavenStack (fictional)
**Type:** Synthetic data — not real customer data

| File | Description | Rows |
|---|---|---|
| ravenstack_accounts.csv | Customer account profiles | 500 |
| ravenstack_subscriptions.csv | Subscription records with MRR/ARR | 5000 |
| ravenstack_feature_usage.csv | Feature-level usage events | 25000 |
| ravenstack_support_tickets.csv | Support ticket history | 2000 |
| ravenstack_churn_events.csv | Churn event records with reason codes | 600 |

## Dashboard Pages
| Page | Business Question | Key Visuals |
|---|---|---|
| Executive Overview | Is churn increasing and how much revenue is exposed? | KPI cards, monthly churn/MRR trend, active vs churned, revenue at risk |
| Churn Drivers | Which customer groups churn more often? | Churn by plan, tenure band, usage group, support ticket group |
| Revenue Risk | Which at-risk customers carry the highest MRR exposure? | At-risk segment matrix, plan-level MRR, high-value customer table |
| Customer / QA Detail | Can analysts validate records and explain totals? | Record table, filters, KPI validation cards |

## Key KPIs
| KPI | Definition |
|---|---|
| Active Customers | Accounts where churnflag = 'False' in accounts table |
| Churned Customers | Accounts with a record in churn_events table |
| Churn Rate | Churned Customers / (Active + Churned Customers) |
| MRR | SUM(mrramount) from subscriptions where churnflag = 'False' AND istrial = 'False' |
| ARPU | MRR / Active Customers |
| Revenue at Risk | MRR from customers in At Risk or High Value At Risk segments |
| Support Ticket Rate | Total tickets / Active Customers × 100 |

## Repository Structure
saas-churn-revenue-analytics/
  data/raw/           ← original Kaggle CSVs (never edited)
  data/processed/     ← cleaned outputs for Power BI
  sql/                ← create, clean, and KPI validation scripts
  notebooks/          ← Python EDA and validation notebook
  powerbi/            ← .pbix dashboard file
  docs/               ← data dictionary, QA checklist, executive summary
  images/             ← dashboard screenshots

## How to Reproduce
1. Download dataset from Kaggle link above → place CSVs in `data/raw/`
2. Run SQL scripts in order:
   - `sql/01_create_tables.sql`
   - `sql/02_cleaning_views.sql`
   - `sql/03_kpi_validation.sql`
3. Open `notebooks/saas_churn_eda_quality_checks.ipynb` and run all cells
4. Open `powerbi/SaaS_Churn_Revenue_Dashboard.pbix` in Power BI Desktop

## Status
🚧 In Progress — Day 1 of 7