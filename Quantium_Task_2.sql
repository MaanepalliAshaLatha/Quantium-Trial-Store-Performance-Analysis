USE quantium_project;

CREATE TABLE qvi_data (
LYLTY_CARD_NBR INT,
TXN_DATE VARCHAR(20),
STORE_NBR INT,
TXN_ID INT,
PROD_NBR INT,
PROD_NAME VARCHAR(255),
PROD_QTY INT,
TOT_SALES DECIMAL(10,2),
PACK_SIZE INT,
BRAND VARCHAR(100),
LIFESTAGE VARCHAR(100),
PREMIUM_CUSTOMER VARCHAR(50)
);

SELECT * FROM qvi_data LIMIT 5;
desc qvi_data;

CREATE VIEW monthly_metrics AS
SELECT 
    STORE_NBR,
    concat(year(txn_date), LPAD(month(txn_date),2,'0')) AS YEARMONTH,
    sum(tot_sales) AS totSales,
    count(distinct lylty_card_nbr) AS nCustomers,
    count(txn_id)/count(distinct lylty_card_nbr) AS nTxnPerCust,
    sum(tot_sales)/sum(prod_qty) AS avgPricePerUnit
FROM qvi_data
GROUP BY STORE_NBR, YEARMONTH
ORDER BY STORE_NBR, YEARMONTH;

-- Step 1: find stores that have all pre-trial months
-- Step 2: filter monthly_metrics to pre-trial only, for those stores

CREATE VIEW pre_trial AS
SELECT *
FROM monthly_metrics
WHERE YEARMONTH < 201902
AND STORE_NBR IN (
    SELECT STORE_NBR
    FROM monthly_metrics
    WHERE YEARMONTH < 201902
    GROUP BY STORE_NBR
    HAVING COUNT(*) = 7
);


SELECT
a.STORE_NBR as trial_store,
b.STORE_NBR as control_store,
a.YEARMONTH,
ABS(a.totSales - b.totSales) as abs_diff
FROM (select *
from pre_trial
where store_nbr=77) AS a
JOIN (select *
from pre_trial
where store_nbr<>77) AS b
ON a.YEARMONTH = b.YEARMONTH;

SELECT
    control_store,
 avg(1 - (abs_diff - min_diff) / (max_diff - min_diff)) AS avg_magnitude_score
 from(
SELECT 
    trial_store,
    control_store,
    YEARMONTH,
    abs_diff,
    MIN(abs_diff) OVER (PARTITION BY YEARMONTH) as min_diff,
    MAX(abs_diff) OVER (PARTITION BY YEARMONTH) as max_diff
FROM (
	SELECT
	a.STORE_NBR as trial_store,
	b.STORE_NBR as control_store,
	a.YEARMONTH,
	ABS(a.totSales - b.totSales) as abs_diff
	FROM (select *
	from pre_trial
	where store_nbr=88) AS a
	JOIN (select *
	from pre_trial
	where store_nbr<>88) AS b
	ON a.YEARMONTH = b.YEARMONTH
) AS diffs
) AS Magnitude_diff
group by control_store
ORDER BY avg_magnitude_score DESC
LIMIT 5;


SELECT
*
FROM (select *
from pre_trial
where store_nbr=77) AS a
JOIN (select *
from pre_trial
where store_nbr=53) AS b
ON a.YEARMONTH = b.YEARMONTH;

select 
total_pre_trial_sales_for_store_77/total_pre_trial_sales_for_store_53 as scaling_factor
from(
select 
sum(case when store_nbr=77 then  totSales end) as total_pre_trial_sales_for_store_77,
sum(case when store_nbr=53 then  totSales end) as total_pre_trial_sales_for_store_53
from monthly_metrics
where YEARMONTH < 201902) x;

select
a.yearmonth,
a.Store_77_totSales,
a.Store_77_nCustomers,
a.Store_77_nTxnPerCust,
b.scaled_control_sales,
b.Store_53_nCustomers,
b.Store_53_nTxnPerCust,
abs(Store_77_totSales-scaled_control_sales) as diff
from
(select 
yearmonth,
sum(case when store_nbr=77 then  totSales end) as Store_77_totSales,
sum(case when store_nbr=77 then nCustomers end) as Store_77_nCustomers,
avg(case when store_nbr=77 then nTxnPerCust end) as Store_77_nTxnPerCust
from monthly_metrics
where YEARMONTH IN (201902, 201903, 201904)
GROUP BY YEARMONTH) as a
join
(select 
yearmonth,
sum(case when store_nbr=53 then  totSales end)*1.004159 as  scaled_control_sales,
sum(case when store_nbr=53 then nCustomers end) as Store_53_nCustomers,
avg(case when store_nbr=53 then nTxnPerCust end) as Store_53_nTxnPerCust
from monthly_metrics
where YEARMONTH IN (201902, 201903, 201904)
GROUP BY YEARMONTH) as b
ON a.YEARMONTH = b.YEARMONTH;


