DROP TABLE IF EXISTS ref.code_map;
CREATE TABLE ref.code_map (
  source_table  text,
  source_column text,
  code          text,
  label_en      text,
  PRIMARY KEY (source_table, source_column, code)
);
INSERT INTO ref.code_map VALUES
 ('trans','type','PRIJEM','Credit (money in)'),
 ('trans','type','VYDAJ','Withdrawal (money out)'),
 ('trans','operation','VYBER KARTOU','Credit card withdrawal'),
 ('trans','operation','VKLAD','Cash deposit'),
 ('trans','operation','PREVOD Z UCTU','Collection from another bank'),
 ('trans','operation','VYBER','Cash withdrawal'),
 ('trans','operation','PREVOD NA UCET','Remittance to another bank'),
 ('trans','k_symbol','POJISTNE','Insurance payment'),
 ('trans','k_symbol','SLUZBY','Statement fee'),
 ('trans','k_symbol','UROK','Interest credited'),
 ('trans','k_symbol','SANKC. UROK','Penalty interest (negative balance)'),
 ('trans','k_symbol','SIPO','Household payment'),
 ('trans','k_symbol','DUCHOD','Old-age pension'),
 ('trans','k_symbol','UVER','Loan payment'),
 ('order','k_symbol','POJISTNE','Insurance payment'),
 ('order','k_symbol','SIPO','Household payment'),
 ('order','k_symbol','LEASING','Leasing payment'),
 ('order','k_symbol','UVER','Loan payment'),
 ('account','frequency','POPLATEK MESICNE','Monthly statement'),
 ('account','frequency','POPLATEK TYDNE','Weekly statement'),
 ('account','frequency','POPLATEK PO OBRATU','Statement after each transaction'),
 ('loan','status','A','Finished - repaid'),
 ('loan','status','B','Finished - not repaid (default)'),
 ('loan','status','C','Running - OK so far'),
 ('loan','status','D','Running - client in debt (default)');

-- Codes that appear in the data but are NOT in the map (run after loading; every row here is a finding)
SELECT 'trans.type' AS field, trim(type) AS code, COUNT(*) AS n_rows
FROM stg.trans
WHERE trim(type) NOT IN (SELECT code FROM ref.code_map WHERE source_table='trans' AND source_column='type')
GROUP BY 2
UNION ALL
SELECT 'trans.operation', trim(operation), COUNT(*)
FROM stg.trans
WHERE NULLIF(trim(operation),'') IS NOT NULL
  AND trim(operation) NOT IN (SELECT code FROM ref.code_map WHERE source_table='trans' AND source_column='operation')
GROUP BY 2
UNION ALL
SELECT 'trans.k_symbol', trim(k_symbol), COUNT(*)
FROM stg.trans
WHERE NULLIF(trim(k_symbol),'') IS NOT NULL
  AND trim(k_symbol) NOT IN (SELECT code FROM ref.code_map WHERE source_table='trans' AND source_column='k_symbol')
GROUP BY 2;