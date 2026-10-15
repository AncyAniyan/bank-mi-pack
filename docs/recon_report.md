# Reconciliation report — Bank Account Balances — 2026-10-15
**Bottom line:** Reported account balances are reliable for month-end MI and financial reporting. Out of 4,500 accounts, zero accounts (0) have material breaks. All discrepancies are either same-day ordering differences or minor cumulative interest rounding drift (maximum gap across the entire 5-year dataset is only 2.80 CZK).

## Method
We compared the reported transaction balance (`core.transaction.balance`) against a recomputed running balance calculated from transaction cash flows (`signed_amount`) partitioned by account and ordered chronologically.
To account for same-day batch processing, we performed an **End-of-Day (EOD)** reconciliation comparing the reported end-of-day balance to the cumulative net daily flows, using a business tolerance threshold of **5.00 CZK**.

## Results
| Measure | Value | % of Total |
|---|---|---|
| Rows checked | 1,056,320 | 100.0% |
| Rows with row-level difference (> 0.01 CZK) | 865,166 | 81.9% |
| Accounts with row-level difference | 4,452 | 98.9% |
| Accounts checked | 4,500 | 100.0% |

## Breaks by category
| Category | Accounts | % Accounts | Largest EOD Gap | Likely root cause |
|---|---|---|---|---|
| **A: Exact at every transaction** | 48 | 1.1% | 0.00 CZK | Accounts with single transactions per day or strict timestamp ordering. |
| **B: Same-day ordering only (EOD exact)** | 20 | 0.4% | 0.00 CZK | Multiple same-day transactions where ledger posting order differed from database `trans_id` sequence, but daily net reconciles to 0.00. |
| **C: Small drift within tolerance (<= 5 CZK)** | 4,432 | 98.5% | 2.80 CZK | Cumulative month-end rounding drift on automated interest credits and statement fee deductions over 5 years of activity. |
| **D: Material break (> 5 CZK)** | 0 | 0.0% | 0.00 CZK | None. No missing transaction batches or ledger breaks detected. |

## Root Cause Analysis (Category C Investigation)
Detailed transaction-level audit of Category C accounts (e.g. Account 1, Account 2, Account 10) confirmed:
1. Discrepancies first appear on month-end dates (e.g. `1995-08-31`) when automated batch processes execute simultaneously:
   - Automated debit: Statement fee (`-14.60 CZK`, `k_symbol = Statement fee`)
   - Automated credit: Monthly interest (`+99.20 CZK`, `k_symbol = Interest credited`)
2. In the core banking engine, interest was applied before fee deduction, while table rows recorded the statement fee with an earlier `trans_id`.
3. Fractional interest rounding (daily accrual rounded to 2 decimal places at month-end credit) compounds over 60 months, creating harmless micro-drifts capped at 2.80 CZK.

## What this means for the business
- **Ledger Integrity:** The transaction history accurately accounts for 100% of funds across 1.05M records without unexplained leakages.
- **Reporting Usage:** Month-end reported balances can be trusted for executive dashboards, customer statements, and portfolio reporting.
- **Reporting Grain:** For accurate daily cash flow analytics, reporting should aggregate at the **account-day grain (EOD)** rather than intra-day row level to eliminate ordering artifacts.

## Recommendation
1. **Adopt End-of-Day aggregation:** Model fact tables at the account-month and account-day grain (`mart.fact_account_month`) rather than displaying intra-day running balances.
2. **Maintain 5 CZK Tolerance Rule:** Establish automated monthly reconciliation checks flagging accounts with EOD divergence > 5.00 CZK for manual operations review.
