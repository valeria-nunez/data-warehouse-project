/*
Script Purpose:
This script performs various quality checks for data consistency, accuracy,
and standardization across the 'silver' schema. It includes checks for:
- Null or duplicate primary keys.
- Unwanted spaces in string fields.
- Data standardization and consistency.
- Invalid date ranges and orders.
- Data consista
between related fields.

Usage Notes:
- Run these checks after data loading Silver Layer.
- Investigate and resolve any discrepancies found during the checks.
*/
SELECT 
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN 
(SELECT distinct id FROM bronze.erp_px_cat_g1v2 ) 

--SECOND PART
--
SELECT 
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) IN 
(select  sls_prd_key from bronze.crm_sales_details)

--Check Primary Key(duplicates or nulls)
SELECT prd_id,
count(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) != 1 OR prd_id IS NULL
--data standarization
--silver layer
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

--Check for invalid date orders 
--the end date must be older than the start date
SELECT 
	*
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt 

SELECT 
	prd_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM silver.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')

--check for negative number or nulls
SELECT 
	prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0 


--DATA CHECK BRONZE TO SILVER 
--all that product keys from the sales details can be used and connected with product info
SELECT TOP 30
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details 
WHERE sls_prd_key not in
(SELECT prd_key FROM silver.crm_prd_info)

--check for invalid dates
SELECT NULLIF (sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details 
WHERE sls_order_dt <= 0 
or len(sls_order_dt) != 8 
or sls_order_dt > 20500101
or sls_order_dt < 19000101

--ckeck the data 
--no nulls or zero and this ecuation must match sls_price * sls_quantity = sls_sales
select  sls_sales,sls_price,sls_quantity from bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_price is null or sls_quantity is null
or sls_sales <= 0 or sls_price <= 0 or sls_quantity <= 0

SELECT cid FROM bronze.erp_cust_az12 WHERE cid like '%NAS'

SELECT * FROM silver.crm_cust_info

--check out of range dates
USE DataWarehouse
SELECT bdate FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()
--data standirization and consistency
SELECT DISTINCT gen from silver.erp_cust_az12

--unique values and recent 
SELECT *
FROM (
SELECT 
	* ,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC ) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL
)t WHERE flag_last != 1

--check if exists any duplicate on primary key 
SELECT cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--check for unwanted spaces 
--expectation: no results 
SELECT cst_firstname 
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname 
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

--crm_prd_info
SELECT 
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

--Check for NULLs or Negative Numbers
SELECT 
	prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0 

--Data Standardization and Consistency 

--bronze layer
SELECT 
	DISTINCT cst_gndr 
FROM bronze.crm_cust_info

SELECT 
	DISTINCT cst_marital_status 
FROM bronze.crm_cust_info

--silver layer
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info


