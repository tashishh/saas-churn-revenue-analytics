-- ============================================================
-- 02_cleaning_views.sql
-- Project : RavenStack SaaS Subscription & Churn Analytics
-- Database: saas_churn_db
-- Purpose : Layer 1 — 5 cleaning views that fix raw data issues
--           Layer 2 — 5 BI reporting views for Power BI
--           Raw tables are NEVER modified here.
-- Run order: After 01_create_tables.sql and data is loaded
-- ============================================================

USE saas_churn_db;

-- ============================================================
-- LAYER 1: CLEANING VIEWS
-- Fix string booleans, column typo, NULLs, key naming,
-- and add computed helper columns
-- ============================================================

-- ------------------------------------------------------------
-- CLEAN VIEW 1: clean_accounts
-- Fixes : string booleans → TINYINT (0/1)
-- Adds  : churn_flag (0/1), tenure_months_current
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW clean_accounts AS
SELECT
    accountid,
    accountname,
    industry,
    country,
    signupdate,
    referralsource,
    plantier,
    seats,
    CASE WHEN LOWER(istrial)   = 'true' THEN 1 ELSE 0 END   AS is_trial,
    CASE WHEN LOWER(churnflag) = 'true' THEN 1 ELSE 0 END   AS churn_flag,
    TIMESTAMPDIFF(MONTH, signupdate, CURDATE())              AS tenure_months_current
FROM ravenstack_accounts;

select * from ravenstack_accounts;
select * from clean_accounts;
-- ------------------------------------------------------------
-- CLEAN VIEW 2: clean_subscriptions
-- Fixes : string booleans → TINYINT
-- Adds  : active_revenue_flag (1 = active paid subscription)
-- Note  : active_revenue_flag = 1 means churnflag=False AND
--         istrial=False — this is your MRR source of truth
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW clean_subscriptions AS
SELECT
    subscriptionid,
    accountid,
    startdate,
    enddate,
    plantier,
    seats,
    mrramount,
    arramount,
    billingfrequency,
    CASE WHEN LOWER(istrial)       = 'true' THEN 1 ELSE 0 END  AS is_trial,
    CASE WHEN LOWER(upgradeflag)   = 'true' THEN 1 ELSE 0 END  AS upgrade_flag,
    CASE WHEN LOWER(downgradeflag) = 'true' THEN 1 ELSE 0 END  AS downgrade_flag,
    CASE WHEN LOWER(churnflag)     = 'true' THEN 1 ELSE 0 END  AS churn_flag,
    CASE WHEN LOWER(autorenewflag) = 'true' THEN 1 ELSE 0 END  AS autorenew_flag,
    CASE
        WHEN LOWER(churnflag) = 'false'
        AND  LOWER(istrial)   = 'false'
        THEN 1 ELSE 0
    END AS active_revenue_flag
FROM ravenstack_subscriptions;

select * from ravenstack_subscriptions;
select * from clean_subscriptions;

-- ------------------------------------------------------------
-- CLEAN VIEW 3: clean_feature_usage
-- Fixes : string boolean for is_beta_feature
-- Adds  : usage_duration_mins (secs / 60)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW clean_feature_usage AS
SELECT
    usage_id,
    subscription_id,
    usage_date,
    feature_name,
    usage_count,
    usage_duration_secs,
    ROUND(usage_duration_secs / 60.0, 2)                         AS usage_duration_mins,
    error_count,
    CASE WHEN LOWER(is_beta_feature) = 'true' THEN 1 ELSE 0 END  AS is_beta_feature
FROM ravenstack_feature_usage;

select * from ravenstack_feature_usage;
select * from clean_feature_usage;

-- ------------------------------------------------------------
-- CLEAN VIEW 4: clean_support_tickets
-- Fixes : renames double-s typo → firstresponsetimeminutes
--         string boolean for escalationflag
-- Adds  : is_open flag (1 = not yet closed)
-- Note  : satisfactionscore NULLs kept — AVG() ignores them
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW clean_support_tickets AS
SELECT
    ticketid,
    accountid,
    submittedat,
    closedat,
    resolutiontimehours,
    priority,
    firstresponsetimeminutess                                    AS firstresponsetimeminutes,
    satisfactionscore,
    CASE WHEN LOWER(escalationflag) = 'true' THEN 1 ELSE 0 END  AS escalation_flag,
    CASE WHEN closedat IS NULL      THEN 1 ELSE 0 END            AS is_open
FROM ravenstack_support_tickets;

