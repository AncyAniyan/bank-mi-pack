# Retail Banking MI Pack & Loan Portfolio Risk Review — Business Requirements Document
Version: v0.9 — draft for review — 2026-10-13   Owner: Ancy Aniyan

## 1. Background and problem
Retail Banking leadership currently relies on a manually assembled monthly Excel report. Figures frequently disagree between Finance and Retail, causing friction and delaying commercial decisions. Furthermore, Credit Risk cannot detect early-warning behavioural signals before personal loans enter default, and branch managers lack a qualified, governed list of customers for credit card cross-selling. The bank requires a fully automated, auditable, and reconciled Management Information (MI) pack with self-service Power BI analytics.

## 2. Objectives and success criteria
| Objective | Success criterion (measurable) |
|---|---|
| Trusted monthly MI pack | Numbers reconcile to transaction history with 100% of breaks categorized; automated DQ pass rate ≥ 95% |
| Early-warning credit risk visibility | Default rates segmented by district, loan duration, and pre-loan balance behaviour with explicit denominators |
| Targeted card cross-sell program | Automated qualification list of active customers with no cards and above-median balance to drive branch outreach |
| Governed self-service analytics | Power BI report with sub-3-second visual load times and district-level Row-Level Security (RLS) |

## 3. Scope
- **In scope:** Historical retail banking dataset (1993–1998) covering 4,500 accounts, 5,369 clients, 1,056,320 transactions, 682 loans, 892 credit cards, and 77 districts. Automated PostgreSQL ETL pipeline (`stg`, `ref`, `core`, `mart`), automated DQ and balance reconciliation test suites, and 5-page Power BI dashboard (Executive, Activity, Credit Risk, Cross-sell, Data Quality).
- **Out of scope:** Real-time transaction streaming; machine learning / predictive default scoring models; transactional core banking write operations.

## 4. Stakeholders and RACI
| Stakeholder | Role | R | A | C | I |
|---|---|---|---|---|---|
| Head of Retail Banking | Sponsor & Commercial Owner | C | A | R | I |
| Credit Risk Manager | Risk & Policy Owner | C | A | R | I |
| Finance Controller | Financial Reconciliation Owner | C | A | R | I |
| Branch Network Manager | Operational End User | I | I | C | R |
| Data Owner / IT | Data Governance & Architecture Owner | R | A | C | I |
| Lead Data Analyst (Ancy Aniyan) | Analytics Implementation Lead | R | A | C | I |

*Legend: R = Responsible, A = Accountable, C = Consulted, I = Informed.*

## 5. KPI definitions
| KPI | Formula | Grain | Filters / exclusions | Owner |
|---|---|---|---|---|
| Active accounts | Accounts with ≥ 1 transaction in the period | Account × month | `mart.fact_account_month.is_active = true` | Head of Retail |
| Transaction count / value | `COUNT(*)` / `SUM(amount)` of transactions | Transaction | Completed transactions | Head of Retail |
| Net flow | `SUM(signed_amount)` (+ credit, − withdrawal) | Transaction | None | Finance |
| MoM growth % | `(Current Month Value − Prior Month Value) / Prior Month Value` | Month | Total transaction value | Head of Retail |
| Average period-end balance | Average of account balances at the latest month-end | Account × month | Semi-additive balance snapshot | Finance |
| Loan default rate | Loans with status B or D / Total loans | Loan | Status in ('A','B','C','D') | Credit Risk |
| Finished-loan default rate | Loans with status B / (Loans status A + B) | Loan | Closed loans only | Credit Risk |
| Loan exposure | `SUM(loan amount)` | Loan | Active and historical loans | Credit Risk |
| Card penetration | Accounts with ≥ 1 card / Total accounts | Account | Owner dispositions | Head of Retail |
| Cross-sell list size | Accounts active in last 3 months, no card, balance ≥ median, no defaulted loan | Account | Qualified cross-sell criteria | Head of Retail |
| DQ pass rate | Checks with 0 failures / Total checks | Check run | Automated DQ suite | Data Owner |
| Reconciliation break rate | Accounts with balance break / Total accounts | Account | End-of-day tolerance | Finance |

## 6. Data sources and assumptions
| Source | Description | Refresh | Known issues |
|---|---|---|---|
| Berka / PKDD'99 Anonymised Banking Data | 8 tables: `account`, `client`, `disp`, `order`, `trans`, `loan`, `card`, `district` | Historical batch load | Czech language codes; `YYMMDD` integer dates; birth numbers encoding gender; undocumented transaction type (`VYBER`) |

