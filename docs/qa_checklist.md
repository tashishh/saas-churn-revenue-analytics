# QA Checklist
## RavenStack SaaS Churn Analytics

---

## SQL Baseline KPIs (Day 2 — Source of Truth)

| KPI | SQL Value | Python Value | Power BI Value | Match? |
|---|---|---|---|---|
| Total Customers | 500 | TBD | TBD | — |
| Active Customers | 390 | TBD | TBD | — |
| Churned Customers | 339 | TBD | TBD | — |
| Total MRR | $10,159,608.00 | TBD | TBD | — |
| Total Subscriptions | 3,814 | TBD | TBD | — |
| Total Support Tickets | 2,000 | TBD | TBD | — |
| Total Churn Events | 539 | TBD | TBD | — |

## Known Assumptions
- Churn Rate denominator = Total Customers (500)
- Churned Customers = distinct accounts with net churn event (is_reactivation = False)
- Active Customers = accounts where churnflag = 'False' in accounts table
- Churned (339) + Active (390) > 500 because reactivated customers appear in both groups
- MRR excludes trial subscriptions (istrial = 'True') and churned subscriptions
- Total Subscriptions (3,814) is higher than 500 because accounts have multiple subscription records

## Data Quality Issues Found
| Issue | Table | Column | Resolution |
|---|---|---|---|
| String booleans | All tables | istrial, churnflag, flags | Cast to 0/1 in cleaning views |
| Column name typo | support_tickets | firstresponsetimeminutess | Renamed in clean_support_tickets view |
| NULL satisfaction scores | support_tickets | satisfactionscore | NULLs kept; excluded from AVG automatically |
| NULL feedback text | churn_events | feedback_text | NULLs kept; documented |
| Join key mismatch | churn_events | account_id vs accountid | Aliased in clean_churn_events view |
| Fan-out join duplicates | vw_customer_dim | multiple active subs per account | Fixed with ROW_NUMBER() OVER() |

"Churned Customers (339) counts distinct accounts with at least one net churn event. Active Customers (390) counts accounts where churnflag = 'False' in the accounts table. The sum of active + churned exceeds 500 because some customers reactivated after churning and are counted in both groups."