# Data Dictionary
## RavenStack SaaS Subscription Churn Analytics

**Dataset Source:** Kaggle — rivalytics/saas-subscription-and-churn-analytics-dataset
**Company (Fictional):** RavenStack
**Downloaded:** [Add your download date]
**Data Type:** Synthetic — not real customer data
**SQL Database:** [Add your DB name, e.g., ravenstack_db]

---

## Table Inventory

| File Name | Table Name (SQL) | Row Count | Primary Key | Description |
|---|---|---|---|---|
| ravenstack_accounts.csv | accounts | 500 | accountid | Customer account profiles — one row per company |
| ravenstack_subscriptions.csv | subscriptions | 5000 | subscriptionid | Subscription records with MRR, ARR, plan, billing |
| ravenstack_feature_usage.csv | feature_usage | 25000 | usage_id | Feature-level usage events per subscription |
| ravenstack_support_tickets.csv | support_tickets | 2000 | ticketid | Support ticket history linked to accounts |
| ravenstack_churn_events.csv | churn_events | 600 | churn_event_id | One row per churn event — reason, date, refund |

---

## Table: accounts (ravenstack_accounts.csv)

**Purpose:** Master customer dimension. One row per company. Central join key via accountid.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| accountid | VARCHAR(50) | Primary key | A-00bed1, A-00cac8 | Format: A-xxxxxx |
| accountname | VARCHAR(255) | Company name (fictional) | Company_306, Company_26 | Anonymized |
| industry | VARCHAR(100) | Industry vertical | Cybersecurity, HealthTech, FinTech | Used for segmentation |
| country | VARCHAR(50) | Country code | US, AU, DE | ISO 2-letter codes |
| signupdate | DATE | Date account was created | 2023-11-14, 2024-05-22 | Used for tenure calculation |
| referralsource | VARCHAR(50) | Acquisition channel | ads, organic, partner | Marketing attribution |
| plantier | VARCHAR(50) | Plan at account level | Basic, Pro, Enterprise | Use subscriptions.plantier as source of truth |
| seats | INT | Number of licensed seats | 28, 8, 5 | Volume metric |
| istrial | VARCHAR(15) | Trial account flag | True, False | String boolean — cast to BIT in SQL |
| churnflag | VARCHAR(15) | Account churned flag | True, False | String boolean — cast to BIT. TRUE = churned |

**Relationships:**
- accountid → subscriptions.accountid (one-to-many)
- accountid → support_tickets.accountid (one-to-many)
- accountid → churn_events.account_id (one-to-one or one-to-few)

---

## Table: subscriptions (ravenstack_subscriptions.csv)

**Purpose:** Fact table for subscription records. Contains MRR, ARR, plan, billing details.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| subscriptionid | VARCHAR(50) | Primary key | S-001561, S-0027d3 | Format: S-xxxxxx |
| accountid | VARCHAR(50) | Foreign key to accounts | A-1b7577 | |
| startdate | DATE | Subscription start date | 2024-12-12 | Used for tenure and MRR period |
| enddate | DATE | Subscription end date | 2024-06-20, NULL | NULL = still active |
| plantier | VARCHAR(50) | Plan level — source of truth | Basic, Pro, Enterprise | |
| seats | INT | Seats on this subscription | 6, 55 | |
| mrramount | DECIMAL(18,2) | Monthly Recurring Revenue USD | 1194.00, 0.00 | 0.00 for trials — exclude from MRR KPIs |
| arramount | DECIMAL(18,2) | Annual Recurring Revenue USD | 14328.00 | ARR = MRR × 12 |
| istrial | VARCHAR(20) | Trial subscription flag | True, False | Exclude from all revenue KPIs |
| upgradeflag | VARCHAR(20) | Was an upgrade | True, False | |
| downgradeflag | VARCHAR(20) | Was a downgrade | True, False | Downgrade may predict churn |
| churnflag | VARCHAR(20) | Subscription is churned | True, False | Active = False + NULL enddate |
| billingfrequency | VARCHAR(20) | Billing cycle | annual, monthly | |
| autorenewflag | VARCHAR(15) | Auto-renew enabled | True, False | False = manual renewal risk |

**Key Notes:**
- Active subscriptions: churnflag = 'False' AND enddate IS NULL
- Trial subscriptions: istrial = 'True' — mrramount will be 0.00

---

## Table: feature_usage (ravenstack_feature_usage.csv)

**Purpose:** Granular feature usage events. Used to calculate usage intensity per customer.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| usage_id | VARCHAR(50) | Primary key | U-0000eb | Format: U-xxxxxx |
| subscription_id | VARCHAR(50) | Foreign key to subscriptions | S-5a2a05 | |
| usage_date | DATE | Date of usage event | 2023-08-14 | Use for monthly aggregation |
| feature_name | VARCHAR(255) | Feature used | feature_15, feature_5 | Anonymized |
| usage_count | INT | Times feature used in session | 7, 12 | Aggregate for usage_group |
| usage_duration_secs | INT | Time on feature in seconds | 840, 3252 | Divide by 60 for minutes |
| error_count | INT | Errors encountered | 0, 3 | High errors may signal churn risk |
| is_beta_feature | VARCHAR(20) | Beta feature flag | True, False | Segment power users |

**Key Notes:**
- Aggregate by subscription_id per month for total usage_count
- usage_group (Low/Medium/High) engineered from monthly totals in Python Day 3