select * from ravenstack_support_tickets;
select * from clean_support_tickets;

-- ------------------------------------------------------------
-- CLEAN VIEW 5: clean_churn_events
-- Fixes : renames account_id → accountid for consistent joins
--         string booleans → TINYINT
-- Note  : feedback_text NULLs kept — document in QA checklist
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW clean_churn_events AS
SELECT
    churn_event_id,
    account_id                                                              AS accountid,
    churn_date,
    reason_code,
    refund_amount_usd,
    CASE WHEN LOWER(preceding_upgrade_flag)   = 'true' THEN 1 ELSE 0 END  AS preceding_upgrade_flag,
    CASE WHEN LOWER(preceding_downgrade_flag) = 'true' THEN 1 ELSE 0 END  AS preceding_downgrade_flag,
    CASE WHEN LOWER(is_reactivation)          = 'true' THEN 1 ELSE 0 END  AS is_reactivation,
    feedback_text
FROM ravenstack_churn_events;

select * from ravenstack_churn_events;
select * from clean_churn_events;


-- ============================================================
-- LAYER 2: BI REPORTING VIEWS
-- These are what Power BI connects to directly.
-- Built on clean_ views only — never on raw tables.
-- ============================================================

-- ------------------------------------------------------------
-- BI VIEW 1: vw_customer_dim
-- Purpose : Customer dimension table for the star schema.
--           One row per account with plan, tenure, and
--           tenure_band for dashboard segmentation.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_dim AS
SELECT
    a.accountid,
    a.accountname,
    a.industry,
    a.country,
    a.signupdate,
    a.referralsource,
    a.is_trial,
    a.churn_flag,
    a.tenure_months_current,
    s.plantier              AS current_plan,
    s.seats                 AS current_seats,
    s.billingfrequency,
    s.autorenew_flag,
    CASE
        WHEN a.tenure_months_current <= 3   THEN '0-3 Months'
        WHEN a.tenure_months_current <= 6   THEN '4-6 Months'
        WHEN a.tenure_months_current <= 12  THEN '7-12 Months'
        WHEN a.tenure_months_current <= 24  THEN '13-24 Months'
        ELSE '24+ Months'
    END AS tenure_band,

    -- ✅ NEW: risk_segment based on business rules
    -- Replace the risk_segment CASE block with this:
CASE
    WHEN a.churn_flag = 1
        THEN 'Churned'
    WHEN a.churn_flag = 0 
         AND s.mrramount >= 500 
         AND a.tenure_months_current <= 24
        THEN 'High Value At Risk'
    WHEN a.churn_flag = 0 
         AND a.tenure_months_current <= 24
        THEN 'At Risk'
    WHEN a.churn_flag = 0 
         AND a.tenure_months_current <= 32
        THEN 'Watchlist'
    ELSE 'Healthy'
END AS risk_segment

FROM clean_accounts a
LEFT JOIN (
    SELECT
        accountid,
        plantier,
        seats,
        billingfrequency,
        autorenew_flag,
        startdate,
        mrramount,
        ROW_NUMBER() OVER (
            PARTITION BY accountid
            ORDER BY startdate DESC, mrramount DESC
        ) AS row_rank
    FROM clean_subscriptions
    WHERE active_revenue_flag = 1
) s
    ON  a.accountid = s.accountid
    AND s.row_rank  = 1;
    
select * from vw_customer_dim;
SELECT risk_segment, COUNT(*) AS customer_count
FROM vw_customer_dim
GROUP BY risk_segment
ORDER BY customer_count DESC;

SELECT 
    MIN(tenure_months_current) AS min_tenure,
    MAX(tenure_months_current) AS max_tenure,
    AVG(tenure_months_current) AS avg_tenure,
    COUNT(CASE WHEN tenure_months_current <= 12 THEN 1 END) AS under_12_months,
    COUNT(CASE WHEN tenure_months_current <= 24 THEN 1 END) AS under_24_months,
    COUNT(CASE WHEN churn_flag = 0 THEN 1 END) AS active_customers
FROM vw_customer_dim;

