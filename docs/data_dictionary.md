# Data Dictionary
## RavenStack SaaS Subscription Churn Analytics

**Dataset Source:** Kaggle — rivalytics/saas-subscription-and-churn-analytics-dataset
**Company (Fictional):** RavenStack
**Data Type:** Synthetic — not real customer data
**SQL Database:** saas_churn_db

---

## Table Inventory

| File Name | Table Name (SQL) | Row Count | Primary Key | Description |
|---|---|---|---|---|
| ravenstack_accounts.csv | accounts | 500 | accountid | Customer account profiles — one row per company |
| ravenstack_subscriptions.csv | subscriptions | 5,000 | subscriptionid | Subscription records with MRR, plan, billing |
| ravenstack_support_tickets.csv | support_tickets | 2,000 | ticketid | Support ticket history linked to accounts |
| ravenstack_churn_events.csv | churn_events | 600 | churn_event_id | One row per churn event — reason, date, refund |

---

## Table: accounts (ravenstack_accounts.csv)

**Purpose:** Master customer dimension. One row per company. Central join key via accountid.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| accountid | VARCHAR(50) | Primary key | A-00bed1, A-00cac8 | Format: A-xxxxxx |
| accountname | VARCHAR(255) | Company name (fictional) | Company_306, Company_26 | Anonymized |
| industry | VARCHAR(100) | Industry vertical | Cybersecurity, HealthTech, FinTech, DevTools, EdTech | Used for segmentation |
| country | VARCHAR(50) | Country code | US, AU, DE | ISO 2-letter codes |
| signupdate | DATE | Date account was created | 2023-11-14, 2024-05-22 | Used for tenure calculation |
| referralsource | VARCHAR(50) | Acquisition channel | ads, organic, partner | Marketing attribution |
| plantier | VARCHAR(50) | Plan at account level | Basic, Pro, Enterprise | subscriptions.plantier is source of truth for current plan |
| seats | INT | Number of licensed seats | 28, 8, 5 | Volume metric |
| istrial | VARCHAR(15) | Trial account flag | True, False | String boolean — cast to BIT in SQL |
| churnflag | VARCHAR(15) | Account churned flag | True, False | String boolean — cast to BIT. TRUE = churned (110 accounts) |

**Relationships:**
- accountid → subscriptions.accountid (one-to-many)
- accountid → support_tickets.accountid (one-to-many)
- accountid → churn_events.account_id (one-to-many)

---

## Table: subscriptions (ravenstack_subscriptions.csv)

**Purpose:** Fact table for subscription records. Contains MRR, plan, and billing details.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| subscriptionid | VARCHAR(50) | Primary key | S-001561, S-0027d3 | Format: S-xxxxxx |
| accountid | VARCHAR(50) | Foreign key to accounts | A-1b7577 | |
| startdate | DATE | Subscription start date | 2024-12-12 | Used for tenure and MRR period |
| enddate | DATE | Subscription end date | 2024-06-20, NULL | NULL = active subscription (4,514 nulls in raw file, ~90.3%) |
| plantier | VARCHAR(50) | Plan level — source of truth | Basic, Pro, Enterprise | |
| seats | INT | Seats on this subscription | 6, 55 | |
| mrramount | DECIMAL(18,2) | Monthly Recurring Revenue USD | 1194.00, 0.00 | 0.00 for trials — exclude from MRR KPIs |
| istrial | VARCHAR(20) | Trial subscription flag | True, False | Exclude from all revenue KPIs |
| billingfrequency | VARCHAR(20) | Billing cycle | annual, monthly | |
| autorenewflag | VARCHAR(15) | Auto-renew enabled | True, False | False = manual renewal risk |
| subscription_status | VARCHAR(6) | Derived status | Active, Ended | Active = 4,514 rows via active flag logic; Ended = 486 rows |
| active_revenue_flag | INT | Revenue counts toward current MRR | 0, 1 | Source-of-truth filter for MRR and Revenue at Risk calculations |

**Key Notes:**
- Active, revenue-counting subscriptions: `active_revenue_flag = 1`
- Trial subscriptions: `istrial = 'True'` — mrramount will be 0.00
- **Critical:** All MRR and Revenue at Risk measures (SQL, Python, and Power BI) must filter on `active_revenue_flag = 1`. An early Power BI DAX draft omitted this filter, overstating Revenue at Risk by ~$344K (see qachecklist.md).

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
| firstresponsetimeminutes | DECIMAL(10,2) | Minutes to first response | 65.00, 58.00 | Raw CSV has typo: "minutess" — renamed in cleaning view |
| satisfactionscore | DECIMAL(10,2) | Customer satisfaction score | 3.00, 4.00, NULL | 825 nulls (41.2%) — exclude from AVG |
| escalationflag | VARCHAR(20) | Ticket was escalated | True, False | Escalated = higher churn risk |

**⚠️ Known Issue:** Raw CSV column name is `firstresponsetimeminutess` (double "s"). Renamed to `firstresponsetimeminutes` in `clean_support_tickets` view.

---

## Table: churn_events (ravenstack_churn_events.csv)

**Purpose:** Source of truth for churn dates and reasons. One row per churn event.

