-- 05_core.sql : typed, cleaned, translated tables. Re-runnable (drops and rebuilds).

-- Districts: '?' means "unknown" in this file, so it becomes NULL
DROP TABLE IF EXISTS core.district;
CREATE TABLE core.district AS
SELECT
  NULLIF(trim(a1),  '?')::int      AS district_id,
  trim(a2)                         AS district_name,
  trim(a3)                         AS region,
  NULLIF(trim(a4),  '?')::int      AS inhabitants,
  NULLIF(trim(a9),  '?')::int      AS number_of_cities,
  NULLIF(trim(a10), '?')::numeric  AS urban_ratio_pct,
  NULLIF(trim(a11), '?')::int      AS avg_salary,
  NULLIF(trim(a12), '?')::numeric  AS unemployment_rate_1995,
  NULLIF(trim(a13), '?')::numeric  AS unemployment_rate_1996,
  NULLIF(trim(a14), '?')::int      AS entrepreneurs_per_1000,
  NULLIF(trim(a15), '?')::int      AS crimes_1995,
  NULLIF(trim(a16), '?')::int      AS crimes_1996
FROM stg.district;

-- Accounts: YYMMDD integer date -> real date; frequency translated
DROP TABLE IF EXISTS core.account;
CREATE TABLE core.account AS
SELECT
  a.account_id::int                                   AS account_id,
  a.district_id::int                                  AS district_id,
  trim(a.frequency)                                   AS frequency_code,
  m.label_en                                          AS frequency_en,
  to_date(lpad(trim(a.date), 6, '0'), 'YYMMDD')       AS opened_date
FROM stg.account a
LEFT JOIN ref.code_map m
  ON m.source_table = 'account' AND m.source_column = 'frequency' AND m.code = trim(a.frequency);

-- Clients: gender and birth date are encoded inside birth_number
--   men:   YYMMDD        women: YY(MM+50)DD        year = 1900 + YY
DROP TABLE IF EXISTS core.client;
CREATE TABLE core.client AS
WITH p AS (
  SELECT client_id::int   AS client_id,
         district_id::int AS district_id,
         lpad(trim(birth_number), 6, '0') AS bn
  FROM stg.client
)
SELECT
  client_id,
  district_id,
  CASE WHEN substr(bn, 3, 2)::int > 50 THEN 'F' ELSE 'M' END AS gender,
  make_date(1900 + substr(bn, 1, 2)::int,
            substr(bn, 3, 2)::int - CASE WHEN substr(bn, 3, 2)::int > 50 THEN 50 ELSE 0 END,
            substr(bn, 5, 2)::int)                         AS birth_date,
  bn                                                       AS birth_number_raw
FROM p;

-- Dispositions: who may use which account (OWNER or DISPONENT)
DROP TABLE IF EXISTS core.disp;
CREATE TABLE core.disp AS
SELECT disp_id::int AS disp_id, client_id::int AS client_id, account_id::int AS account_id,
       trim(type) AS disp_type
FROM stg.disp;

-- Transactions: typed, translated, plus a signed amount (+ money in, - money out)
DROP TABLE IF EXISTS core.transaction;
CREATE TABLE core.transaction AS
SELECT
  t.trans_id::bigint                                  AS trans_id,
  t.account_id::int                                   AS account_id,
  to_date(lpad(trim(t.date), 6, '0'), 'YYMMDD')       AS trans_date,
  trim(t.type)                                        AS type_code,
  ty.label_en                                         AS type_en,
  NULLIF(trim(t.operation), '')                       AS operation_code,
  op.label_en                                         AS operation_en,
  NULLIF(trim(t.k_symbol), '')                        AS k_symbol_code,
  ks.label_en                                         AS k_symbol_en,
  t.amount::numeric(14,2)                             AS amount,
  CASE WHEN trim(t.type) = 'PRIJEM' THEN  t.amount::numeric(14,2)
       ELSE                               -t.amount::numeric(14,2) END AS signed_amount,
  t.balance::numeric(14,2)                            AS balance,
  NULLIF(trim(t.bank), '')                            AS partner_bank,
  NULLIF(trim(t.account), '')                         AS partner_account
FROM stg.trans t
LEFT JOIN ref.code_map ty ON ty.source_table='trans' AND ty.source_column='type'      AND ty.code = trim(t.type)
LEFT JOIN ref.code_map op ON op.source_table='trans' AND op.source_column='operation' AND op.code = trim(t.operation)
LEFT JOIN ref.code_map ks ON ks.source_table='trans' AND ks.source_column='k_symbol'  AND ks.code = trim(t.k_symbol);

-- Loans: status A/B/C/D translated; B and D are the "default" statuses
DROP TABLE IF EXISTS core.loan;
CREATE TABLE core.loan AS
SELECT
  l.loan_id::int                                      AS loan_id,
  l.account_id::int                                   AS account_id,
  to_date(lpad(trim(l.date), 6, '0'), 'YYMMDD')       AS loan_date,
  l.amount::numeric(14,2)                             AS amount,
  l.duration::int                                     AS duration_months,
  l.payments::numeric(14,2)                           AS monthly_payment,
  trim(l.status)                                      AS status,
  m.label_en                                          AS status_en,
  trim(l.status) IN ('B','D')                         AS is_default,
  trim(l.status) IN ('A','B')                         AS is_finished
FROM stg.loan l
LEFT JOIN ref.code_map m ON m.source_table='loan' AND m.source_column='status' AND m.code = trim(l.status);

-- Cards: issued looks like '931107 00:00:00' -> keep the first 6 characters
DROP TABLE IF EXISTS core.card;
CREATE TABLE core.card AS
SELECT card_id::int AS card_id, disp_id::int AS disp_id, trim(type) AS card_type,
       to_date(left(trim(issued), 6), 'YYMMDD') AS issued_date
FROM stg.card;

-- Permanent orders (standing instructions)
DROP TABLE IF EXISTS core.permanent_order;
CREATE TABLE core.permanent_order AS
SELECT o.order_id::int AS order_id, o.account_id::int AS account_id,
       NULLIF(trim(o.bank_to),'') AS bank_to, NULLIF(trim(o.account_to),'') AS account_to,
       o.amount::numeric(14,2) AS amount,
       NULLIF(trim(o.k_symbol),'') AS k_symbol_code, m.label_en AS k_symbol_en
FROM stg.permanent_order o
LEFT JOIN ref.code_map m ON m.source_table='order' AND m.source_column='k_symbol' AND m.code = trim(o.k_symbol);

-- Primary keys make duplicate IDs impossible from here on (the CREATE fails loudly if a duplicate exists)
ALTER TABLE core.district        ADD PRIMARY KEY (district_id);
ALTER TABLE core.account         ADD PRIMARY KEY (account_id);
ALTER TABLE core.client          ADD PRIMARY KEY (client_id);
ALTER TABLE core.disp            ADD PRIMARY KEY (disp_id);
ALTER TABLE core.transaction     ADD PRIMARY KEY (trans_id);
ALTER TABLE core.loan            ADD PRIMARY KEY (loan_id);
ALTER TABLE core.card            ADD PRIMARY KEY (card_id);
ALTER TABLE core.permanent_order ADD PRIMARY KEY (order_id);
---Spot Query to check data added
SELECT client_id, birth_number_raw, gender, birth_date
FROM core.client
ORDER BY random()
LIMIT 20;
