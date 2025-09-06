/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency,
    and accuracy of the data_marts layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Run these checks after data loading EDW layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ========================================================================
-- Checking 'data_marts.dim_customers'
-- ========================================================================
-- Check for uniqueness of customer key in data_marts.dim_customers
-- Expectation: No results
SELECT
    customer_key,
    count(*) as duplicate_count
FROM data_marts.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ========================================================================
-- Checking 'data_marts.dim_products'
-- ========================================================================
-- Check for uniqueness of product key in data_marts.dim_products
-- Expectation: No results
SELECT
    product_key,
    count(*) as duplicate_count
FROM data_marts.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ========================================================================
-- Checking 'data_marts.fact_sales'
-- ========================================================================
-- Check for data model connectivity between fact and dimensions
-- Foreign key integrity （Dimensions） 
select * 
from data_marts.fact_sales f
left join data_marts.dim_customers dc
on f.customer_key = dc.customer_key
left join data_marts.dim_products dp
on f.product_key = dp.product_key
where dc.customer_key is null or dp.product_key is null
-- Having some new/unregistered products, requiring a discussion with the business team for these product information.
