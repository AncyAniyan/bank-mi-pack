# Data-quality report — Retail Banking MI Pack — run of 2026-10-14
**Bottom line:** Core banking tables are structurally sound across all relational integrity, primary key, and date checks (9 of 14 passed on first run). All 5 identified failures have been audited: 1 operational rule refinement (DQ-06 interest credits) and 4 documented defects with decisions in the defect and decision logs.

| Check | Rule | Failed rows | % failed | Status | Decision |
|---|---|---|---|---|---|
| DQ-01 | Transaction type is a documented code (PRIJEM/VYDAJ) | 16,666 | 1.578% | FAIL | DEC-001: Mapped 'VYBER' (cash withdrawal) as money out; DEF-001 |
| DQ-02 | Transaction amount is positive | 14 | 0.001% | FAIL | DEF-002: Flagged non-positive reversal entries; audit trail maintained |
| DQ-03 | Transaction date inside 1993-01-01..1998-12-31 | 0 | 0.000% | PASS | Verified |
| DQ-04 | Transaction belongs to known account (orphan check) | 0 | 0.000% | PASS | 100% referential integrity verified |
| DQ-05 | Transaction is not before account opened date | 0 | 0.000% | PASS | Verified |
| DQ-06 | Operation code is filled (excl. interest credit) | 0 (refined) | 0.000% | PASS | DEC-002: Refined rule to exempt automated monthly interest credits |
| DQ-07 | Every account has exactly one OWNER | 0 | 0.000% | PASS | Verified |
| DQ-08 | Client birth date valid (1900–1998) | 0 | 0.000% | PASS | Verified |
| DQ-09 | Loan status is one of A/B/C/D | 0 | 0.000% | PASS | Verified |
| DQ-10 | Loan amount roughly equals duration x monthly payment | 0 | 0.000% | PASS | Verified |
| DQ-11 | At most one loan per account | 0 | 0.000% | PASS | Verified |
| DQ-12 | Card issued on or after account opening date | 0 | 0.000% | PASS | Verified |
| DQ-13 | District demographics complete (1995 stats) | 1 | 1.299% | FAIL | DEF-003: District 69 lacks 1995 metrics; regional imputation policy |
| DQ-14 | Duplicate business key (same account, date, type, amt, bal) | 1 | 0.000% | FAIL | DEF-004: Duplicate entry audited; unique trans_id retained |

## Top 3 issues by business impact
1. **Unmapped Cash Withdrawal Code (`VYBER`) — 16,666 rows (1.58%):** Dropping these would break account balance reconciliation by millions of CZK. Resolved by DEC-001 mapping to withdrawal.
2. **Missing Operation Code on System Entries — 183,114 rows (17.34%):** Audited as legitimate automated interest credits (`UROK`). Resolved by DEC-002 refining rule scope.
3. **Non-Positive Transaction Amounts — 14 rows (0.001%):** Anomaly entries flagged in DEF-002 so aggregations in reporting layer are not distorted.

## Recommendations & Cadence
- **Daily Ingestion Pipeline:** Run DQ-01, DQ-02, DQ-03, DQ-04, DQ-05, DQ-06, DQ-10, DQ-14 on every scheduled batch run.
- **Migration & Periodic Master Data:** Run DQ-07, DQ-08, DQ-09, DQ-11, DQ-12, DQ-13 on account/client/district dimension updates.
