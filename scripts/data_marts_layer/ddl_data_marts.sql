/*
======================================================================================
DDL Script: Create Data_marts Views
======================================================================================
Script Purpose:
    This script creates views for the data_marts layer in the data warehouse.
    The data_marts layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the EDW layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
======================================================================================
*/
-- ======================================================================================
-- Create Dimension: data_marts.dim_customers
-- ======================================================================================
--Join all the customer information,change the order of column for importance sorting, update the name to be friendly
--and add sorrogate key
IF OBJECT_ID('data_marts.dim_customers', 'V') IS NOT NULL
	DROP VIEW data_marts.dim_customers;
CREATE VIEW data_marts.dim_customers as
SELECT
	ROW_NUMBER() over (order by cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		 ELSE COALESCE(ca.gen, 'n/a') 
	end as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date
FROM EDW.crm_cust_info ci
left join EDW.erp_cust_az12 ca
on ci.cst_key = ca.cid
left join EDW.erp_loc_a101 la
on ci.cst_key = la.cid

--Integration for gender
SELECT distinct
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		 ELSE COALESCE(ca.gen, 'n/a') 
	end as new_gen
FROM EDW.crm_cust_info ci
left join EDW.erp_cust_az12 ca
on ci.cst_key = ca.cid
left join EDW.erp_loc_a101 la
on ci.cst_key = la.cid
order by 1,2
--Find partial gender data is complexx between crm and erp, go and find the system expert for the master/dorminated system
--The master system for this project is CRM
go

-- ======================================================================================
-- Create Dimension: data_marts.dim_products
-- ======================================================================================
IF OBJECT_ID('data_marts.dim_products', 'V') IS NOT NULL
	DROP VIEW data_marts.dim_products;
CREATE VIEW data_marts.dim_products as
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) as product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
from EDW.crm_prd_info pn
LEFT JOIN EDW.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt IS NULL -- Filter out all the historical dara

select * from data_marts.dim_products
where product_key is null
go

-- ======================================================================================
-- Create Dimension: data_marts.fact_sales
-- ======================================================================================

--Building Fact: Use the dimension's surrogate keys instead of IDs to easily connect facts with dimensions
IF OBJECT_ID('data_marts.fact_sales', 'V') IS NOT NULL
	DROP VIEW data_marts.fact_sales;
CREATE VIEW data_marts.fact_sales as
SELECT
cd.sls_ord_num as order_number,
pr.product_key, -- surrogate keys  for products
cu.customer_key, -- surrogate keys  for products
cd.sls_order_dt as order_date,
cd.sls_ship_dt as shipping_date,
cd.sls_due_dt as due_date,
cd.sls_sales as sales_amount,
cd.sls_quantity as quantity,
cd.sls_price as price
FROM 
EDW.crm_sales_details cd
LEFT JOIN data_marts.dim_products pr
on cd.sls_prd_key = pr.product_number
LEFT JOIN data_marts.dim_customers cu
on cd.sls_cust_id = cu.customer_id

-- Foreign key integrity （Dimensions） 
select * 
from data_marts.fact_sales f
left join data_marts.dim_customers dc
on f.customer_key = dc.customer_key
left join data_marts.dim_products dp
on f.product_key = dp.product_key
where dc.customer_key is null or dp.product_key is null
-- Having some new/unregistered products
go
