-- 07_reconciliation.sql : does the bank's reported balance agree with the transactions?

-- Step 1: recompute a running balance per account and compare it with the reported balance (row level)
DROP TABLE IF EXISTS dq.balance_recon;
CREATE TABLE dq.balance_recon AS
SELECT
  trans_id, account_id, trans_date, signed_amount, balance AS reported_balance,
  SUM(signed_amount) OVER (PARTITION BY account_id
                           ORDER BY trans_date, trans_id
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS recomputed_balance,
  ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY trans_date, trans_id) AS seq_in_account
FROM core.transaction;

ALTER TABLE dq.balance_recon ADD COLUMN difference numeric(14,2);
UPDATE dq.balance_recon SET difference = reported_balance - recomputed_balance;

-- Step 2: headline numbers at row level
SELECT COUNT(*)                                                       AS rows_checked,
       COUNT(*) FILTER (WHERE ABS(difference) > 0.01)                 AS rows_with_difference,
       COUNT(DISTINCT account_id) FILTER (WHERE ABS(difference) > 0.01) AS accounts_with_difference,
       COUNT(DISTINCT account_id)                                     AS accounts_checked
FROM dq.balance_recon;

-- Step 3: end-of-day comparison. The end-of-day balance does not depend on the ORDER of
-- transactions inside a day, so for each account-day take the smallest gap between any
-- balance reported that day and the recomputed end-of-day balance.
DROP TABLE IF EXISTS dq.balance_recon_eod;
CREATE TABLE dq.balance_recon_eod AS
WITH daily AS (
  SELECT account_id, trans_date, SUM(signed_amount) AS day_net
  FROM core.transaction
  GROUP BY account_id, trans_date
), eod AS (
  SELECT account_id, trans_date,
         SUM(day_net) OVER (PARTITION BY account_id ORDER BY trans_date) AS eod_recomputed
  FROM daily
)
SELECT e.account_id, e.trans_date, e.eod_recomputed,
       MIN(ABS(t.balance - e.eod_recomputed)) AS eod_gap
FROM eod e
JOIN core.transaction t ON t.account_id = e.account_id AND t.trans_date = e.trans_date
GROUP BY e.account_id, e.trans_date, e.eod_recomputed;

-- Step 4: classify every account. Change the tolerance in ONE place (params).
DROP TABLE IF EXISTS dq.balance_recon_accounts;
CREATE TABLE dq.balance_recon_accounts AS
WITH params AS (SELECT 5.00::numeric AS tolerance_czk),
row_level AS (
  SELECT account_id, MAX(ABS(difference)) AS max_row_diff
  FROM dq.balance_recon GROUP BY account_id
), eod_level AS (
  SELECT account_id, MAX(eod_gap) AS max_eod_gap,
         COUNT(*) FILTER (WHERE eod_gap > 0.01) AS eod_days_off
  FROM dq.balance_recon_eod GROUP BY account_id
)
SELECT r.account_id, r.max_row_diff, e.max_eod_gap, e.eod_days_off,
       CASE
         WHEN r.max_row_diff <= 0.01          THEN 'A: exact at every transaction'
         WHEN e.max_eod_gap  <= 0.01          THEN 'B: same-day ordering only (end-of-day exact)'
         WHEN e.max_eod_gap  <= p.tolerance_czk THEN 'C: small drift within tolerance (investigate cause, e.g. rounding)'
         ELSE                                      'D: material break above tolerance (investigate each)'
       END AS category
FROM row_level r
JOIN eod_level e ON e.account_id = r.account_id
CROSS JOIN params p;

-- Step 5: summary for the reconciliation report
SELECT category, COUNT(*) AS accounts, MAX(max_eod_gap) AS largest_end_of_day_gap
FROM dq.balance_recon_accounts
GROUP BY category
ORDER BY category;
