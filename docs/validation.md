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
