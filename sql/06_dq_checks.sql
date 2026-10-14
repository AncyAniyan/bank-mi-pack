-- 06_dq_checks.sql : data-quality rule suite. Every run appends one row per check to dq.results.
-- Production cadence:
--   Daily (automated transaction feeds): DQ-01, DQ-02, DQ-03, DQ-04, DQ-05, DQ-06, DQ-10, DQ-14
--   Once / Reference (dimensions & migration): DQ-07, DQ-08, DQ-09, DQ-11, DQ-12, DQ-13

CREATE SCHEMA IF NOT EXISTS dq;

CREATE TABLE IF NOT EXISTS dq.results (
  run_at      timestamptz DEFAULT now(),
  check_id    text,
  check_name  text,
  table_name  text,
  failed_rows bigint,
  total_rows  bigint,
  status      text
);

INSERT INTO dq.results (check_id, check_name, table_name, failed_rows, total_rows, status)
SELECT check_id, check_name, table_name, failed_rows, total_rows,
       CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
  -- DQ-01 NULL-safe: a NULL type would slip through "NOT IN", so test it explicitly
  SELECT 'DQ-01' AS check_id, 'Transaction type is a documented code (PRIJEM/VYDAJ)' AS check_name,
         'core.transaction' AS table_name,
         COUNT(*) FILTER (WHERE type_code IS NULL OR type_code NOT IN ('PRIJEM','VYDAJ')) AS failed_rows,
         COUNT(*) AS total_rows
  FROM core.transaction
  UNION ALL
  SELECT 'DQ-02', 'Transaction amount is positive', 'core.transaction',
         COUNT(*) FILTER (WHERE amount IS NULL OR amount <= 0), COUNT(*)
  FROM core.transaction
  UNION ALL
  SELECT 'DQ-03', 'Transaction date inside 1993-01-01..1998-12-31', 'core.transaction',
         COUNT(*) FILTER (WHERE trans_date IS NULL OR trans_date NOT BETWEEN DATE '1993-01-01' AND DATE '1998-12-31'),
         COUNT(*)
  FROM core.transaction
  UNION ALL
  SELECT 'DQ-04', 'Transaction belongs to a known account (orphan check)', 'core.transaction',
         COUNT(*) FILTER (WHERE a.account_id IS NULL), COUNT(*)
  FROM core.transaction t LEFT JOIN core.account a ON a.account_id = t.account_id
  UNION ALL
  SELECT 'DQ-05', 'Transaction is not before the account opening date', 'core.transaction',
         COUNT(*) FILTER (WHERE t.trans_date < a.opened_date), COUNT(*)
  FROM core.transaction t JOIN core.account a ON a.account_id = t.account_id
  UNION ALL
  -- DQ-06 Refined: automated interest credits (183,114 rows) legitimately carry no operation code
  SELECT 'DQ-06', 'Operation code is filled and documented (excl. interest credit)', 'core.transaction',
         COUNT(*) FILTER (WHERE operation_en IS NULL AND COALESCE(k_symbol_en, '') <> 'Interest credited'), COUNT(*)
  FROM core.transaction
  UNION ALL
  SELECT 'DQ-07', 'Every account has exactly one OWNER', 'core.account',
         COUNT(*) FILTER (WHERE COALESCE(o.owners, 0) <> 1), COUNT(*)
  FROM core.account a
  LEFT JOIN (SELECT account_id, COUNT(*) AS owners FROM core.disp
             WHERE disp_type = 'OWNER' GROUP BY account_id) o ON o.account_id = a.account_id
  UNION ALL
  SELECT 'DQ-08', 'Client birth date is valid and between 1900 and 1998', 'core.client',
         COUNT(*) FILTER (WHERE birth_date IS NULL OR birth_date NOT BETWEEN DATE '1900-01-01' AND DATE '1998-12-31'),
         COUNT(*)
  FROM core.client
  UNION ALL
  SELECT 'DQ-09', 'Loan status is one of A/B/C/D', 'core.loan',
         COUNT(*) FILTER (WHERE status IS NULL OR status NOT IN ('A','B','C','D')), COUNT(*)
  FROM core.loan
  UNION ALL
  SELECT 'DQ-10', 'Loan amount roughly equals duration x monthly payment (within 1%)', 'core.loan',
         COUNT(*) FILTER (WHERE ABS(amount - duration_months * monthly_payment) > 0.01 * amount), COUNT(*)
  FROM core.loan
  UNION ALL
  SELECT 'DQ-11', 'At most one loan per account', 'core.loan',
         COUNT(*) FILTER (WHERE n > 1), COUNT(*)
  FROM (SELECT account_id, COUNT(*) AS n FROM core.loan GROUP BY account_id) x
  UNION ALL
  SELECT 'DQ-12', 'Card issued on or after the account opening date', 'core.card',
         COUNT(*) FILTER (WHERE c.issued_date < a.opened_date), COUNT(*)
  FROM core.card c JOIN core.disp d ON d.disp_id = c.disp_id JOIN core.account a ON a.account_id = d.account_id
  UNION ALL
  SELECT 'DQ-13', 'District demographic fields complete (no unknown values)', 'core.district',
         COUNT(*) FILTER (WHERE unemployment_rate_1995 IS NULL OR crimes_1995 IS NULL), COUNT(*)
  FROM core.district
  UNION ALL
  SELECT 'DQ-14', 'Duplicate business key: same account, date, type, amount, balance', 'core.transaction',
         COALESCE(SUM(n - 1), 0), (SELECT COUNT(*) FROM core.transaction)
  FROM (SELECT COUNT(*) AS n FROM core.transaction
        GROUP BY account_id, trans_date, type_code, amount, balance HAVING COUNT(*) > 1) d
) checks;

-- Latest run, worst first
SELECT check_id, check_name, failed_rows, total_rows,
       ROUND(100.0 * failed_rows / NULLIF(total_rows, 0), 3) AS failed_pct, status
FROM dq.results
WHERE run_at = (SELECT MAX(run_at) FROM dq.results)
ORDER BY status, failed_rows DESC;
