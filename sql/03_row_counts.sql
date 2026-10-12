-- 03_row_counts.sql : compare loaded rows with the counts the dataset guide says to expect
SELECT 'account' AS table_name, COUNT(*) AS loaded_rows, 4500 AS expected_rows FROM stg.account
UNION ALL SELECT 'client',          COUNT(*), 5369    FROM stg.client
UNION ALL SELECT 'disp',            COUNT(*), 5369    FROM stg.disp
UNION ALL SELECT 'permanent_order', COUNT(*), 6471    FROM stg.permanent_order
UNION ALL SELECT 'trans',           COUNT(*), 1056320 FROM stg.trans
UNION ALL SELECT 'loan',            COUNT(*), 682     FROM stg.loan
UNION ALL SELECT 'card',            COUNT(*), 892     FROM stg.card
UNION ALL SELECT 'district',        COUNT(*), 77      FROM stg.district;
