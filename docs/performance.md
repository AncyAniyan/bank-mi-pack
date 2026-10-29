# ⚡ Power BI Performance Analyzer Baseline (Day 22)

**Test Environment:** Power BI Desktop / Service (Cloud Semantic Model on Azure SQL Serverless)  
**Report:** `bank_mi_pack_cloud.pbix`  
**Date:** 2026-10-29  

## Visual Performance Baseline

Recorded using Power BI **Performance Analyzer** on fresh visual refresh across all report pages:

| Page | Visual | DAX Query (ms) | Visual Display (ms) | Other (ms) | Total Time (ms) | Under 3s SLA? |
|---|---|---|---|---|---|---|
| **Executive** | Executive KPI Cards (5 measures) | 48 ms | 62 ms | 15 ms | **125 ms** | ✅ PASS |
| **Executive** | Monthly Volume & Net Flow Clustered Chart | 110 ms | 85 ms | 22 ms | **217 ms** | ✅ PASS |
| **Activity** | Regional Balance Matrix | 185 ms | 120 ms | 35 ms | **340 ms** | ✅ PASS |
| **Credit Risk** | Loan Quality Matrix & Loss Exposure | 215 ms | 145 ms | 40 ms | **400 ms** | ✅ PASS |
| **Cross-sell** | Priority Accounts Table (1,460 rows grain) | 265 ms | 190 ms | 45 ms | **500 ms** | ✅ PASS |
| **Cross-sell** | District Account Count Bar Chart | 85 ms | 65 ms | 20 ms | **170 ms** | ✅ PASS |

## Observations & Findings
1. **SLA Compliance:** Every visual renders in **under 0.5 seconds** (500 ms), substantially faster than the 3.0-second corporate SLA limit.
2. **Slowest Visual:** The **Cross-sell Priority Table** (500 ms total, 265 ms DAX query) is the slowest visual because it renders individual account-level rows with client age bands and average balances.
3. **Week 9 Optimization Opportunities:**
   - Pre-aggregate client age-bands into `mart.fact_account_month` or `mart.cross_sell_list`.
   - Remove unused surrogate IDs and text descriptions from the imported semantic model in Power Query to reduce memory footprint.
