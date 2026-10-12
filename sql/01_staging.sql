-- 01_staging.sql : creates the schemas and the raw staging tables (every column stored as text)
CREATE SCHEMA IF NOT EXISTS stg;   -- raw copies of the source files
CREATE SCHEMA IF NOT EXISTS ref;   -- reference / mapping tables (Czech code -> English label)
CREATE SCHEMA IF NOT EXISTS core;  -- cleaned, typed, translated tables
CREATE SCHEMA IF NOT EXISTS dq;    -- data-quality and reconciliation results
CREATE SCHEMA IF NOT EXISTS mart;  -- star schema that Power BI reads

DROP TABLE IF EXISTS stg.account, stg.client, stg.disp, stg.permanent_order,
                     stg.trans, stg.loan, stg.card, stg.district;

CREATE TABLE stg.account (account_id text, district_id text, frequency text, date text);
CREATE TABLE stg.client  (client_id text, birth_number text, district_id text);
CREATE TABLE stg.disp    (disp_id text, client_id text, account_id text, type text);
CREATE TABLE stg.permanent_order (order_id text, account_id text, bank_to text,
                                  account_to text, amount text, k_symbol text);
CREATE TABLE stg.trans   (trans_id text, account_id text, date text, type text, operation text,
                          amount text, balance text, k_symbol text, bank text, account text);
CREATE TABLE stg.loan    (loan_id text, account_id text, date text, amount text,
                          duration text, payments text, status text);
CREATE TABLE stg.card    (card_id text, disp_id text, type text, issued text);
CREATE TABLE stg.district (a1 text, a2 text, a3 text, a4 text, a5 text, a6 text, a7 text, a8 text,
                           a9 text, a10 text, a11 text, a12 text, a13 text, a14 text, a15 text, a16 text);
