/*
=================
Product Report 
=================
This SQL script creates a view for product metrics, aggregating key performance indicators and segmenting products based on sales performance.
Purpose: this report consolidates key product metrics and behaviors

Highlights:
	1. Gathers essential fields such as product name, category, subcategory and cost
	2. Segments products by revenue to identify high perormers, mid range or low performers 
	3. aggregate product-level metrics:
		-total orders
		-total sales
		-total quantity sold 
		-total customers (unique)
		-lifespan (months)
	4. Calculates valuable KPIs:
		-recency (months since last sale)
		-average order revenue (AOR)
		-average monthly revenue 
*/


CREATE VIEW gold.report_products AS
WITH base_query AS (
SELECT 
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.dim_products p 
LEFT JOIN gold.fact_sales f
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL
),

product_aggregations AS(
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
	MAX(order_date) AS last_sale_date,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query
GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)

/*Combines all product results into one output */

SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(month, last_sale_date, GETDATE()) AS recency_in_months,
	CASE 
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Performer'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_sales,
	total_orders,
	total_quantity,
	total_customers,
	avg_selling_price,
	--compuate average order value (AVO)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END  avg_order_value,
	--compute average monthly spend
	CASE 
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan 
	END avg_monthly_spending
FROM product_aggregations
