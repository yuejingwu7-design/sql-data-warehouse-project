/* 
===================================================================================================
Stored Procedure: Load Stage Layer (Source -> Stage)
===================================================================================================
Script Purpose:
  This stored procedure loads data into the "stage" schema from external csv files.
  It performs the following actions:
  - Truncates the stage tables before loading data.
  - Uses the 'BULK INSERT' command to load data from csv files to stage tables.
Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  EXEC stage.load_stage;
===================================================================================================
*/

CREATE OR ALTER PROCEDURE stage.load_stage AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==============================================================';
		PRINT 'Loading Stage Layer';
		PRINT '==============================================================';

		PRINT '--------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------------------------------';

		PRINT '>> Truncating Table: stage.crm_cust_info';
		SET @start_time = GETDATE();
		TRUNCATE TABLE stage.crm_cust_info;

		PRINT '>> Inserting Table: stage.crm_cust_info';
		BULK INSERT stage.crm_cust_info
		FROM 'D:\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: stage.crm_prd_info';
		SET @start_time = GETDATE();
		TRUNCATE TABLE stage.crm_prd_info;

		PRINT '>> Inserting Table: stage.crm_prd_info';
		BULK INSERT stage.crm_prd_info
		FROM 'D:\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: stage.crm_sales_details';
		SET @start_time = GETDATE();
		TRUNCATE TABLE stage.crm_sales_details;

		PRINT '>> Inserting Table: stage.crm_sales_info';
		BULK INSERT stage.crm_sales_details
		FROM 'D:\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '--------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------------------------';

		PRINT '>> Truncating Table: stage.erp_cust_az12';

		TRUNCATE TABLE stage.erp_cust_az12;
		SET @start_time = GETDATE();
		PRINT '>> Inserting Table: stage.erp_cust_az12';
		BULK INSERT stage.erp_cust_az12
		FROM 'D:\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: stage.erp_loc_a101';

		TRUNCATE TABLE stage.erp_loc_a101;
		SET @start_time = GETDATE();
		PRINT '>> Inserting Table: stage.erp_loc_a101';

		BULK INSERT stage.erp_loc_a101
		FROM 'D:\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		with(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '>> Truncating Table: stage.erp_px_cat_g1v2';

		TRUNCATE TABLE stage.erp_px_cat_g1v2;
		SET @start_time = GETDATE();
		PRINT '>> Inserting Table: stage.erp_px_cat_g1v2';
		BULK INSERT stage.erp_px_cat_g1v2
		FROM 'D:\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		with(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------------';
		SET @batch_end_time = GETDATE();
		PRINT '>> The whole batch Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
		PRINT '==================================================================';
		PRINT 'ERROR OCCURED DURING LOADING STAGE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=================================================================='
	END CATCH
END