SELECT DISTINCT store_nbr 
FROM pre_trial 
ORDER BY store_nbr;

select 
total_pre_trial_sales_for_store_86/total_pre_trial_sales_for_store_10 as scaling_factor
from(
select 
sum(case when store_nbr=86 then  totSales end) as total_pre_trial_sales_for_store_86,
sum(case when store_nbr=10 then  totSales end) as total_pre_trial_sales_for_store_10
from monthly_metrics
where YEARMONTH < 201902) x;

select
a.yearmonth,
a.Store_86_totSales,
a.Store_86_nCustomers,
a.Store_86_nTxnPerCust,
b.scaled_control_sales,
b.Store_10_nCustomers,
b.Store_10_nTxnPerCust,
abs(Store_86_totSales-scaled_control_sales) as diff
from
(select 
yearmonth,
sum(case when store_nbr=86 then  totSales end) as Store_86_totSales,
sum(case when store_nbr=86 then nCustomers end) as Store_86_nCustomers,
avg(case when store_nbr=86 then nTxnPerCust end) as Store_86_nTxnPerCust
from monthly_metrics
where YEARMONTH IN (201902, 201903, 201904)
GROUP BY YEARMONTH) as a
join
(select 
yearmonth,
sum(case when store_nbr=10 then  totSales end)*0.952550 as  scaled_control_sales,
sum(case when store_nbr=10 then nCustomers end) as Store_10_nCustomers,
avg(case when store_nbr=10 then nTxnPerCust end) as Store_10_nTxnPerCust
from monthly_metrics
where YEARMONTH IN (201902, 201903, 201904)
GROUP BY YEARMONTH) as b
ON a.YEARMONTH = b.YEARMONTH;

select 
total_pre_trial_sales_for_store_88/total_pre_trial_sales_for_store_56 as scaling_factor
from(
select 
sum(case when store_nbr=88 then  totSales end) as total_pre_trial_sales_for_store_88,
sum(case when store_nbr=56 then  totSales end) as total_pre_trial_sales_for_store_56
from monthly_metrics
where YEARMONTH < 201902) x;

select
a.yearmonth,
a.Store_88_totSales,
a.Store_88_nCustomers,
a.Store_88_nTxnPerCust,
b.scaled_control_sales,
b.Store_56_nCustomers,
b.Store_56_nTxnPerCust,
abs(Store_88_totSales-scaled_control_sales) as diff
from
(select 
yearmonth,
sum(case when store_nbr=88 then  totSales end) as Store_88_totSales,
sum(case when store_nbr=88 then nCustomers end) as Store_88_nCustomers,
avg(case when store_nbr=88 then nTxnPerCust end) as Store_88_nTxnPerCust
from monthly_metrics
where YEARMONTH IN (201902, 201903, 201904)
GROUP BY YEARMONTH) as a
join
(select 
yearmonth,
sum(case when store_nbr=56 then  totSales end)*0.862090 as  scaled_control_sales,
sum(case when store_nbr=56 then nCustomers end) as Store_56_nCustomers,
avg(case when store_nbr=56 then nTxnPerCust end) as Store_56_nTxnPerCust
from monthly_metrics
where YEARMONTH IN (201902, 201903, 201904)
GROUP BY YEARMONTH) as b
ON a.YEARMONTH = b.YEARMONTH;

SELECT 
    a.YEARMONTH,
    a.totSales AS store_77_sales,
    b.totSales * 1.0042 AS store_53_scaled
FROM
    (SELECT YEARMONTH, totSales FROM monthly_metrics WHERE STORE_NBR = 77) a
JOIN
    (SELECT YEARMONTH, totSales FROM monthly_metrics WHERE STORE_NBR = 53) b
ON a.YEARMONTH = b.YEARMONTH
ORDER BY a.YEARMONTH;

SELECT 
    a.YEARMONTH,
    a.totSales AS store_86_sales,
    b.totSales * 0.9526 AS store_10_scaled
FROM
    (SELECT YEARMONTH, totSales FROM monthly_metrics WHERE STORE_NBR = 86) a
JOIN
    (SELECT YEARMONTH, totSales FROM monthly_metrics WHERE STORE_NBR = 10) b
ON a.YEARMONTH = b.YEARMONTH
ORDER BY a.YEARMONTH;

SELECT 
    a.YEARMONTH,
    a.totSales AS store_88_sales,
    b.totSales * 0.8621 AS store_56_scaled
FROM
    (SELECT YEARMONTH, totSales FROM monthly_metrics WHERE STORE_NBR = 88) a
JOIN
    (SELECT YEARMONTH, totSales FROM monthly_metrics WHERE STORE_NBR = 56) b
ON a.YEARMONTH = b.YEARMONTH
ORDER BY a.YEARMONTH;