---

## Table: support_tickets (ravenstack_support_tickets.csv)

**Purpose:** Support ticket history. Used to calculate support burden and test churn correlation.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| ticketid | VARCHAR(50) | Primary key | T-000c31 | Format: T-xxxxxx |
| accountid | VARCHAR(50) | Foreign key to accounts | A-3ce5b8 | |
| submittedat | DATETIME | Ticket submission timestamp | 2024-04-05 00:00:00 | |
| closedat | DATETIME | Resolution timestamp | 2024-04-05 21:00:00 | NULL if still open |
| resolutiontimehours | DECIMAL(10,2) | Hours to resolve | 21.00, 67.00 | |
| priority | VARCHAR(20) | Priority level | urgent, high, medium | |
| firstresponsetimeminutes | DECIMAL(10,2) | Minutes to first response | 65.00, 58.00 | Raw CSV has typo: "minutess" — rename in cleaning view |
| satisfactionscore | DECIMAL(10,2) | Customer satisfaction score | 3.00, 4.00, NULL | NULLs present — exclude from AVG |
| escalationflag | VARCHAR(20) | Ticket was escalated | True, False | Escalated = higher churn risk |

**⚠️ Known Issue:** Raw CSV column name is `firstresponsetimeminutess` (double "s"). Rename to `firstresponsetimeminutes` in SQL cleaning view.

---

## Table: churn_events (ravenstack_churn_events.csv)

**Purpose:** Source of truth for churn dates and reasons. One row per churn event.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| churn_event_id | VARCHAR(50) | Primary key | C-020446 | Format: C-xxxxxx |
| account_id | VARCHAR(50) | Foreign key to accounts | A-0cc442 | ⚠️ Uses underscore — differs from accountid in other tables |
| churn_date | DATE | Date churn occurred | 2024-10-06 | Use for monthly churn trend |
| reason_code | VARCHAR(50) | Churn reason | pricing, features, competitor, support, unknown | 5 categories |
| refund_amount_usd | DECIMAL(18,2) | Refund issued | 0.00, 28.84 | 0.00 = no refund |
| preceding_upgrade_flag | VARCHAR(20) | Had upgrade before churn | True, False | |
| preceding_downgrade_flag | VARCHAR(20) | Had downgrade before churn | True, False | Downgrade → churn signal |
| is_reactivation | VARCHAR(20) | Customer came back | True, False | True = won-back — decide whether to count in net churn |
| feedback_text | VARCHAR(1000) | Free-text feedback | "too expensive", NULL | NULLs present — document count |

**⚠️ Known Issue:** `account_id` (with underscore) must be aliased when joining to other tables that use `accountid` (no underscore).

---

## Engineered Features (Created in SQL / Python)

| Feature | Source Table | Logic | Created In |
|---|---|---|---|
| churn_flag (BIT) | accounts | CASE WHEN churnflag = 'True' THEN 1 ELSE 0 END | SQL Day 2 |
| tenure_months | accounts + churn_events | DATEDIFF(month, signupdate, churn_date or GETDATE()) | SQL Day 2 |
| usage_group | feature_usage | Low / Medium / High by monthly usage_count percentile | Python Day 3 |
| risk_segment | accounts + subscriptions + feature_usage | Healthy / Watchlist / At Risk / High Value At Risk | Python Day 3 |
| revenue_at_risk | subscriptions + risk_segment | SUM(mrramount) WHERE risk_segment IN ('At Risk','High Value At Risk') | DAX Day 4 |
| support_ticket_rate | support_tickets | COUNT(ticketid) / active_customers × 100 | SQL Day 2 |

---

## Known Data Quality Issues

| Issue | Table | Column | Action |
|---|---|---|---|
| String booleans | All tables | istrial, churnflag, upgradeflag, downgradeflag, etc. | Cast to BIT in SQL cleaning views |
| Column name typo | support_tickets | firstresponsetimeminutess | Rename in cleaning view |
| NULL satisfaction scores | support_tickets | satisfactionscore | Document count; exclude from AVG |
| NULL feedback text | churn_events | feedback_text | Document count; treat as missing |
| NULL enddate | subscriptions | enddate | Expected for active subs — confirm logic |
| Join key name mismatch | churn_events | account_id vs accountid | Alias in all SQL joins |
| Trial MRR = 0.00 | subscriptions | mrramount | Exclude istrial = 'True' from MRR KPIs |
| Reactivated customers | churn_events | is_reactivation | Decide whether to include in net churn |

---

## Assumptions and Limitations

- All data is synthetic — do not present as real business data
- churnflag = 'True' in accounts is the primary churn indicator; churn_events provides date and reason detail
- MRR is calculated from subscriptions.mrramount for active, non-trial subscriptions only
- Churn Rate denominator = total unique accountids (churned + active) — document any variation
- Tenure measured from accounts.signupdate to churn_date (churned) or GETDATE() (active)
- Plan tier source of truth = subscriptions.plantier (accounts.plantier may lag upgrades/downgrades)


### vw_subscription_facts — Column Mapping
| View Column | Source Column | Notes |
|-------------|---------------|-------|
| monthly_fee | mrramount | Renamed for business readability |
| plan_name | plantier | Renamed for business readability |
| start_date | startdate | Renamed for consistency |
| end_date | enddate | NULL = active subscription |