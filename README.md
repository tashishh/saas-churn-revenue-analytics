# SaaS Subscription Churn and Revenue Intelligence Dashboard

## Project Overview

This project analyzes a synthetic SaaS subscription and churn dataset to help a fictional subscription business understand where churn is happening, how much monthly recurring revenue (MRR) is at risk, and which customer groups should be prioritized for retention actions. The focus is on subscription analytics, revenue intelligence, churn analysis, and dashboard QA, not on e-commerce or mobility use cases.

The core business question is: **Which customer groups are most likely to churn, how much MRR is at risk, and what should the business do first?**

## Tools Used

- SQL Server (or MySQL) for data loading, cleaning, star-schema modeling, and source-of-truth KPI queries  
- Python (pandas, Jupyter Notebook) for data profiling, EDA, and KPI validation  
- Power BI for semantic model, DAX measures, and executive dashboard pages  
- Git and GitHub for version control and project documentation

## Dataset

- **Name:** Ravenstack SaaS Subscription and Churn Analytics Dataset (synthetic)  
- **Source:** Kaggle – SaaS Subscription and Churn Analytics Dataset  
- **Link:** https://www.kaggle.com/datasets/rivalytics/saas-subscription-and-churn-analytics-dataset  

Key CSV files used in this project:

- `ravenstack_accounts.csv`  
- `ravenstack_subscriptions.csv`  
- `ravenstack_feature_usage.csv`  
- `ravenstack_support_tickets.csv`  
- `ravenstack_churn_events.csv`  

This dataset is synthetic and does **not** represent real customer data.

## Planned Dashboard Pages

1. **Executive Overview** – high-level KPIs (Active Customers, Churned Customers, Churn Rate, MRR, ARPU, Revenue at Risk) and monthly churn / MRR trends  
2. **Churn Drivers** – churn by plan, tenure band, usage level, support tickets, and customer segments  
3. **Revenue Risk** – MRR exposure by at-risk segments, plans, and high-value at-risk customers  
4. **Customer / QA Detail** – record-level table with filters, KPI validation cards, and QA notes for stakeholder trust

## Business Questions

1. How is overall customer churn rate trending over time for the SaaS subscription base?  
2. Which plans, regions, or customer segments exhibit the highest churn and associated MRR loss?  
3. How much monthly recurring revenue is currently at risk from customers showing churn signals or declining usage?  
4. How does customer tenure relate to churn likelihood and revenue at risk?  
5. How does support ticket volume or intensity correlate with churn outcomes and MRR loss?  
6. Which customer groups should be prioritized first for retention actions such as offers, onboarding improvements, or proactive support outreach?

## Reproducibility (High-Level)

- Load raw CSV files from Kaggle into the `data/raw/` folder (unmodified)  
- Build a clean relational / star schema in SQL before any dashboarding  
- Validate all core KPIs (Active Customers, Churned Customers, Churn Rate, MRR, ARPU, Revenue at Risk) in SQL and Python  
- Connect Power BI to the validated model and create DAX measures with a dedicated validation page  
- Document data dictionary, QA checks, assumptions, and business findings in the `docs/` folder