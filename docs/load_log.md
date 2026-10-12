# Data Load Log (Staging)

- **Date:** 2026-10-12
- **Database:** `bank_mi` (PostgreSQL 18)
- **Source Files:** `~/data/berka/*.asc`
- **Verification:** Self-check `N01` PASS

| Table Name | Loaded Rows | Expected Rows | Difference | Status / Explanation |
|---|---|---|---|---|
| `stg.account` | 4,500 | 4,500 | 0 | Exact match |
| `stg.client` | 5,369 | 5,369 | 0 | Exact match |
| `stg.disp` | 5,369 | 5,369 | 0 | Exact match |
| `stg.permanent_order` | 6,471 | 6,471 | 0 | Exact match |
| `stg.trans` | 1,056,320 | 1,056,320 | 0 | Exact match (1.05M records loaded cleanly) |
| `stg.loan` | 682 | 682 | 0 | Exact match |
| `stg.card` | 892 | 892 | 0 | Exact match |
| `stg.district` | 77 | 77 | 0 | Exact match |
