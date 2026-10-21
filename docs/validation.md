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
