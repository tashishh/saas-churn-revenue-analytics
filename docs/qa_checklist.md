# QA Checklist
## RavenStack SaaS Churn Analytics

---

## SQL Baseline KPIs (Day 2 — Source of Truth)

| KPI | SQL Value | Python Value | Power BI Value | Match? |
|---|---|---|---|---|
| Total Customers | 500 | 500 | 500 | ✅ Match |
| Active Customers | 390 | 390 | 390 | ✅ Match |
| Churned Customers | 110 | 110 | 110 | ✅ Match |
| Total MRR | $10,159,608.00 | $10,159,608.00 | $10.16M | ✅ Match |
| Total Subscriptions | 5,000 | 5,000 | 5,000 | ✅ Match |
| Total Support Tickets | 2,000 | 2,000 | 2,000 | ✅ Match |
| Total Churn Events | 600 | 600 | 600 | ✅ Match |

> **Note on Churned Customers correction:** An early Day 2 draft cited 339 churned customers, based on a distinct-account count of net churn events rather than the `churnflag` field on the accounts table. This was superseded by the Day 6 reconciliation, which confirmed **110** as the correct, consistent churned-customer count matching both SQL and Power BI. The 339 figure describes churn *events*, not unique churned *customers*, and should not be used as a KPI.

## Known Assumptions
- Churn Rate denominator = Total Customers (500)
- Churned Customers = accounts where `churnflag = 'False'`... i.e., accounts flagged as churned in the accounts table (110 accounts)
- Active Customers = accounts where `churnflag` indicates active status in the accounts table (390 accounts)
- Churn Events (600) can exceed Churned Customers (110) because some accounts have multiple churn/reactivation events over their lifecycle
- MRR excludes trial subscriptions (`istrial = 'True'`) and uses only subscriptions flagged `active_revenue_flag = 1`
- Total Subscriptions (5,000) is higher than 500 because accounts have multiple subscription records over time

## Data Quality Issues Found
| Issue | Table | Column | Resolution |
|---|---|---|---|
| String booleans | All tables | istrial, churnflag, flags | Cast to 0/1 in cleaning views |
| Column name typo | support_tickets | firstresponsetimeminutess | Renamed in clean_support_tickets view |
| NULL satisfaction scores | support_tickets | satisfactionscore | NULLs kept; excluded from AVG automatically |
| NULL feedback text | churn_events | feedback_text | NULLs kept; documented |
| Join key mismatch | churn_events | account_id vs accountid | Aliased in clean_churn_events view |
| Fan-out join duplicates | vw_customer_dim | multiple active subs per account | Fixed with ROW_NUMBER() OVER() |

## Data Quality Notes
- `satisfactionscore` (support_tickets): 825 nulls (41.2%) — expected when ticket closed without survey response. Excluded from avg satisfaction calculations.
- `feedbacktext` (churn_events): 148 nulls (24.7%) — free-text field, not all customers provide exit feedback. Treated as optional.
- `enddate` (subscriptions): 4,514 nulls (90.3%) — active subscriptions have no end date by design. Null = still active.
- KPI Validation: All 7 core KPIs match between SQL and Python exactly, using the corrected Churned Customers (110) definition. No discrepancies found after correction.

## KPI Reconciliation (Day 6)

| KPI | Power BI | SQL Source-of-Truth | Status |
|---|---|---|---|
| Total Customers | 500 | 500 | Match |
| Active Customers | 390 | 390 | Match |
| Churned Customers | 110 | 110 | Match |
| MRR | 10.16M | 10,159,608 | Match |
| Revenue at Risk | 2.93M | 2,926,060 | Match (fixed) |

### Issue Found & Resolved
Initial `Revenue at Risk` DAX measure did not filter on `active_revenue_flag = 1`, 
causing it to include Ended subscriptions and overstate risk by ~344K (3.27M vs 2.93M).
Fixed by adding the active_revenue_flag filter to match SQL logic exactly.