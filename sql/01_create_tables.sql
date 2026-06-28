-- ============================================================
-- 01_create_tables.sql
-- Project : RavenStack SaaS Subscription & Churn Analytics
-- Database: saas_churn_db
-- Purpose : DDL only — creates the database and all 5 raw tables.
--           Data loading (INSERT from bronze tables) is done
--           after this script runs. Cleaning logic is in
--           02_cleaning_views.sql.
-- ============================================================

CREATE DATABASE IF NOT EXISTS saas_churn_db;
USE saas_churn_db;

-- ============================================================
-- TABLE 1: ravenstack_accounts
-- Source  : ravenstack_accounts.csv
-- Grain   : One row per customer account
-- PK      : accountid
-- ============================================================
DROP TABLE IF EXISTS ravenstack_accounts;

CREATE TABLE ravenstack_accounts (
    accountid           VARCHAR(50)     NOT NULL,
    accountname         VARCHAR(255)    NOT NULL,
    industry            VARCHAR(100),
    country             VARCHAR(50),
    signupdate          DATE,
    referralsource      VARCHAR(50),
    plantier            VARCHAR(50),
    seats               INT,
    istrial             VARCHAR(15),
    churnflag           VARCHAR(15),
    PRIMARY KEY (accountid)
);

-- ============================================================
-- TABLE 2: ravenstack_subscriptions
-- Source  : ravenstack_subscriptions.csv
-- Grain   : One row per subscription record
-- PK      : subscriptionid
-- FK      : accountid → ravenstack_accounts
-- Note    : enddate is NULL for active subscriptions (expected)
-- ============================================================
DROP TABLE IF EXISTS ravenstack_subscriptions;

CREATE TABLE ravenstack_subscriptions (
    subscriptionid      VARCHAR(50)     NOT NULL,
    accountid           VARCHAR(50)     NOT NULL,
    startdate           DATE,
    enddate             DATE,               -- NULL = active subscription
    plantier            VARCHAR(50),
    seats               INT,
    mrramount           DECIMAL(18,2),
    arramount           DECIMAL(18,2),
    istrial             VARCHAR(20),
    upgradeflag         VARCHAR(20),
    downgradeflag       VARCHAR(20),
    churnflag           VARCHAR(20),
    billingfrequency    VARCHAR(20),
    autorenewflag       VARCHAR(15),
    PRIMARY KEY (subscriptionid),
    CONSTRAINT fk_subscriptions_accounts
        FOREIGN KEY (accountid) REFERENCES ravenstack_accounts (accountid)
);

-- ============================================================
-- TABLE 3: ravenstack_support_tickets
-- Source  : ravenstack_support_tickets.csv
-- Grain   : One row per support ticket
-- PK      : ticketid
-- FK      : accountid → ravenstack_accounts
-- Note    : firstresponsetimeminutess is intentional typo from
--           raw CSV — renamed to correct spelling in view layer
-- Note    : satisfactionscore has NULLs (expected — not all
--           tickets are rated)
-- ============================================================
DROP TABLE IF EXISTS ravenstack_support_tickets;

CREATE TABLE ravenstack_support_tickets (
    ticketid                    VARCHAR(50)     NOT NULL,
    accountid                   VARCHAR(50)     NOT NULL,
    submittedat                 DATETIME,
    closedat                    DATETIME,           -- NULL = ticket still open
    resolutiontimehours         DECIMAL(10,2),
    priority                    VARCHAR(20),
    firstresponsetimeminutess   DECIMAL(10,2),      -- raw CSV typo kept intentionally
    satisfactionscore           DECIMAL(10,2),      -- NULLs expected
    escalationflag              VARCHAR(20),
    PRIMARY KEY (ticketid),
    CONSTRAINT fk_tickets_accounts
        FOREIGN KEY (accountid) REFERENCES ravenstack_accounts (accountid)
);

-- ============================================================
-- TABLE 4: ravenstack_feature_usage
-- Source  : ravenstack_feature_usage.csv
-- Grain   : One row per usage event per subscription per feature
-- PK      : usage_id (usage_id + subscription_id composite is
--           also valid — kept composite per original design)
-- FK      : subscription_id → ravenstack_subscriptions
-- ============================================================
DROP TABLE IF EXISTS ravenstack_feature_usage;

CREATE TABLE ravenstack_feature_usage (
    usage_id                VARCHAR(50)     NOT NULL,
    subscription_id         VARCHAR(50)     NOT NULL,
    usage_date              DATE,
    feature_name            VARCHAR(255)    NOT NULL,
    usage_count             INT,
    usage_duration_secs     INT,
    error_count             INT,
    is_beta_feature         VARCHAR(20),
    PRIMARY KEY (usage_id, subscription_id),
    CONSTRAINT fk_feature_usage_subscriptions
        FOREIGN KEY (subscription_id) REFERENCES ravenstack_subscriptions (subscriptionid)
);

-- ============================================================
-- TABLE 5: ravenstack_churn_events
-- Source  : ravenstack_churn_events.csv
-- Grain   : One row per churn event
-- PK      : churn_event_id
-- FK      : account_id → ravenstack_accounts (note: uses
--           underscore — standardized to accountid in view layer)
-- Note    : feedback_text has NULLs (expected — not all
--           customers leave feedback)
-- ============================================================
DROP TABLE IF EXISTS ravenstack_churn_events;

CREATE TABLE ravenstack_churn_events (
    churn_event_id              VARCHAR(50)     NOT NULL,
    account_id                  VARCHAR(50)     NOT NULL,   -- underscore format, standardized in views
    churn_date                  DATE,
    reason_code                 VARCHAR(50)     NOT NULL,
    refund_amount_usd           DECIMAL(18,2),
    preceding_upgrade_flag      VARCHAR(20),
    preceding_downgrade_flag    VARCHAR(20),
    is_reactivation             VARCHAR(20),
    feedback_text               VARCHAR(1000),              -- NULLs expected
    PRIMARY KEY (churn_event_id),
    CONSTRAINT fk_churn_events_accounts
        FOREIGN KEY (account_id) REFERENCES ravenstack_accounts (accountid)
);

-- ============================================================
-- LOAD VALIDATION
-- Run after all bronze → main table INSERTs are complete.
-- Expected: accounts=500, subscriptions=5000,
--           support_tickets=2000, feature_usage=25000,
--           churn_events=600
-- ============================================================
SELECT 'ravenstack_accounts'       AS table_name, COUNT(*) AS row_count FROM ravenstack_accounts
UNION ALL
SELECT 'ravenstack_subscriptions',                COUNT(*)               FROM ravenstack_subscriptions
UNION ALL
SELECT 'ravenstack_support_tickets',              COUNT(*)               FROM ravenstack_support_tickets
UNION ALL
SELECT 'ravenstack_feature_usage',                COUNT(*)               FROM ravenstack_feature_usage
UNION ALL
SELECT 'ravenstack_churn_events',                 COUNT(*)               FROM ravenstack_churn_events;