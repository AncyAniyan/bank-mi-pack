# Data Dictionary — Dimensional Model (`mart`)

Refresh rule: Re-run `sql/08_marts.sql` against PostgreSQL `bank_mi`.

---

## mart.dim_date
**Grain:** One row per calendar day (1993-01-01 to 1998-12-31).  
**Source:** `generate_series()`  

| Column | Type | Meaning | Source | Notes |
|---|---|---|---|---|
| date | date | Calendar date | generated | Primary key |
| year | int | Calendar year | EXTRACT(YEAR) | 1993–1998 |
| quarter | int | Quarter of year (1–4) | EXTRACT(QUARTER) | |
| month_no | int | Month number (1–12) | EXTRACT(MONTH) | |
| month_name | varchar | 3-letter month name | to_char('Mon') | e.g. 'Jan' |
| year_month | varchar | Year-month key (YYYY-MM) | to_char('YYYY-MM') | For monthly aggregations |
| month_start | date | First day of month | date_trunc('month') | |
| month_end | date | Last day of month | interval arithmetic | Joins to monthly facts |
| iso_day_of_week | int | Day of week (1=Mon..7=Sun) | EXTRACT(ISODOW) | |

---

## mart.dim_district
**Grain:** One row per administrative district.  
**Source:** `core.district`  

| Column | Type | Meaning | Source | Notes |
|---|---|---|---|---|
| district_id | int | District identifier | core.district.district_id | Primary key |
| district_name | text | Name of district | core.district.district_name | |
| region | text | Geographic region in Czech Republic | core.district.region | |
| inhabitants | int | Total population | core.district.inhabitants | |
| avg_salary | int | Average monthly salary (CZK) | core.district.avg_salary | |
| unemployment_rate_1996 | numeric | 1996 unemployment rate (%) | core.district.unemployment_rate_1996 | |
| crimes_1996 | int | Number of committed crimes (1996) | core.district.crimes_1996 | |

---

## mart.dim_account
**Grain:** One row per bank account, enriched with Owner demographics, card, and loan flags.  
**Source:** `core.account`, `core.disp`, `core.client`, `core.card`, `core.loan`  

| Column | Type | Meaning | Source | Notes |
|---|---|---|---|---|
| account_id | int | Account identifier | core.account.account_id | Primary key |
| district_id | int | Branch district location | core.account.district_id | FK to mart.dim_district |
| frequency_en | text | Statement issue frequency | core.account.frequency_en | Monthly / Weekly / After txn |
| opened_date | date | Account opening date | core.account.opened_date | |
| owner_client_id | int | Client ID of the primary owner | core.client.client_id | disp_type = 'OWNER' |
| owner_gender | char(1) | Owner gender (M/F) | core.client.gender | Decoded from birth_number |
| owner_birth_year | int | Owner birth year | core.client.birth_date | |
| owner_age_band_1999 | text | Age bracket as of 1999 | core.client.birth_date | <25, 25-34, 35-44, 45-54, 55-64, 65+ |
| has_card | boolean | True if account has a payment card | core.card | Flag for cross-sell |
| card_types | text | Comma-separated card types held | core.card.card_type | Classic, Junior, Gold |
| first_card_issued | date | Earliest card issue date | core.card.issued_date | |
| has_loan | boolean | True if account holds a loan | core.loan | |

---

## mart.fact_transaction
**Grain:** One row per posted bank transaction.  
**Source:** `core.transaction`  

| Column | Type | Meaning | Source | Notes |
|---|---|---|---|---|
| trans_id | bigint | Transaction identifier | core.transaction.trans_id | Primary key |
| account_id | int | Account identifier | core.transaction.account_id | FK to mart.dim_account |
| trans_date | date | Transaction date | core.transaction.trans_date | FK to mart.dim_date |
| type_en | text | Credit (money in) or Withdrawal (out) | core.transaction.type_en | Translated |
| operation_en | text | Transaction method (remittance, cash, etc.) | core.transaction.operation_en | |
| k_symbol_en | text | Transaction character / category | core.transaction.k_symbol_en | Household, insurance, pension, etc. |
| amount | numeric(14,2) | Absolute transaction magnitude | core.transaction.amount | Always positive |
| signed_amount | numeric(14,2) | Signed cash flow (+ in, - out) | core.transaction.signed_amount | For running balances |
| balance | numeric(14,2) | Reported account balance post-transaction | core.transaction.balance | Reconciled in BMI-4 |

---

## mart.fact_loan
**Grain:** One row per approved loan contract.  
**Source:** `core.loan`  

| Column | Type | Meaning | Source | Notes |
|---|---|---|---|---|
| loan_id | int | Loan contract identifier | core.loan.loan_id | Primary key |
| account_id | int | Account receiving the loan | core.loan.account_id | FK to mart.dim_account |
| loan_date | date | Loan origination date | core.loan.loan_date | FK to mart.dim_date |
| amount | numeric(14,2) | Principal loan amount (CZK) | core.loan.amount | |
| duration_months | int | Repayment term in months | core.loan.duration_months | 12 to 60 months |
| monthly_payment | numeric(14,2) | Monthly instalment amount | core.loan.monthly_payment | |
| status | char(1) | Raw bank status code | core.loan.status | A, B, C, D |
| status_en | text | English status description | core.loan.status_en | Finished or Running |
| is_default | boolean | True if loan defaulted (B or D) | core.loan.is_default | Credit risk target |
| is_finished | boolean | True if contract closed (A or B) | core.loan.is_finished | |

---

## mart.fact_account_month
**Grain:** One row per account per month-end (monthly periodic snapshot).  
**Source:** `core.account`, `mart.dim_date`, `core.transaction`  

| Column | Type | Meaning | Source | Notes |
|---|---|---|---|---|
| account_id | int | Account identifier | core.account.account_id | Composite PK (with month_end) |
| month_end | date | Month-end calendar date | mart.dim_date.month_end | Composite PK (with account_id) |
| txn_count | bigint | Number of transactions in month | core.transaction | 0 if inactive month |
| inflow | numeric | Total money deposited in month | core.transaction | Inflow sum |
| outflow | numeric | Total money withdrawn in month | core.transaction | Outflow sum |
| is_active | boolean | True if at least 1 transaction occurred | derived | txn_count > 0 |
| end_balance | numeric | Closing balance at month-end | core.transaction.balance | Carried forward through inactive months |
