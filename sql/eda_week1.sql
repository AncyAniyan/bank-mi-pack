--Question 1: What is the first and last transaction date?
SELECT min(trans_date) as first_date ,max(trans_date) as last_date from core."transaction" t ;
--Find:Exactly 6 full calendar years of data: 1993-01-01 to 1998-12-31.


--Ques2.How many accounts were opened per year?
select extract(year from opened_date) as year,count(account_id) from core."account" a  group by year order by year;
---Find:he total equals exactly 4,500 accounts (1,139 + 439 + 661 + 1,363 + 898).
---1. 1996 was the peak opening year (1,363 accounts).
---2. Zero accounts were opened in 1998 (the bank stopped onboarding or the dataset only tracks existing accounts in 1998).


---Question 3: Transaction count and total value per year.
select extract(year from trans_date) as year,count(trans_id),sum(amount) from core.transaction group by year order by year;

---1. Transaction volume exploded from 28.2k (1993) to 322.3k (1998)—an increase of over 11x!
---2.Transaction value grew from 204.3M to 1.89B CZK.
---3. Total transactions = 1,056,320 (100% accounted for).


----Question 4: Share of transactions by operation (operation_en), including NULLs as '(none)'.
select COALESCE(operation_en, '(none)'),count(*) as count_of_operation,ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)as percentage_share from core."transaction" t group by operation_en order by count_of_operation desc ;

--183,114 transactions (17.34%) have no operation code at all


----Question 5:Top 10 k_symbol_en values by total value.
select  coalesce(k_symbol_en,'(none)')as purpose_category,count(trans_id) as count_of_total,sum(amount) as total_amount from core."transaction" t group by k_symbol_en order by total_amount desc limit 10;

---In Question 4, exactly 183,114 transactions had no operation ((none)). And in Question 5, Interest credited has exactly 183,114 transactions!
---That solves the mystery: interest credits are automated bank entries, so they have no manual operation type


----Que6:Loans by status, with count and total amount.
select count(loan_id) as count_of_loan,sum(amount) as total_loan_amount,status,status_en  from core.loan group by status,status_en order by status desc;
---Status B (31): Finished loans that were not repaid (historical default).
----Status D (45): Running loans where the client is in debt (active default).
---In banking credit risk, both B and D are defaults! So total loans in default = 31 + 45 = 76 loans (out of 682 total loans, giving a 11.1% default rate)



---Question 7: Cards by type.
select count(card_id) as count_of_card,card_type from core.card c group by card_type order by count_of_card desc; 
---Total cards = 892 (659 classic, 145 junior, 88 gold). Across 4,500 accounts, that is only ~20% card penetration

----Question 8: Average reported balance by region, using each account's last transaction.
WITH latest_trans AS (
    SELECT account_id, balance,
           ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY trans_date DESC, trans_id DESC) AS rn
    FROM core.transaction
)
select round(avg(la.balance),2) as average_balance,dis.region from latest_trans as la join core.account as acct on la.account_id=acct.account_id join core.district as dis on acct.district_id=dis.district_id where la.rn=1 group by dis.region order by average_balance desc;
-- Results:
-- Prague: 44,939.82 CZK (highest average account balance)
-- north Moravia: 44,136.20 CZK
-- north Bohemia: 44,127.93 CZK
-- central Bohemia: 43,818.06 CZK
-- south Moravia: 43,727.01 CZK
-- west Bohemia: 43,636.90 CZK
-- east Bohemia: 43,494.20 CZK
-- south Bohemia: 41,841.10 CZK (lowest average account balance)

---Task: Find the number of accounts that have no transactions at all.
----Tables: core.account and core.transaction
select count(a.account_id )as n_accounts from  core.account a left join core."transaction" t on t.account_id =a.account_id where t.account_id is null ;

---Task: For every account, find:account_id first_date (earliest transaction date) last_date (latest transaction date) n_transactions (number of transactions) days_between (the number of days between first and last date)
select account_id,min(trans_date) as first_date,max(trans_date) as last_date,count(trans_id) as n_transactions,(max(trans_date)-min(trans_date)) as days_between from core."transaction" t group by account_id

---Task:

