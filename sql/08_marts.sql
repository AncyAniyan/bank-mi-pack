-- 08_marts.sql : star schema for Power BI (dimensions describe, facts measure)

CREATE SCHEMA IF NOT EXISTS mart;

-- dim_date: one row per calendar day (Power BI time intelligence needs a complete date table)
DROP TABLE IF EXISTS mart.dim_date CASCADE;
CREATE TABLE mart.dim_date AS
SELECT
  d::date                                                   AS date,
  EXTRACT(YEAR FROM d)::int                                 AS year,
  EXTRACT(QUARTER FROM d)::int                              AS quarter,
  EXTRACT(MONTH FROM d)::int                                AS month_no,
  to_char(d, 'Mon')                                         AS month_name,
  to_char(d, 'YYYY-MM')                                     AS year_month,
  date_trunc('month', d)::date                              AS month_start,
  (date_trunc('month', d) + interval '1 month - 1 day')::date AS month_end,
  EXTRACT(ISODOW FROM d)::int                               AS iso_day_of_week
FROM generate_series(DATE '1993-01-01', DATE '1998-12-31', interval '1 day') AS g(d);
ALTER TABLE mart.dim_date ADD PRIMARY KEY (date);

-- dim_district
DROP TABLE IF EXISTS mart.dim_district CASCADE;
CREATE TABLE mart.dim_district AS
SELECT district_id, district_name, region, inhabitants, avg_salary,
       unemployment_rate_1996, crimes_1996
FROM core.district;
ALTER TABLE mart.dim_district ADD PRIMARY KEY (district_id);

-- dim_account: one row per account, enriched with OWNER profile, card and loan flags
DROP TABLE IF EXISTS mart.dim_account CASCADE;
CREATE TABLE mart.dim_account AS
WITH owner AS (
  SELECT d.account_id, c.client_id, c.gender, c.birth_date
  FROM core.disp d
  JOIN core.client c ON c.client_id = d.client_id
  WHERE d.disp_type = 'OWNER'
), cards AS (
  SELECT d.account_id,
         string_agg(DISTINCT ca.card_type, ', ') AS card_types,
         MIN(ca.issued_date)                     AS first_card_issued
  FROM core.card ca
  JOIN core.disp d ON d.disp_id = ca.disp_id
  GROUP BY d.account_id
)
SELECT
  a.account_id, a.district_id, a.frequency_en, a.opened_date,
  o.client_id                                          AS owner_client_id,
  o.gender                                             AS owner_gender,
  EXTRACT(YEAR FROM o.birth_date)::int                 AS owner_birth_year,
  CASE
    WHEN o.birth_date IS NULL                                         THEN 'Unknown'
    WHEN EXTRACT(YEAR FROM age(DATE '1999-01-01', o.birth_date)) < 25 THEN '<25'
    WHEN EXTRACT(YEAR FROM age(DATE '1999-01-01', o.birth_date)) < 35 THEN '25-34'
    WHEN EXTRACT(YEAR FROM age(DATE '1999-01-01', o.birth_date)) < 45 THEN '35-44'
    WHEN EXTRACT(YEAR FROM age(DATE '1999-01-01', o.birth_date)) < 55 THEN '45-54'
    WHEN EXTRACT(YEAR FROM age(DATE '1999-01-01', o.birth_date)) < 65 THEN '55-64'
    ELSE '65+'
  END                                                  AS owner_age_band_1999,
  (cards.account_id IS NOT NULL)                       AS has_card,
  cards.card_types,
  cards.first_card_issued,
  EXISTS (SELECT 1 FROM core.loan l WHERE l.account_id = a.account_id) AS has_loan
FROM core.account a
LEFT JOIN owner o   ON o.account_id = a.account_id
LEFT JOIN cards     ON cards.account_id = a.account_id;
ALTER TABLE mart.dim_account ADD PRIMARY KEY (account_id);

-- fact_transaction: one row per transaction (grain = transaction)
DROP TABLE IF EXISTS mart.fact_transaction CASCADE;
CREATE TABLE mart.fact_transaction AS
SELECT trans_id, account_id, trans_date, type_en, operation_en, k_symbol_en,
       amount, signed_amount, balance
FROM core.transaction;
ALTER TABLE mart.fact_transaction ADD PRIMARY KEY (trans_id);

-- fact_loan: one row per loan (grain = loan)
DROP TABLE IF EXISTS mart.fact_loan CASCADE;
CREATE TABLE mart.fact_loan AS
SELECT loan_id, account_id, loan_date, amount, duration_months, monthly_payment,
       status, status_en, is_default, is_finished
FROM core.loan;
ALTER TABLE mart.fact_loan ADD PRIMARY KEY (loan_id);

-- fact_account_month: one row per account per month-end (grain = account x month)
DROP TABLE IF EXISTS mart.fact_account_month CASCADE;
CREATE TABLE mart.fact_account_month AS
WITH month_list AS (
  SELECT DISTINCT month_end FROM mart.dim_date
), account_months AS (
  SELECT a.account_id, ml.month_end
  FROM core.account a
  JOIN month_list ml ON ml.month_end >= a.opened_date
), monthly_txn AS (
  SELECT account_id,
         (date_trunc('month', trans_date) + interval '1 month - 1 day')::date AS month_end,
         COUNT(*)                                          AS txn_count,
         SUM(signed_amount) FILTER (WHERE signed_amount > 0)  AS inflow,
         -SUM(signed_amount) FILTER (WHERE signed_amount < 0) AS outflow
  FROM core.transaction
  GROUP BY 1, 2
), last_balance AS (
  SELECT DISTINCT ON (account_id, date_trunc('month', trans_date))
         account_id,
         (date_trunc('month', trans_date) + interval '1 month - 1 day')::date AS month_end,
         balance
  FROM core.transaction
  ORDER BY account_id, date_trunc('month', trans_date), trans_date DESC, trans_id DESC
), joined AS (
  SELECT am.account_id, am.month_end, t.txn_count, t.inflow, t.outflow, lb.balance,
         COUNT(lb.balance) OVER (PARTITION BY am.account_id ORDER BY am.month_end) AS balance_group
  FROM account_months am
  LEFT JOIN monthly_txn  t  ON t.account_id  = am.account_id AND t.month_end  = am.month_end
  LEFT JOIN last_balance lb ON lb.account_id = am.account_id AND lb.month_end = am.month_end
)
SELECT account_id,
       month_end,
       COALESCE(txn_count, 0)           AS txn_count,
       COALESCE(inflow, 0)              AS inflow,
       COALESCE(outflow, 0)             AS outflow,
       (COALESCE(txn_count, 0) > 0)     AS is_active,
       FIRST_VALUE(balance) OVER (PARTITION BY account_id, balance_group ORDER BY month_end) AS end_balance
FROM joined;
ALTER TABLE mart.fact_account_month ADD PRIMARY KEY (account_id, month_end);

-- Tests: the marts must not lose or duplicate rows
SELECT 'fact_transaction vs core' AS test,
       (SELECT COUNT(*) FROM mart.fact_transaction) = (SELECT COUNT(*) FROM core.transaction) AS passed
UNION ALL
SELECT 'dim_account vs core',
       (SELECT COUNT(*) FROM mart.dim_account) = (SELECT COUNT(*) FROM core.account)
UNION ALL
SELECT 'fact_loan vs core',
       (SELECT COUNT(*) FROM mart.fact_loan) = (SELECT COUNT(*) FROM core.loan)
UNION ALL
SELECT 'account_month txn total = transactions',
       (SELECT SUM(txn_count) FROM mart.fact_account_month) = (SELECT COUNT(*) FROM core.transaction);
