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
-- Create Dimension: gold.dim_customers
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
