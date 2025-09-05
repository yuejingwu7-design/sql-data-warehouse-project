/*
=====================================================================================
Stored Procedure: Load Silver Layer (stage -> EDW)
=====================================================================================
Script Purpose:
	This stored procedure performs the ETL (Extract, Transform, Load) process to populate the 'silver' schema tables from the 'bronze' schema.
  Actions Performed:
	- Truncates Silver tables.
	- Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
	None.
	This stored procedure does not accept any parameters or return any values.

Usage Example:
	EXEC Silver.load_silver;
======================================================================================
*/

CREATE or ALTER PROCEDURE EDW.load_EDW AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @overall_start_time DATETIME, @overall_end_time DATETIME;
	BEGIN TRY
		SET @overall_start_time = GETDATE();
		PRINT '==============================================================';
		PRINT 'Loading EDW Layer';
		PRINT '==============================================================';

		PRINT '--------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------------------------------';

		PRINT '>> Truncating Table: EDW.crm_cust_info';
		SET @start_time = GETDATE();
		--Loading EDW.crm_cust_info
		-- Truncate table first before full loading
		Truncate Table EDW.crm_cust_info;
		--Loading
		Insert INTO EDW.crm_cust_info (
		cst_id, 
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		)
		select 
		cst_id,
		cst_key,
		trim(cst_firstname) as cst_firstname,
		trim(cst_lastname) as cst_lastname,
		case 
			when upper(trim(cst_marital_status)) = 'S' then 'Single'
			when upper(trim(cst_marital_status)) = 'M' then 'Married'
			else 'n/a'
		end cst_marital_status,
		case 
			when upper(trim(cst_gndr)) = 'F' then 'Female'
			when upper(trim(cst_gndr)) = 'M' then 'Male'
			else 'n/a'
		end cst_gndr,
		cst_create_date
		from (
		select 
		*,
		ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
		from stage.crm_cust_info
		) t where flag_last = 1 and cst_id is not null

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: EDW.erp_px_cat_g1v2';
		SET @start_time = GETDATE();
		--Loading EDW.erp_px_cat_g1v2
		-- Truncate table first before full loading
		Truncate Table EDW.erp_px_cat_g1v2;

		-- Loading
		insert into EDW.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
		)
		select 
		id,
		cat,
		subcat,
		maintenance
		from stage.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: EDW.crm_sales_details';
		SET @start_time = GETDATE();
		--Loading EDW.crm_sales_details
		-- Truncate table first before full loading
		Truncate Table EDW.crm_sales_details;

		-- Loading
		insert into EDW.crm_sales_details (
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
		Select
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
		else cast(cast(sls_order_dt as varchar) as date) 
		end as sls_order_dt,
		case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
		else cast(cast(sls_ship_dt as varchar) as date) 
		end as sls_ship_dt,
		case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
		else cast(cast(sls_due_dt as varchar) as date) 
		end as sls_due_dt,
		case 
			when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
			then sls_quantity * abs(sls_price) else sls_sales 
			end as sls_sales,
		sls_quantity,
		case 
			when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
			else sls_price end as sls_price
		From 
		stage.crm_sales_details
		--where sls_ord_num != TRIM(sls_ord_num) -> check for unwanted space
		--where sls_prd_key not in (select prd_key from EDW.crm_prd_info) ->check for validity
		--where sls_cust_id not in (select cst_key from EDW.crm_prd_info) ->check for validity
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: EDW.crm_prd_info';
		SET @start_time = GETDATE();
		-- Loading EDW.crm_prd_info
		-- Truncate table first before full loading
		Truncate Table EDW.crm_prd_info;

		-- Loading
		Insert into EDW.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
		)
		select 
		prd_id,
		replace(substring(prd_key,1,5),'-','_') as cat_id,
		substring(prd_key,7,LEN(prd_key)) as prd_key,
		prd_nm,
		ISNULL(prd_cost,0) AS prd_cost,
		CASE upper(trim(prd_line))
		WHEN 'R'THEN 'Mountain'
		WHEN 'S' THEN 'Road'
		WHEN 'M' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		else 'n/a'
		end as prd_line,
		CAST(prd_start_dt as date) as prd_start_dt,
		Dateadd(day,-1,LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt)) as prd_end_dt
		from stage.crm_prd_info
		where prd_key in 
		(Select
		distinct prd_key
		from stage.crm_prd_info
		where prd_end_dt < prd_start_dt)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '--------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------------------------';
		PRINT '>> Truncating Table: EDW.erp_cust_az12';
		SET @start_time = GETDATE();
		-- Loading EDW.erp_cust_az12
		-- Truncate table first before full loading
		Truncate Table EDW.erp_cust_az12;

		-- Loading
		Insert into EDW.erp_cust_az12(
		cid,
		bdate,
		gen
		)
		SELECT
		case when cid LIKE 'NAS%' then SUBSTRING(cid, 4, len(cid))
			 else cid
		end as cid,
		case when bdate > GETDATE() then null
		else bdate
		end as bdate,
		case when trim(upper(gen)) in ('Female','F') then 'Female'
		when trim(upper(gen)) in ('Male','M') then 'Male'
		else 'n/a'
		end as gen
		FROM stage.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: EDW.erp_loc_a101';
		SET @start_time = GETDATE();
		--Loading EDW.erp_loc_a101
		-- Truncate table first before full loading
		Truncate Table EDW.erp_loc_a101;

		-- Loading
		Insert into EDW.erp_loc_a101(
		cid,
		cntry
		)
		select 
		REPLACE(cid, '-', '') as cid,
		case when trim(cntry) = 'DE' then 'Germany'
		when trim(cntry) in ('US','USA') then 'United States'
		when cntry = '' or cntry is null then 'n/a'
		else trim(cntry) end as cntry
		from stage.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------------';
		SET @overall_end_time = GETDATE();
		PRINT '>> The whole EDW Load Duration: ' + CAST(DATEDIFF(second, @overall_start_time, @overall_end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
		PRINT '==================================================================';
		PRINT 'ERROR OCCURED DURING LOADING EDW LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=================================================================='
	END CATCH
END


EXEC EDW.load_EDW
