-- 09_analysis_risk_crosssell.sql

-- A) Behaviour in the 90 days BEFORE each loan was granted (only past data: no "leakage")
DROP TABLE IF EXISTS mart.loan_pre_behaviour;
CREATE TABLE mart.loan_pre_behaviour AS
SELECT
  l.loan_id, l.account_id, l.loan_date, l.is_default,
  COUNT(t.trans_id)                                            AS txn_count_90d,
  ROUND(AVG(t.balance), 2)                                     AS avg_balance_90d,
  MIN(t.balance)                                               AS min_balance_90d,
  COUNT(*) FILTER (WHERE t.k_symbol_code = 'SANKC. UROK')      AS penalty_interest_90d
FROM core.loan l
LEFT JOIN core.transaction t
  ON  t.account_id = l.account_id
  AND t.trans_date >= l.loan_date - 90
  AND t.trans_date <  l.loan_date
GROUP BY l.loan_id, l.account_id, l.loan_date, l.is_default;

ALTER TABLE mart.loan_pre_behaviour ADD COLUMN balance_band text;
UPDATE mart.loan_pre_behaviour SET balance_band =
  CASE WHEN avg_balance_90d IS NULL   THEN '0 No history'
       WHEN avg_balance_90d < 20000   THEN '1 Under 20k'
       WHEN avg_balance_90d < 40000   THEN '2 20k-40k'
       WHEN avg_balance_90d < 60000   THEN '3 40k-60k'
       ELSE                                '4 60k and above' END;

-- Default rate by balance band, with the denominator shown and small groups flagged
SELECT balance_band,
       COUNT(*)                                             AS loans,
       COUNT(*) FILTER (WHERE is_default)                   AS defaulted,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_default) / COUNT(*), 1) AS default_rate_pct,
       CASE WHEN COUNT(*) < 5 THEN 'small sample - do not conclude' ELSE '' END AS caution
FROM mart.loan_pre_behaviour
GROUP BY balance_band
ORDER BY balance_band;

-- B) Card cross-sell list: active in the last 3 months of data, no card,
--    balance at or above the median, and no defaulted loan
DROP TABLE IF EXISTS mart.cross_sell_list;
CREATE TABLE mart.cross_sell_list AS
WITH last3 AS (
  SELECT account_id, SUM(txn_count) AS txn_last3, AVG(end_balance) AS avg_end_balance_last3
  FROM mart.fact_account_month
  WHERE month_end >= (SELECT MAX(month_end) FROM mart.fact_account_month) - interval '2 months'
  GROUP BY account_id
), median AS (
  SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY avg_end_balance_last3) AS median_balance
  FROM last3
)
SELECT d.account_id, d.district_id, d.owner_gender, d.owner_age_band_1999,
       l3.txn_last3, ROUND(l3.avg_end_balance_last3, 2) AS avg_end_balance_last3
FROM mart.dim_account d
JOIN last3 l3 ON l3.account_id = d.account_id
CROSS JOIN median m
WHERE l3.txn_last3 > 0
  AND NOT d.has_card
  AND l3.avg_end_balance_last3 >= m.median_balance
  AND NOT EXISTS (SELECT 1 FROM core.loan l WHERE l.account_id = d.account_id AND l.is_default);

SELECT COUNT(*) AS accounts_on_cross_sell_list FROM mart.cross_sell_list;

-- C) One table for Power BI: each loan with its pre-loan behaviour (avoids a 1:1 relationship in the model)
DROP TABLE IF EXISTS mart.fact_loan_risk;
CREATE TABLE mart.fact_loan_risk AS
SELECT f.*, b.txn_count_90d, b.avg_balance_90d, b.min_balance_90d, b.penalty_interest_90d, b.balance_band
FROM mart.fact_loan f
JOIN mart.loan_pre_behaviour b ON b.loan_id = f.loan_id;
ALTER TABLE mart.fact_loan_risk ADD PRIMARY KEY (loan_id);