**Assumptions:**
- **Currency:** Czech koruna (CZK) maintained for strict accounting fidelity; retail banking KPIs align with UAE/GCC banking reporting standards.
- **Dates:** Data spans 1993–1998; 2-digit years represent 1900s (`19YY`).
- **Anonymisation:** Client identifying data is fully anonymised and compliant with privacy standards.

## 7. Functional requirements
| ID | Requirement | Ticket |
|---|---|---|
| FR-01 | Ingest 8 raw files into staging with row count reconciliation against source manifests | BMI-1 |
| FR-02 | Translate Czech reference codes into English with unmapped code defect tracking | BMI-2 |
| FR-03 | Build typed core tables, decoding birth numbers into birth date and gender | BMI-3 |
| FR-04 | Reconcile running transaction balances against reported balances and classify breaks | BMI-4 |
| FR-05 | Deliver monthly customer activity, volume, and MoM trend metrics | BMI-5 |
| FR-06 | Deliver loan default risk analysis by district, term, and pre-loan balance behaviour | BMI-6 |
| FR-07 | Generate automated credit card cross-sell targeting list for branch outreach | BMI-7 |
| FR-08 | Implement dimensional star schema (`mart`) optimized for Power BI consumption | BMI-8 |
| FR-09 | Enforce district-level Row-Level Security (RLS) for branch managers | BMI-9 |
| FR-10 | Deliver executive dashboard with formal UAT test execution and stakeholder sign-off | BMI-10 |
| FR-14 | Implement automated data-quality rule suite (≥ 14 checks) with defect logging | BMI-14 |


### 7.1 Card Cross-Sell Campaign Measurement & Control Group Design (BMI-7)
To evaluate the true causal uplift of the branch outreach campaign rather than attributing natural organic conversion to the sales team, Retail Banking will execute an A/B holdout test structure:
- **Target Population:** The 1,460 qualified accounts identified in `mart.cross_sell_list` (active in the last 3 months, no existing credit card, average end balance at or above the active median, and zero defaulted loans).
- **Control Group (10% Holdout):** A randomly selected 10% sample (~146 accounts) will be flagged and excluded from all branch relationship manager outreach, direct mail, and marketing calls.
- **Treatment Group (90% Outreach):** The remaining 90% (~1,314 accounts) will receive proactive branch relationship manager outreach.
- **Effectiveness Measurement:** At the end of the 90-day campaign window, credit card adoption rates between the two cohorts will be evaluated:
  $$\\text{Incremental Uplift} = \\text{Take-up Rate}_{\\text{treatment}} - \\text{Take-up Rate}_{\\text{control}}$$
Only positive incremental uplift demonstrates marketing ROI and justifies expanding the cross-sell initiative to other product lines.

## 8. Non-functional requirements
- **Reproducibility:** Entire ETL pipeline in PostgreSQL and Power Query must run end-to-end without manual data edits.
- **Performance:** Power BI visuals must load in under 3 seconds using VertiPaq in-memory storage.
- **Security & Governance:** District-level Row-Level Security (RLS) enforced; complete data dictionary and decision logs maintained.
- **Auditability:** 100% of balance discrepancies categorized and explained.

## 9. Data-quality approach
- Automated rule suite (`sql/06_dq_checks.sql`) executing ≥ 14 structural, referential, and business logic checks.
- Execution history logged to `dq.results` with timestamps.
- Every failure triaged: classified as either a genuine data defect (logged in `defect_log.md`) or rule adjustment (logged in `decision_log.md`).
- Checks categorized into daily production controls versus one-time onboarding checks.

## 10. UAT approach
- Testing executed on Day 26 against pre-defined test cases mapped directly to FR-01 through FR-10.
- Minimum 15 test cases covering data reconciliation, visual filtering, RLS security isolation, and DAX measure accuracy.
- Formal sign-off recorded in `docs/uat_signoff.md`.

## 11. Risks and mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Small loan sample sizes in certain rural districts | Misleading default percentages | Flag groups with < 10 loans; display explicit sample denominators on all visuals |
| Legacy 1990s data conventions | Misinterpreted business attributes | Translation mapping table (`ref.code_map`) and documented data dictionary |
| Undocumented transaction codes | Misstated cash flows or balance breaks | Automated unmapped code detection, defect log tracking, and signed amount logic |

## 12. Sign-off
| Name / role | Decision | Date |
|---|---|---|
| Head of Retail Banking (Sponsor) | Pending review | |
| Credit Risk Manager | Pending review | |
| Finance Controller | Pending review | |
| Data Owner / IT | Pending review | |
