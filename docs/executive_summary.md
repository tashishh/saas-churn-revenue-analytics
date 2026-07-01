## Key EDA Findings (Day 3)
1. **Overall churn rate: 67.8%** (339 churned / 500 total customers) — significantly high; needs plan-level investigation.
2. **Plan-level churn varies** — Enterprise and Basic plans show different churn patterns (confirm exact % from your chart).
3. **Early-tenure customers churn more** — 0–6 month customers show the highest churn rate (confirm from your tenure chart).
4. **Support ticket nulls in satisfaction scores** — 41.2% of tickets have no satisfaction rating, limiting support-churn correlation analysis.
5. **No duplicate IDs across any table** — dataset is clean and ready for star schema joins.


# Dashboard Design (Day 5)

## Page 1 – Executive Overview
- **Business question:** Is churn increasing and how much revenue is exposed?
- **Contents:** Core KPIs (customers, churn rate, MRR, revenue at risk), monthly churn trend, customer health distribution, insight text.

## Page 2 – Churn Drivers
- **Business question:** Which customer groups churn more often?
- **Contents:** Churn by plan, industry, tenure band, risk-segment table, insight text.

## Page 3 – Revenue Risk
- **Business question:** Which at-risk customers or plans carry the highest MRR exposure?
- **Contents:** MRR by plan, revenue at risk by risk segment, high-value at-risk customer table, insight text.