-- ------------------------------------------------------------
-- BI VIEW 2: vw_subscription_facts
-- Purpose : Subscription fact table — MRR source of truth.
--           Active, paid (non-trial) subscriptions only.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_subscription_facts AS
SELECT
    s.subscriptionid,
    s.accountid,
    s.plantier                              AS plan_name,
    s.mrramount                             AS monthly_fee,
    s.startdate                             AS start_date,
    s.enddate                               AS end_date,
    DATE_FORMAT(s.startdate, '%Y-%m')       AS start_month,
    DATE_FORMAT(s.enddate,   '%Y-%m')       AS end_month,
    s.seats,
    s.billingfrequency,
    s.autorenew_flag,
    s.active_revenue_flag,
    CASE
        WHEN s.enddate IS NULL THEN 'Active'
        ELSE 'Ended'
    END                                     AS subscription_status,
    ROUND(
        DATEDIFF(COALESCE(s.enddate, CURDATE()), s.startdate) / 30.44
    , 0)                                    AS duration_months
FROM clean_subscriptions s;
select * from vw_subscription_facts;

-- ------------------------------------------------------------
-- BI VIEW 3: vw_usage_monthly
-- Purpose : Monthly usage aggregated per account.
--           Joins feature_usage → subscriptions → account.
--           Used to build usage_group (Low/Medium/High)
--           in Python on Day 3.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_usage_monthly AS
SELECT
    u.subscription_id,
    s.accountid,
    DATE_FORMAT(u.usage_date, '%Y-%m')      AS usage_month,
    SUM(u.usage_count)                      AS total_usage_count,
    SUM(u.usage_duration_mins)              AS total_usage_mins,
    SUM(u.error_count)                      AS total_errors,
    COUNT(DISTINCT u.feature_name)          AS distinct_features_used
FROM clean_feature_usage u
JOIN clean_subscriptions s
    ON u.subscription_id = s.subscriptionid
GROUP BY
    u.subscription_id,
    s.accountid,
    DATE_FORMAT(u.usage_date, '%Y-%m');

select * from vw_usage_monthly;

-- ------------------------------------------------------------
-- BI VIEW 4: vw_support_summary
-- Purpose : Support ticket totals per account.
--           Used to calculate support_ticket_rate KPI.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_support_summary AS
SELECT
    accountid,
    COUNT(ticketid)                     AS total_tickets,
    SUM(escalation_flag)                AS escalated_tickets,
    AVG(resolutiontimehours)            AS avg_resolution_hours,
    AVG(firstresponsetimeminutes)       AS avg_first_response_mins,
    AVG(satisfactionscore)              AS avg_satisfaction_score,
    SUM(is_open)                        AS open_tickets
FROM clean_support_tickets
GROUP BY accountid;

select * from vw_support_summary;

-- ------------------------------------------------------------
-- BI VIEW 5: vw_churn_facts
-- Purpose : Churn event fact table with monthly grain.
--           Excludes reactivated customers (is_reactivation=1)
--           for net churn calculation.
--           Joins to subscriptions for MRR at time of churn.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_churn_facts AS
SELECT
    ce.churn_event_id,
    ce.accountid,
    ce.churn_date,
    DATE_FORMAT(ce.churn_date, '%Y-%m')     AS churn_month,
    ce.reason_code,
    ce.refund_amount_usd,
    ce.preceding_upgrade_flag,
    ce.preceding_downgrade_flag,
    ce.is_reactivation,
    ce.feedback_text,
    s.plantier                              AS plan_at_churn,
    s.mrramount                             AS mrr_at_churn
FROM clean_churn_events ce
LEFT JOIN clean_subscriptions s
    ON  ce.accountid = s.accountid
WHERE ce.is_reactivation = 0;

select * from vw_churn_facts;


-- ============================================================
-- VERIFY: Confirm all views were created
-- ============================================================
SELECT
    TABLE_NAME      AS view_name,
    TABLE_TYPE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'saas_churn_db'
  AND TABLE_TYPE   = 'VIEW'
ORDER BY TABLE_NAME;


-- -------------check

-- 1. Customer dimension — should have 500 rows, no duplicates
SELECT COUNT(*) AS total_customers FROM vw_customer_dim;

-- 2. MRR source of truth — active paid subs only
SELECT
    COUNT(*)            AS active_paid_subs,
    SUM(monthly_fee)    AS total_mrr
FROM vw_subscription_facts
WHERE subscription_status = 'Active'
  AND active_revenue_flag = 1;

-- 3. Churn events (net churn — reactivations excluded)
SELECT COUNT(*) AS net_churn_events FROM vw_churn_facts;

-- 4. Support summary — should have one row per account
SELECT COUNT(*) AS accounts_with_tickets FROM vw_support_summary;

SELECT accountid, COUNT(*) AS cnt
FROM vw_customer_dim
GROUP BY accountid
HAVING cnt > 1;