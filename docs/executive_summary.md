# Executive Summary

## Key EDA Findings (Day 3 — Preliminary)

1. **Overall churn rate: 22%** (110 churned / 500 total customers). Note: an earlier draft of this EDA cited 67.8% (339/500), which was based on an incorrect DISTINCTCOUNT calculation later corrected during Power BI DAX validation (Day 6). The reconciled, source-of-truth figure is 22%.
2. **Plan-level churn varies** — Enterprise carries the highest churn volume among plans, followed by Basic and Pro (confirmed in Power BI Churn Drivers page).
3. **Tenure and churn relationship** — validated dashboard data shows customers with 24+ months tenure churn more than the 13–24 month cohort, the opposite of the initial EDA hypothesis that early-tenure customers churn most. This is flagged as a key insight: churn is not a "new customer" problem in this dataset, but a long-tenure retention issue.
4. **Support ticket nulls in satisfaction scores** — 41.2% of tickets have no satisfaction rating, limiting support-churn correlation analysis.
5. **No duplicate IDs across any table** — dataset is clean and ready for star schema joins.

## Dashboard Design (Day 5)

### Page 1 – Executive Overview
- **Business question:** Is churn increasing and how much revenue is exposed?
- **Contents:** Core KPIs (customers, churn rate, MRR, revenue at risk), monthly churn trend, customer health distribution, insight text.

### Page 2 – Churn Drivers
- **Business question:** Which customer groups churn more often?
- **Contents:** Churn by plan, industry, tenure band, risk-segment table, insight text.

### Page 3 – Revenue Risk
- **Business question:** Which at-risk customers or plans carry the highest MRR exposure?
- **Contents:** MRR by plan, revenue at risk by risk segment, high-value at-risk customer table, insight text.

## Key Findings (Validated — Day 6)

1. Churn rate stands at 22% (110 of 500 customers), a material loss rate for a SaaS business of this size.
2. Churn is accelerating — the monthly trend shows a clear upward pattern from early 2023 through late 2024.
3. Enterprise plan and DevTools industry are the highest-churn segments, with DevTools leading all industries in churn rate.
4. Long-tenure customers (24+ months) are churning more than the 13-24 month cohort, signaling possible loyalty erosion rather than early-onboarding failure.
5. Revenue risk is concentrated in a small group — the High Value At Risk segment accounts for ~$2.93M of exposed MRR, far more than the general At Risk segment.

## Recommended Actions

1. Launch a targeted retention program for High Value At Risk accounts, prioritizing outreach to the highest-MRR customers first.
2. Conduct root-cause interviews with churned Enterprise customers to identify pricing, onboarding, or support gaps.
3. Build a DevTools-specific retention playbook addressing adoption and value communication for that industry.
4. Introduce a loyalty program (renewal discounts, advanced features) targeted at customers with 24+ months tenure.
5. Embed this dashboard into recurring Customer Success reviews (monthly/QBR) to monitor churn and revenue risk continuously.