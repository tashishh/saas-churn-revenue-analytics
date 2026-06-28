-- ============================================================
-- 03_kpi_validation.sql
-- Project : RavenStack SaaS Subscription & Churn Analytics
-- Purpose : Validate all dashboard KPIs from SQL layer.
--           These numbers are your source-of-truth baseline.
--           You will reconcile these against Python (Day 3)
--           and Power BI DAX (Day 4).
-- ============================================================

USE saas_churn_db;

-- ------------------------------------------------------------
-- KPI 1: Total Customers
-- Definition: Distinct accounts in the accounts table
-- ------------------------------------------------------------
SELECT
    'KPI 1 - Total Customers'           AS kpi,
    COUNT(DISTINCT accountid)           AS value
FROM ravenstack_accounts;

-- ------------------------------------------------------------
-- KPI 2: Active Customers
-- Definition: Accounts where churnflag = 'False'
-- ------------------------------------------------------------
SELECT
    'KPI 2 - Active Customers'          AS kpi,
    COUNT(DISTINCT accountid)           AS value
FROM ravenstack_accounts
WHERE LOWER(churnflag) = 'false';

-- ------------------------------------------------------------
-- KPI 3: Churned Customers
-- Definition: Distinct accounts in churn_events
--             (net churn — reactivations excluded)
-- ------------------------------------------------------------
SELECT
    'KPI 3 - Churned Customers'         AS kpi,
    COUNT(DISTINCT account_id)          AS value
FROM ravenstack_churn_events
WHERE LOWER(is_reactivation) = 'false';

-- ------------------------------------------------------------
-- KPI 4: Churn Rate
-- Definition: Churned Customers / Total Customers
-- Denominator: Total unique accounts (active + churned)
-- ------------------------------------------------------------
SELECT
    'KPI 4 - Churn Rate'                AS kpi,
    CONCAT(
        ROUND(
            COUNT(DISTINCT ce.account_id) * 100.0
            / COUNT(DISTINCT a.accountid),
        2), '%')                         AS value
FROM ravenstack_accounts a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM ravenstack_churn_events
    WHERE LOWER(is_reactivation) = 'false'
) ce ON a.accountid = ce.account_id;

-- ------------------------------------------------------------
-- KPI 5: MRR (Monthly Recurring Revenue)
-- Definition: SUM of mrramount for active, non-trial subs
-- ------------------------------------------------------------
SELECT
    'KPI 5 - Total MRR'                 AS kpi,
    CONCAT('$', FORMAT(SUM(mrramount), 2)) AS value
FROM ravenstack_subscriptions
WHERE LOWER(churnflag) = 'false'
  AND LOWER(istrial)   = 'false';

-- ------------------------------------------------------------
-- KPI 6: ARPU (Average Revenue Per User)
-- Definition: MRR / Active Customers
-- ------------------------------------------------------------
SELECT
    'KPI 6 - ARPU'                      AS kpi,
    CONCAT('$', FORMAT(
        SUM(s.mrramount) /
        COUNT(DISTINCT a.accountid)
    , 2))                               AS value
FROM ravenstack_accounts a
JOIN ravenstack_subscriptions s
    ON  a.accountid        = s.accountid
    AND LOWER(s.churnflag) = 'false'
    AND LOWER(s.istrial)   = 'false'
WHERE LOWER(a.churnflag) = 'false';

-- ------------------------------------------------------------
-- KPI 7: Support Ticket Rate
-- Definition: Total tickets / Active Customers * 100
-- ------------------------------------------------------------
SELECT
    'KPI 7 - Support Ticket Rate'       AS kpi,
    CONCAT(
        ROUND(
            COUNT(t.ticketid) * 100.0
            / COUNT(DISTINCT a.accountid)
        , 2), ' per 100 customers')     AS value
FROM ravenstack_accounts a
LEFT JOIN ravenstack_support_tickets t
    ON a.accountid         = t.accountid
WHERE LOWER(a.churnflag)  = 'false';

-- ------------------------------------------------------------
-- KPI 8: MRR by Plan
-- Definition: MRR broken down by plantier
-- ------------------------------------------------------------
SELECT
    'KPI 8 - MRR by Plan'               AS kpi,
    plantier,
    COUNT(DISTINCT accountid)           AS customers,
    CONCAT('$', FORMAT(SUM(mrramount), 2)) AS mrr
FROM ravenstack_subscriptions
WHERE LOWER(churnflag) = 'false'
  AND LOWER(istrial)   = 'false'
GROUP BY plantier
ORDER BY SUM(mrramount) DESC;

-- ------------------------------------------------------------
-- KPI 9: Churn by Plan
-- Definition: Churned customers broken down by plan at churn
-- ------------------------------------------------------------
SELECT
    'KPI 9 - Churn by Plan'             AS kpi,
    s.plantier                          AS plan_at_churn,
    COUNT(DISTINCT ce.account_id)       AS churned_customers
FROM ravenstack_churn_events ce
JOIN ravenstack_subscriptions s
    ON ce.account_id = s.accountid
WHERE LOWER(ce.is_reactivation) = 'false'
GROUP BY s.plantier
ORDER BY churned_customers DESC;

-- ------------------------------------------------------------
-- KPI 10: Churn by Reason
-- Definition: Count of churn events grouped by reason_code
-- ------------------------------------------------------------
SELECT
    'KPI 10 - Churn by Reason'          AS kpi,
    reason_code,
    COUNT(*)                            AS churn_count,
    CONCAT(ROUND(COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (), 1), '%') AS pct_of_total
FROM ravenstack_churn_events
WHERE LOWER(is_reactivation) = 'false'
GROUP BY reason_code
ORDER BY churn_count DESC;

-- ------------------------------------------------------------
-- KPI 11: Monthly Churn Trend
-- Definition: Churned customers per month
-- ------------------------------------------------------------
SELECT
    'KPI 11 - Monthly Churn Trend'      AS kpi,
    DATE_FORMAT(churn_date, '%Y-%m')    AS churn_month,
    COUNT(DISTINCT account_id)          AS churned_customers
FROM ravenstack_churn_events
WHERE LOWER(is_reactivation) = 'false'
GROUP BY DATE_FORMAT(churn_date, '%Y-%m')
ORDER BY churn_month;

-- ------------------------------------------------------------
-- MASTER SUMMARY — All scalar KPIs in one result set
-- Use this table to reconcile against Python and Power BI
-- ------------------------------------------------------------
SELECT 'Total Customers'    AS kpi, COUNT(DISTINCT accountid)                   AS value FROM ravenstack_accounts
UNION ALL
SELECT 'Active Customers',          COUNT(DISTINCT accountid)                           FROM ravenstack_accounts      WHERE LOWER(churnflag) = 'false'
UNION ALL
SELECT 'Churned Customers',         COUNT(DISTINCT account_id)                          FROM ravenstack_churn_events  WHERE LOWER(is_reactivation) = 'false'
UNION ALL
SELECT 'Total MRR',                 ROUND(SUM(mrramount), 2)                            FROM ravenstack_subscriptions WHERE LOWER(churnflag) = 'false' AND LOWER(istrial) = 'false'
UNION ALL
SELECT 'Total Subscriptions',       COUNT(*)                                            FROM ravenstack_subscriptions WHERE LOWER(churnflag) = 'false' AND LOWER(istrial) = 'false'
UNION ALL
SELECT 'Total Support Tickets',     COUNT(*)                                            FROM ravenstack_support_tickets
UNION ALL
SELECT 'Total Churn Events',        COUNT(*)                                            FROM ravenstack_churn_events  WHERE LOWER(is_reactivation) = 'false';