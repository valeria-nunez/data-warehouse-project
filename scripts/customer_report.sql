/*
=================
Customer Report
=================
This SQL script creates a view for customer reports, aggregating essential 
customer metrics and segmenting them into categories based on sales and age.

1.gathers essential fields such as names, ages and transaction details
2. segments customers into categories (VIP, Regular, New) and age groups 
3. aggregates customer-level metrics:
	-total orders
	-total sales
	-total quantity purchased
	-total products
	-lifespan(in months)
4. calculates valuable KPIs: 
	-recency (months since last order)
	-average order value
	-average monthly spend 
*/

/*
1) BASE QUERY: retrieves core columns from tables
*/
CREATE VIEW gold.report_customers AS
WITH base_query AS (
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) AS customer_name,
DATEDIFF(YEAR,c.birthdate, GETDATE()) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key 
WHERE order_date IS NOT NULL )

, customer_aggregation AS (
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(month,MIN(order_date),MAX(order_date) ) as lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE 
		WHEN age < 20 THEN 'Under 20'
		WHEN age BETWEEN 20 AND 29 THEN '20-29'
		WHEN age BETWEEN 30 AND 39 THEN '30-39'
		WHEN age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 and above'
	END '50 and above',
	CASE 
		WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
		WHEN total_sales <= 5000 AND lifespan >= 12 THEN 'Regular'
		ELSE 'New'
	END customer_segment,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	--compuate average order value (AVO)
	CASE WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END  avg_order_value,
	--compute average monthly spend
	CASE WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan 
	END avg_monthly_spending
FROM customer_aggregation

