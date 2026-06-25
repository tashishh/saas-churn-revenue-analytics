# Data Dictionary (Draft)

## 1. Data Inventory

The following tables come from the synthetic SaaS Subscription and Churn Analytics Dataset on Kaggle (Ravenstack). All data is synthetic and does not represent real customers or real revenue.

| Table name (file)                 | Approx. row count | Business meaning                                                    | Key date columns              | Primary key candidate      |
|-----------------------------------|-------------------|---------------------------------------------------------------------|-------------------------------|----------------------------|
| ravenstack_accounts.csv           | TODO              | One row per customer account with profile, industry, geography, and base churn flag | signupdate                    | accountid                  |
| ravenstack_subscriptions.csv    | TODO              | One row per subscription with plan tier, seats, MRR/ARR, billing frequency, and churn flags | startdate, enddate           | subscriptionid             |
| ravenstack_feature_usage.csv    | TODO              | Feature usage events or periodic usage metrics per account          | TODO (e.g. usagedate)        | TODO (e.g. event id or composite key) |
| ravenstack_support_tickets.csv  | TODO              | One row per support ticket raised by accounts                       | TODO (e.g. ticketcreateddate) | TODO (ticket id)           |
| ravenstack_churn_events.csv     | TODO              | One row per churn event or subscription status change               | TODO (e.g. churndate)        | TODO (churn event id)      |

> NOTE: Replace the TODO values above with actual row counts and column names after inspecting each CSV. This is sufficient for Day 1; it will be refined on later days.

## 2. Table and Column Definitions (Draft)

### 2.1 ravenstack_accounts.csv

Short description: Account-level dimension table with one row per customer account and relatively stable profile attributes.

- **accountid** — type: string — unique identifier for each customer account.  
- **accountname** — type: string — name of the customer account (company name).  
- **industry** — type: string — industry classification (e.g., EdTech, FinTech, DevTools, HealthTech, Cybersecurity).  
- **country** — type: string — country associated with the account (e.g., US, IN, UK, CA, DE, FR, AU).  
- **signupdate** — type: date — date when the account first signed up for the SaaS product.  
- **referralsource** — type: string — how the account was acquired (e.g., partner, ads, event, organic, other).  
- **plantier** — type: string — current plan tier at the account level (e.g., Basic, Pro, Enterprise).  
- **seats** — type: integer — number of licensed seats associated with the account.  
- **istrial** — type: boolean — indicates whether the account is currently in a trial state.  
- **churnflag** — type: boolean — high-level churn indicator at account level (True if the account has churned).

### 2.2 ravenstack_subscriptions.csv

Short description: Subscription fact table that captures subscription periods, plan details, recurring revenue amounts, and churn / upgrade / downgrade flags.

- **subscriptionid** — type: string — unique identifier for each subscription record.  
- **accountid** — type: string — foreign key linking to `ravenstack_accounts.accountid`.  
- **startdate** — type: date — date when the subscription became active.  
- **enddate** — type: date — date when the subscription ended (null or blank if still active).  
- **plantier** — type: string — subscription plan tier (Basic, Pro, Enterprise).  
- **seats** — type: integer — number of seats on this subscription.  
- **mrramount** — type: numeric — monthly recurring revenue amount for this subscription.  
- **arramount** — type: numeric — annual recurring revenue amount for this subscription.  
- **istrial** — type: boolean — indicates whether this subscription is a trial.  
- **upgradeflag** — type: boolean — indicates whether this subscription reflects an upgrade action.  
- **downgradeflag** — type: boolean — indicates whether this subscription reflects a downgrade action.  
- **churnflag** — type: boolean — indicates whether this subscription is churned based on its lifecycle.  
- **billingfrequency** — type: string — billing frequency (e.g., monthly, annual).  
- **autorenewflag** — type: boolean — indicates whether the subscription is set to auto-renew.

> NOTE: Additional tables (feature usage, support tickets, churn events) will be documented in more detail in later days once the SQL model and KPIs are defined.