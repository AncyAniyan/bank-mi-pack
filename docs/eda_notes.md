# Week 1 Exploratory Data Analysis (EDA) Notes
**Author:** Ancy Aniyan (Lead Data Analyst)  
**Date:** 2026-10-13  
**Dataset:** Berka Czech Retail Banking (1993–1998)

## Executive Summary for Management

1. **Transaction Velocity & Value Growth:**  
   Annual transaction volume experienced an **11.4x expansion** between 1993 and 1998 (rising from 28,205 transactions in 1993 to 322,277 in 1998). Total transaction turnover grew more than ninefold from **204.3M CZK to 1.89B CZK**, reflecting aggressive customer activity and deepening banking relationships across the 6-year period.

2. **Customer Acquisition Dynamics:**  
   Account onboarding concentrated heavily between 1993 and 1997 across all 4,500 accounts. Acquisition peaked in **1996 with 1,363 accounts opened (30.3% of total portfolio)**, followed by 898 in 1997. Zero accounts were onboarded in 1998, indicating that 1998 represents an activity-monitoring period for existing cohorts rather than new acquisition.

3. **Automated Batch Processing & Operation Code Absence:**  
   Exactly **183,114 transactions (17.34% of all 1,056,320 transactions)** have no operation code (`(none)`). Our cross-analysis confirms that 100% of these rows represent **Interest credited (`UROK`)**. They are system-generated monthly interest credits rather than customer-initiated branch or ATM operations. This finding is critical for our upcoming Data Quality suite (rule DQ-06).

4. **Loan Portfolio Risk & Default Rate:**  
   Out of 682 granted retail loans, **76 loans are in default** (31 finished unpaid contracts [Status B] and 45 active contracts with clients currently in debt [Status D]). This establishes an overall portfolio **default rate of 11.14%** and a **13.25% default rate among finished loans** (31 defaults / 234 closed loans). Total defaulted loan exposure stands at **15.58M CZK** (11.22M active in debt + 4.36M written off).

5. **Credit Card Penetration & Regional Liquidity:**  
   Across 4,500 accounts, only **892 cards have been issued (19.8% penetration)**, comprising 659 classic, 145 junior, and 88 gold cards. This leaves over **80% of account holders uncarded**, creating an immediate cross-sell commercial opportunity (BMI-7). Regionally, **Prague clients hold the highest average latest balance (44,939.82 CZK)**, while South Bohemia holds the lowest (41,841.10 CZK), indicating that credit card limits and premium tier offerings should be prioritized in Prague, North Moravia, and North Bohemia.
