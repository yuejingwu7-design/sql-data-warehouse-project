/*
===========================================================================================================
DDL Script: Create Stage Tables
===========================================================================================================
Script Purpose:
  This script creates tables in the 'stage' schema, dropping existing tables
  if they already exist.
  Run this script to re-define the DDL structure of 'stage' Tables
===========================================================================================================
*/

USE DataWarehouse;

IF OBJECT_ID('stage.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE stage.crm_cust_info;

CREATE TABLE stage.crm_cust_info(
cst_id INT,
cst_key NVARCHAR(50),
cst_firstname NVARCHAR(50),
cst_lastname NVARCHAR(50),
cst_material_status NVARCHAR(50),
cst_gndr NVARCHAR(50),
cst_create_date DATE
);

IF OBJECT_ID('stage.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE stage.crm_prd_info;

CREATE TABLE stage.crm_prd_info(
prd_id INT,
prd_key NVARCHAR(50),
prd_nm NVARCHAR(50),
prd_cost INT,
prd_line NVARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE
);

IF OBJECT_ID('stage.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE stage.crm_sales_details;

CREATE TABLE stage.crm_sales_details (
sls_ord_num NVARCHAR(50),
sls_prd_key NVARCHAR(50),
sls_cust_id INT,
sls_order_dt INT,
sls_ship_dt INT,
sls_due_dt INT,
sls_sales INT,
sls_quantity INT,
sls_price INT
);

IF OBJECT_ID('stage.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE stage.erp_loc_a101;

CREATE TABLE stage.erp_loc_a101(
cid NVARCHAR(50),
cntry NVARCHAR(50)
);

IF OBJECT_ID('stage.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE stage.erp_cust_az12;

CREATE TABLE stage.erp_cust_az12(
cid NVARCHAR(50),
bdate date,
gen NVARCHAR(50)
);

IF OBJECT_ID('stage.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE stage.erp_px_cat_g1v2;

CREATE TABLE stage.erp_px_cat_g1v2(
id NVARCHAR(50),
cat NVARCHAR(50),
subcat NVARCHAR(50),
maintenance NVARCHAR(50)
);
