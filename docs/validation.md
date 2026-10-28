# Model & Visual Validation — Activity Page (Day 13)

**Objective:** Validate that Power BI model measures match the underlying SQL data in `mart.fact_transaction` exactly.

| Month | Metric | Power BI Value | SQL Value | Match | Notes |
|---|---|---|---|:---:|---|
| 1997-03 | Transactions | 20,491 | 20,491 | ✅ | Exact match |
| 1997-03 | Transaction Value | 120,829,178.80 | 120,829,178.80 | ✅ | Exact match to the cent |
| 1997-06 | Transactions | Verified via SQL & Line Chart | Verified | ✅ | Model & DAX match |
| 1997-06 | Transaction Value | Verified via SQL & Line Chart | Verified | ✅ | Model & DAX match |
| 1997-09 | Transactions | Verified via SQL & Line Chart | Verified | ✅ | Model & DAX match |
| 1997-09 | Transaction Value | Verified via SQL & Line Chart | Verified | ✅ | Model & DAX match |

**Conclusion:** Base measures (`Transactions`, `Transaction Value`) correctly aggregate transactions across `dim_date` grain with zero variance.

## Azure SQL Migration & Cloud Refresh Validation (Day 14 — BMI-15)

**Objective:** Validate that mart table row counts in Azure SQL (`bankmi`) match PostgreSQL (`bank_mi`) with zero loss, and that cloud refresh operates without an on-premises data gateway.

### 1. Mart Table Row Count Reconciliation

| Table | PostgreSQL Row Count | Azure SQL Row Count | Variance | Match |
|---|---|---|---|:---:|
| `dim_account` | 4,500 | 4,500 | 0 | ✅ |
| `dim_date` | 2,191 | 2,191 | 0 | ✅ |
| `dim_district` | 77 | 77 | 0 | ✅ |
| `fact_account_month` | 185,615 | 185,615 | 0 | ✅ |
| `fact_loan` | 682 | 682 | 0 | ✅ |
| `fact_transaction` | 1,056,320 | 1,056,320 | 0 | ✅ |

### 2. Cloud Refresh Performance
- **Report & Model:** `bank_mi_pack_cloud.pbix`
- **Data Source:** Azure SQL Database (`sql-ancy-da.database.windows.net`, db `bankmi`)
- **Gateway Requirement:** None (direct cloud-to-cloud encrypted connection)
- **First Cloud Refresh:** 2026-10-21 16:00:05 (Completed in 14 seconds)
- **Scheduled Refresh:** Configured twice daily (07:00 and 13:00 GST)
- **Proof:** Screenshot stored at `images/cloud_refresh_history.png`

## KPI Measures Validation (Day 15 — BMI-5)

**Objective:** Validate that Power BI KPI measures (`Loans`, `Defaulted Loans`, `Default Rate`) match database SQL queries across `mart.fact_loan`.

### 1. SQL Query Used
```sql
SELECT COUNT(*) AS loans,
       COUNT(*) FILTER (WHERE is_default) AS defaulted,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_default) / COUNT(*), 1) AS default_rate_pct
FROM mart.fact_loan;
```

### 2. Reconciliation Matrix
| Metric | Power BI Unfiltered Visual | SQL Ground Truth | Variance | Self-Check (N06) |
|---|---|---|---|:---:|
| `Loans` | 682 | 682 | 0 | ✅ PASS |
| `Defaulted Loans` | 76 | 76 | 0 | ✅ PASS |
| `Default Rate` | 11.1% | 11.1% | 0.0% | ✅ PASS |


### 3. Time Intelligence MoM % Validation (N11)
| Month | Power BI MoM % | SQL / S06 Baseline | Variance | Self-Check (N11) |
|---|---|---|---|:---:|
| `1997-03` | 14.9% | 14.89% | 0.0% | ✅ PASS |
| `1998-12` | 15.4% | 15.36% | 0.0% | ✅ PASS |


### 4. Customer Cards Validation (N08)
| Metric | Power BI Value | Baseline / Target | Match | Self-Check (N08) |
|---|---|---|:---:|:---:|
| `Accounts with Card` | 892 | 892 | ✅ | ✅ PASS |
| `Card Penetration` | 19.8% | 19.8% | ✅ | ✅ PASS |

### 5. Period-End Balance Validation — 1998 (N09)
| Metric | Power BI Value (1998) | Baseline / Target | Match | Self-Check (N09) |
|---|---|---|:---:|:---:|
| `Avg Period-End Balance` | 43,809 | 43,809 | ✅ | ✅ PASS |
| `Total Period-End Balance` | 197,140,234 | 197,140,234 | ✅ | ✅ PASS |


## Card Cross-Sell List Validation (Day 21 — BMI-7)

**Objective:** Validate that the target accounts on the card cross-sell list match the physical CSV export, database ground truth, and the Power BI Cross-sell visual exactly.

### 1. Row Count & Target Reconciliation
| Source / Artifact | Measure / Row Count | Variance vs Target | Match | Self-Check (N10) |
|---|---|---|:---:|:---:|
| **SQL Mart Ground Truth** (`mart.cross_sell_list`) | 1,460 accounts | 0 | ✅ | ✅ PASS |
| **Physical CSV Export** (`cross_sell_list.csv`) | 1,460 rows (1,461 lines − 1 header) | 0 | ✅ | ✅ PASS |
| **Power BI Visual** (`[Target Accounts]` card) | 1,460 accounts | 0 | ✅ | ✅ PASS |

### 2. Campaign Definition Criteria
- Active in the last 3 months of data (`txn_last3 > 0`)
- No existing credit card (`NOT has_card`)
- Average period-end balance at or above the 3-month active median (`avg_end_balance_last3 >= median_balance`)
- No defaulted loan (`NOT is_default`)
