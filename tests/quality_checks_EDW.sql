/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'EDW' schemas. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related field.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
================================================================================
*/

-- ====================================================================
-- Checking 'EDW.crm_cust_info'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Resultes
SELECT 
cst_id,
COUNT(*)
FROM EDW.crm_cust_info
Group by cst_id
having COUNT(*) > 1 or cst_id is null

-- Check for unwanted spaces
-- Expectation: No results
Select 
cst_firstname
from EDW.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

Select 
cst_lastname
from EDW.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency
Select 
distinct cst_marital_status 
from EDW.crm_cust_info

select * from EDW.crm_cust_info

-- ====================================================================
-- Checking 'EDW.crm_prd_info'
-- ====================================================================
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
Select 
prd_id,
COUNT(*)
From
EDW.crm_prd_info
group by prd_id
having COUNT(*) > 1 or prd_id is null

-- Check for unwanted spaces of prd_nm
-- Expectation: No results
Select 
prd_nm
from EDW.crm_prd_info
where prd_nm != TRIM(prd_nm)

-- Check for Nulls or negative number of prd_cost
Select
prd_cost
from EDW.crm_prd_info
where prd_cost is null or prd_cost < 0

--Explore the prd_line
Select
distinct prd_line
from EDW.crm_prd_info

--Check for the invalid datet order
Select
distinct prd_key
from EDW.crm_prd_info
where prd_end_dt < prd_start_dt
--Solution: 
--1.Switch end date and start date. 
--Not good, because some product have the overlaping price in the same period, and some products have null start time.
--2.Ignore the conflicted effect of end time, focusing on start time to adjust price
--logically good, as some end date expected but in fact not working which can be switched to (the next updated start date - 1) as the actual end date.
--Try the solution 2:
Select 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
Dateadd(day,-1,LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt)) as prd_end_dt_test
From EDW.crm_prd_info
where prd_key in (Select
distinct prd_key
from stage.crm_prd_info
where prd_end_dt < prd_start_dt)

--Overall checking
Select *
From EDW.crm_prd_info

-- ====================================================================
-- Checking 'EDW.crm_sales_details'
-- ====================================================================
-- Check for invalid date
select
sls_due_dt
From 
EDW.crm_sales_details
Where 
cast(sls_due_dt as float) <= 0
or len(sls_due_dt) !=8 
or sls_due_dt > 20260101 
or sls_due_dt < 19000101

-- Check for invalid date order
select 
*
from
EDW.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_ship_dt > sls_due_dt

-- Check for data consistency： Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be null, zero or negative
select distinct
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
case 
	when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
	then sls_quantity * abs(sls_price) else sls_sales 
	end as sls_sales,
case 
	when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
	else sls_price end as sls_price
from EDW.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_quantity <= 0 or sls_sales <= 0 or sls_price <= 0
or sls_quantity is null or sls_sales is null or sls_price is null
order by sls_sales,
sls_quantity,
sls_price
-- >> Find expert for discussion.
-- >> Common solution: 
-- >> If sales are null/-n/0, calculate by quantity * ABS(price). 
-- >> If price are null/-n/0, calculate by ABS(sales)/quantity.

--rechecking for sales, quantity and price after cleansing:
select distinct
sls_quantity,
sls_sales,
sls_price
from EDW.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_quantity <= 0 or sls_sales <= 0 or sls_price <= 0
or sls_quantity is null or sls_sales is null or sls_price is null
order by sls_sales,
sls_quantity,
sls_price

select * from EDW.crm_sales_details

-- ====================================================================
-- Checking 'EDW.erp_px_cat_g1v2'
-- ====================================================================
-- ID checking
select id from stage.erp_px_cat_g1v2
where id in (select cat_id from [EDW].[crm_prd_info])

-- Checking for unwanted space of cat, subcat and maintenance
select * from stage.erp_px_cat_g1v2
where TRIM(cat) != cat or TRIM(subcat) != subcat or TRIM(maintenance) != maintenance

-- Data standardization & consistency
select distinct 
cat
from stage.erp_px_cat_g1v2

select distinct 
subcat
from stage.erp_px_cat_g1v2

select distinct 
maintenance
from stage.erp_px_cat_g1v2

-- ====================================================================
-- Checking 'EDW.erp_cust_az12'
-- ====================================================================
--ID checking and extracting for connecting the key of cust_infor table.
select
case when cid like 'NAS%' then substring(cid, 4, LEN(cid)-3)
	 else cid
end as cid,
bdate,
gen
from stage.erp_cust_az12
WHERE cid like '%AW00011000%'

--Identify out-of-range date
select distinct
bdate
from EDW.erp_cust_az12
where bdate > GETDATE()

--Data Standardization & Consistency
select
distinct gen,
case when trim(upper(gen)) in ('Female','F') then 'Female'
when trim(upper(gen)) in ('Male','M') then 'Male'
else 'n/a'
end as gen
from EDW.erp_cust_az12

-- ====================================================================
-- Checking 'EDW.erp_loc_a101'
-- ====================================================================
--Check for the id.
select 
REPLACE(cid, '-', '') as cid
from stage.erp_loc_a101
where REPLACE(cid, '-', '') not in (
select cst_key from EDW.crm_cust_info)

--Data consistency & standardization
select distinct
case when trim(cntry) = 'DE' then 'Germany'
when trim(cntry) in ('US','USA') then 'United States'
when cntry = '' or cntry is null then 'n/a'
else trim(cntry) end as cntry
from EDW.erp_loc_a101
