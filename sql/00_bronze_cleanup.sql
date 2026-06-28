-- ============================================================
-- 00_bronze_cleanup.sql
-- Purpose : Fix empty strings → NULL in bronze tables before
--           inserting into main tables. Run ONCE before
--           01_create_tables.sql inserts.
-- ============================================================

USE saas_churn_db;

-- Fix empty enddate in subscriptions bronze
UPDATE ravenstack_subscriptions_bronze
SET end_date = NULL
WHERE end_date = '';
select * from ravenstack_subscriptions_bronze;

-- Fix empty satisfactionscore in support tickets bronze
UPDATE ravenstack_support_tickets_bronze
SET satisfaction_score = NULL
WHERE satisfaction_score = '';
select * from ravenstack_support_tickets_bronze;

UPDATE ravenstack_churn_events_bronze
SET feedback_text = NULL
WHERE feedback_text = '';

-- Then run your INSERTs:
INSERT INTO ravenstack_accounts
SELECT * FROM ravenstack_accounts_bronze;

INSERT INTO ravenstack_subscriptions
SELECT * FROM ravenstack_subscriptions_bronze;

INSERT INTO ravenstack_support_tickets
SELECT * FROM ravenstack_support_tickets_bronze;

INSERT INTO ravenstack_feature_usage
SELECT * FROM ravenstack_feature_usage_bronze;

INSERT INTO ravenstack_churn_events
SELECT * FROM ravenstack_churn_events_bronze;