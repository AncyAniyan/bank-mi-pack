| ID | Date | Table / column | Rule broken | Rows affected | Business impact | Root cause (likely) | Decision / fix | Verification query | Status |
|---|---|---|---|---|---|---|---|---|---|
| DEF-001 | 2026-10-13 | trans.type | Undocumented code; only PRIJEM and VYDAJ expected | 16,666 | Misclassified cash flows if unmapped | Source system wrote operation VYBER into type column | Treat as money out (withdrawal) in core tables | SELECT count(*) FROM stg.trans WHERE trim(type) = 'VYBER'; | Open |