| Column | Data Type | Description | Sample Values | Notes |
|---|---|---|---|---|
| churn_event_id | VARCHAR(50) | Primary key | C-020446 | Format: C-xxxxxx |
| account_id | VARCHAR(50) | Foreign key to accounts | A-0cc442 | ⚠️ Uses underscore — differs from accountid in other tables; aliased in clean_churn_events view |
| churn_date | DATE | Date churn occurred | 2024-10-06 | Used for monthly churn trend |
| reason_code | VARCHAR(50) | Churn reason | pricing, features, competitor, support, unknown | 5 categories |
| refund_amount_usd | DECIMAL(18,2) | Refund issued | 0.00, 28.84 | 0.00 = no refund |
| is_reactivation | VARCHAR(20) | Customer came back | True, False | True = won-back customer |
| feedback_text | VARCHAR(1000) | Free-text feedback | "too expensive", NULL | 148 nulls (24.7%) — optional field |

**⚠️ Known Issue:** `account_id` (with underscore) must be aliased when joining to other tables that use `accountid` (no underscore).

**Note on churn counting:** This table logs 600 churn *events*, which can exceed the number of unique churned *customers* (110) because some accounts have multiple churn/reactivation cycles. The `accounts.churnflag` field (110 = True) is the source-of-truth for the Churned Customers KPI, not a distinct count of this table.

---

## Power BI Model Views

### vw_customer_dim — Column Mapping
| View Column | Source | Notes |
|---|---|---|
| accountid | accounts.accountid | Primary key |
| accountname | accounts.accountname | |
| current_plan | subscriptions.plantier (latest) | Fan-out resolved with ROW_NUMBER() OVER() |
| industry | accounts.industry | |
| churn_flag | accounts.churnflag (cast to BIT) | 1 = churned (110 accounts) |
| tenure_band | Derived from signupdate | e.g., "13-24 Months", "24+ Months" |
| risk_segment | Engineered (see below) | Healthy, Watchlist, At Risk, High Value At Risk, Churned |

### vw_subscription_facts — Column Mapping
| View Column | Source Column | Notes |
|---|---|---|
| monthly_fee | mrramount | Renamed for business readability |
| plan_name | plantier | Renamed for business readability |
| start_date | startdate | Renamed for consistency |
| end_date | enddate | NULL = active subscription |
| subscription_status | Derived | 'Active' (4,514 rows) / 'Ended' (486 rows) |
| active_revenue_flag | Derived | 1 = counts toward MRR and Revenue at Risk; 0 = excluded (trial or ended) |

---

## Engineered Features (Created in SQL / Python / DAX)

| Feature | Source Table | Logic | Created In |
|---|---|---|---|
| churn_flag (BIT) | accounts | CASE WHEN churnflag = 'True' THEN 1 ELSE 0 END | SQL Day 2 |
| tenure_months / tenure_band | accounts | DATEDIFF(month, signupdate, GETDATE()); binned into bands | SQL Day 2 |
| risk_segment | accounts + subscriptions | Healthy / Watchlist / At Risk / High Value At Risk / Churned | Python Day 3 |
| active_revenue_flag | subscriptions | 1 if subscription is active and non-trial, else 0 | SQL Day 2 |
| MRR (measure) | vw_subscription_facts | SUM(monthly_fee) WHERE active_revenue_flag = 1 | DAX Day 4, corrected Day 6 |
| Revenue at Risk (measure) | vw_subscription_facts + vw_customer_dim | SUM(monthly_fee) WHERE active_revenue_flag = 1 AND risk_segment IN ('At Risk','High Value At Risk') | DAX Day 4, corrected Day 6 |

---

## Known Data Quality Issues

| Issue | Table | Column | Action |
|---|---|---|---|
| String booleans | All tables | istrial, churnflag, autorenewflag, etc. | Cast to BIT in SQL cleaning views |
| Column name typo | support_tickets | firstresponsetimeminutess | Renamed in cleaning view |
| NULL satisfaction scores | support_tickets | satisfactionscore | 825 nulls (41.2%) — excluded from AVG |
| NULL feedback text | churn_events | feedback_text | 148 nulls (24.7%) — treated as optional |
| NULL enddate | subscriptions | enddate | 4,514 nulls (90.3%) — expected for active subscriptions by design |
| Join key name mismatch | churn_events | account_id vs accountid | Aliased in all SQL joins |
| Trial MRR = 0.00 | subscriptions | mrramount | Exclude istrial = 'True' from MRR KPIs |
| Revenue at Risk overstatement (fixed) | Power BI DAX | Revenue at Risk measure | Initial measure omitted active_revenue_flag filter, overstating risk by ~$344K; corrected Day 6 |
| Churned Customers ambiguity (fixed) | churn_events vs accounts | churn count definition | Standardized on accounts.churnflag (110), not distinct churn_events count (previously miscited as 339) |

---

## Assumptions and Limitations

- All data is synthetic — do not present as real business data
- `churnflag = 'True'` in accounts is the primary churn indicator (110 churned accounts); churn_events provides date and reason detail for those churns
- MRR and Revenue at Risk are calculated from `subscriptions.mrramount` (renamed `monthly_fee`) filtered to `active_revenue_flag = 1` only
- Churn Rate denominator = Total Customers (500); Churn Rate = 110 / 500 = 22%
- Tenure measured from `accounts.signupdate` to current date (GETDATE()) for active accounts
- Plan tier source of truth = `subscriptions.plantier` (accounts.plantier may lag upgrades/downgrades)