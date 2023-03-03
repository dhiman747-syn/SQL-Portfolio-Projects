-- View the customers data
SELECT * FROM customers;


-- The total number of records (rows) of customers data
SELECT COUNT(*) AS num_of_records 
FROM customers;

-- > total 38 records in customer data



-- Count the missing values
SELECT COUNT(*) AS number_of_null_values
FROM customers
WHERE customer_code IS NULL;

-- > no missing value in the customer data



-- Count the number of fields of the customer data
SELECT COUNT(*) AS num_of_columns
FROM information_schema.columns
WHERE table_schema = 'sales' AND table_name = 'customers';

-- > total 3 fields in the customer data



-- Check for any duplicate record based on customer code
SELECT 
	customer_code,
    COUNT(*) AS freq
FROM customers
GROUP BY customer_code
HAVING COUNT(*) > 1;

-- > no duplicate records

-- renaming a column
ALTER TABLE customers
RENAME COLUMN custmer_name TO customer_name;

-- > renaming a column name form "custmer_name" to "customer_name"



-- View the data
SELECT * FROM customers;



-- Count the cutomer name
SELECT 
	customer_name,
	COUNT(*) AS cust_freq
FROM customers
GROUP BY customer_name
ORDER BY customer_name;

# looks like every customer name is unique



-- The unique customer types
SELECT
	DISTINCT(customer_type) AS unique_cust_type
FROM customers;

-- > Only two unique customer types are being recored: Brick & Mortar, and E-Commerce.



-- Count the customer type records
SELECT 
	customer_type,
    COUNT(*) AS freq_cust_type
FROM customers 
GROUP BY customer_type;

-- > so, we have 19 counts for each customer type



-- View the transactions and markets data
SELECT * FROM transactions;
SELECT * FROM markets;



-- Count the total number of records of the transactions data
SELECT COUNT(*) AS num_of_records
FROM transactions;

-- > so, we have a total 150283 records in the transactions data 



-- Count of unique proucts
SELECT	
	COUNT(DISTINCT product_code) AS num_of_unique_products
FROM transactions;

-- > we have a total of 339 unique products recorded in the transactions data



-- Count of unique markets from the transactions data and the markets data
SELECT	
	COUNT(DISTINCT market_code) AS num_of_unique_markets
FROM transactions;

SELECT	
	COUNT(DISTINCT markets_code) AS num_of_unique_markets
FROM markets;
   
-- > We can observe that the number of unique records in the two datasets differ (transaction data - 15 and markets data - 17) because
--   there appears to be some transactions being made from outside India i.e. New York and Paris.
--   However, we will stick to the Indian market and therefore will drop these two values later.



-- Check the oldest transactions data (transactions being carried out on the oldest date)
SELECT 
	DISTINCT order_date AS oldest_date
FROM transactions
ORDER BY order_date
LIMIT 1;

-- > oldest date: 2017-10-04

SELECT 
	SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount) AS total_sales_amount
FROM transactions 
WHERE currency LIKE "%INR%" AND order_date = (SELECT 
					DISTINCT order_date AS oldest_date
					FROM transactions
					ORDER BY order_date
					LIMIT 1);

-- > total 139 quantities were sold & total amount of Rs.68,643 was made on the oldest date



-- Check the latest transactions data (transactions being carried out on the latest date)
SELECT 
	DISTINCT order_date AS latest_date
FROM transactions
ORDER BY order_date DESC
LIMIT 1;

-- > latest transaction date: 2020-06-26

SELECT 
	SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount) AS total_sales_amount
FROM transactions 
WHERE currency LIKE "%INR%" AND order_date = (SELECT 
					DISTINCT order_date AS latest_date
					FROM transactions
					ORDER BY order_date DESC
					LIMIT 1);

-- > total 9 quantities were sold & total amount of Rs.3,417 was made on the latest date.



-- Checking for negative sales amount
SELECT * FROM transactions
WHERE sales_amount <= 0 ;



-- Checking for the transactions data where currency is USD
SELECT * FROM transactions
WHERE currency LIKE "%USD%";

-- > We can see that order dates of the above data is for the year 2017 and the avg exchange rate of USD to INR (1$ = Rs.65)



-- Creating a new transactions table with positive sales amounts and converted currency sales amounts 
-- (Avg exchange rate of USD to INR in 2017 (1$ = Rs.65))
CREATE TABLE transactions1 AS
SELECT 	
	*,
    CASE WHEN currency LIKE "%USD%" THEN sales_amount * 65 ELSE sales_amount
    END AS sales_amount_convt
FROM transactions
WHERE sales_amount > 0;



-- Checking for duplicate records in transactions table
SELECT 
	product_code,
    customer_code,
    market_code,
    order_date,
    sales_qty,
    sales_amount,
    COUNT(*)
FROM transactions1
GROUP BY product_code, customer_code, market_code, order_date, sales_qty, sales_amount
HAVING COUNT(*) > 1;

-- > It seems like there are some duplicate values in the transactions data. In our case, we'll remove the duplicate transaction records.



-- Removing the duplicate records present in the transaction data and creating a new transactions table
CREATE TABLE transactions2 AS
SELECT product_code,
	   customer_code, 
       market_code, 
       order_date, 
       sales_qty, 
       sales_amount,
       currency,
       sales_amount_convt FROM (
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY product_code, customer_code, market_code, order_date, sales_qty, sales_amount) AS rn
FROM transactions1) AS dup_trans
WHERE rn < 2;



-- Count of unique proucts in the new transactions table
SELECT	
	COUNT(DISTINCT product_code) AS num_of_unique_products
FROM transactions2;

-- > we have a total of 338 unique products recorded in the new transactions data (1 product was removed)



-- Count of unique markets from the new transactions data
SELECT	
	COUNT(DISTINCT market_code) AS num_of_unique_markets
FROM transactions2;

-- > we have a total of 15 unique markets recorded in the new transactions data 



-- Average sales quantity
SELECT
	MIN(sales_qty) AS min_sales_qty,
	ROUND(AVG(sales_qty), 0) AS avg_sales_qty,
    MAX(sales_qty) AS max_sales_qty
FROM transactions2;

-- > minimun sales qty: 1 unit
-- > average sales qty: 16 units
-- > maximum sales qty: 14,049 units



-- Total amount sales and total quantity sold
SELECT	
	SUM(sales_amount_convt) AS total_sales_amt,
    SUM(sales_qty) AS total_sales_qty
FROM transactions2;

-- > Total sales amount: Rs.98,48,61,463 (~ 98.48 crores)
-- > Total sales quantity: 24,29,282 (~ 24.29 lakhs)



-- Min, Avg and Max sales amount
SELECT
	MIN(sales_amount_convt) AS min_sales_amt,
	ROUND(AVG(sales_amount_convt), 0) AS avg_sales_amt,
    MAX(sales_amount_convt) AS max_sales_amt
FROM transactions2;

-- > minimun sales amount: Rs.5
-- > average sales amount: Rs.6,637 
-- > maximum sales amount: Rs.15,10,944 (~ Rs.15.10 lakhs)



-- The full transaction record having the max sales amount
SELECT 
	t.*,
    c.customer_name,
    c.customer_type,
    p.product_type,
    m.markets_name,
    m.zone
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
LEFT JOIN customers c ON t.customer_code = c.customer_code
LEFT JOIN products p ON t.product_code = p.product_code
WHERE sales_amount_convt = (SELECT MAX(sales_amount_convt) FROM transactions2);

-- > Nixon, an E-commerce customer type has the highest sales amount of about Rs.15,10,944 
-- > of the product Prod044 with 725 quantities sold on 6th Decemeber 2018.



-- The full transaction record having the min sales amount
SELECT 
	t.*,
    c.customer_name,
    c.customer_type,
    p.product_type,
    m.markets_name,
    m.zone
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
LEFT JOIN customers c ON t.customer_code = c.customer_code
LEFT JOIN products p ON t.product_code = p.product_code
WHERE sales_amount_convt = (SELECT MIN(sales_amount_convt) FROM transactions2);

-- > It looks like there are three customers - Epic Stores (Brick & Mortar type), Propel (E-commerce type) and Acclaimed Stores (Brick & Mortar type)
-- > have made the lowest amount of sales of the products Prod089, Prod147 and Prod159, respectively with 5 quantites each.



-- > Top 5 customers by high transactions
SELECT * FROM (
SELECT 
	t.*,
    c.customer_name,
    c.customer_type,
    p.product_type,
    m.markets_name,
    m.zone,
	DENSE_RANK() OVER(PARTITION BY customer_code, customer_name ORDER BY sales_amount_convt DESC) AS sales_amt_rank,
    ROW_NUMBER() OVER(PARTITION BY customer_code, customer_name ORDER BY sales_amount_convt DESC) AS rn
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
LEFT JOIN customers c ON t.customer_code = c.customer_code
LEFT JOIN products p ON t.product_code = p.product_code) AS rn_table
WHERE sales_amt_rank = 1 AND rn = 1
ORDER BY sales_amount_convt DESC
LIMIT 5;

-- > Top 5 customers in terms of high transactions: Nixon, Electricalsara Stores, Leader, Electricalslytical and Sage



-- Top 5 customers by total sales amount
SELECT
	c.customer_code,
	c.customer_name,
    c.customer_type,
    SUM(t.sales_amount_convt) AS total_sales_amt
FROM transactions2 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_code, c.customer_name
ORDER BY total_sales_amt DESC
LIMIT 5;

-- > Top 5 customers by total sales amount: Electricalsara Stores, Electricalslytical, Excel Stores, Premium Stores and Nixon.



-- Bottom 5 Customers by total sales amount
SELECT
	c.customer_code,
	c.customer_name,
    c.customer_type,
    SUM(t.sales_amount_convt) AS total_sales_amt
FROM transactions2 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_code, c.customer_name
ORDER BY total_sales_amt
LIMIT 5;

-- > Bottom 5 customers by total sales amount: Electricalsbea Stores, Expression, Electricalsquipo Stores, Electricalslance Stores and Sage.



-- Top 5 Customers by total sales quantity
SELECT
	c.customer_code,
	c.customer_name,
    c.customer_type,
    SUM(t.sales_qty) AS total_sales_qty
FROM transactions2 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_code, c.customer_name
ORDER BY total_sales_qty DESC
LIMIT 5;

-- > Top 5 customers by total sales quantity: Electricalsara Stores, Premium Stores, Surge Stores, Excel Stores and Surface Stores.



-- Bottom 5 customers by total sales quantity
SELECT
	c.customer_code,
	c.customer_name,
    c.customer_type,
    SUM(t.sales_qty) AS total_sales_qty
FROM transactions2 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_code, c.customer_name
ORDER BY total_sales_qty
LIMIT 5;

-- > Bottom 5 customers by total sales quantity: Electricalsbea Stores, Expression, Novus. Elite and Propel.



-- Top 5 products by total sales amount
SELECT
	product_code,
    SUM(sales_amount_convt) AS total_sales_amt
FROM transactions2 
GROUP BY product_code
ORDER BY total_sales_amt DESC
LIMIT 5;

-- > Top 5 products by total sales amount: Prod318, Prod316, Prod324, Prod329 and Prod334.



-- Bottom 5 products by total sales amount
SELECT
	product_code,
    SUM(sales_amount_convt) AS total_sales_amt
FROM transactions2
GROUP BY product_code
ORDER BY total_sales_amt
LIMIT 5;

-- > Bottom 5 products by total sales amount: Prod111, Prod115, Prod181, Prod154 and Prod247.



-- Top 5 products by total volume sold
SELECT
	product_code,
    SUM(sales_qty) AS total_qty
FROM transactions2 
GROUP BY product_code
ORDER BY total_qty DESC
LIMIT 5;

-- > Top 5 products by total volume sold: Prod090, Prod239, Prod237, Prod318 and Prod245.



-- Bottom 5 products by total sales quantity
SELECT
	product_code,
    SUM(sales_qty) AS total_qty
FROM transactions2 
GROUP BY product_code
ORDER BY total_qty
LIMIT 5;

-- > Bottom 5 products by total volume sold: Prod115, Prod151, Prod082, Prod154 and Prod111.



-- > Top 5 Markets by total amount sales
SELECT	
	t.market_code,
    m.markets_name,
    m.zone,
    SUM(t.sales_amount_convt) AS total_sales_amt
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
GROUP BY t.market_code
ORDER BY total_sales_amt DESC
LIMIT 5;

-- > Top 5 markets by total sales amount: Mark004, Mark002, Mark003, Mark011 and Mark007



-- Bottom 5 markets by total sales amount
SELECT	
	t.market_code,
    m.markets_name,
    m.zone,
    SUM(t.sales_amount_convt) AS total_sales_amt
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
GROUP BY t.market_code
ORDER BY total_sales_amt
LIMIT 5;

-- > Bottom 5 markets by total sales amount: Mark006, Mark015, Mark012, Mark008 and Mark009



-- Top 5 markets by total volume sold
SELECT	
	t.market_code,
    m.markets_name,
    m.zone,
    SUM(t.sales_qty) AS total_sales_qty
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
GROUP BY t.market_code
ORDER BY total_sales_qty DESC
LIMIT 5;

-- > Top 5 markets by total sales volume: Mark004, Mark002, Mark011, Mark010 and Mark003



-- Bottom 5 markets by total sales quantity
SELECT	
	t.market_code,
    m.markets_name,
    m.zone,
    SUM(t.sales_qty) AS total_sales_qty
FROM transactions2 t
LEFT JOIN markets m ON t.market_code = m.markets_code
GROUP BY t.market_code
ORDER BY total_sales_qty
LIMIT 5;

-- > Bottom 5 markets by total sales volume: Mark006, Mark009, Mark015, Mark005 and Mark012



-- Creating a new transactions table with some additional info about order_date
CREATE TABLE transactions3 AS
SELECT 
	product_code, customer_code, market_code, sales_qty, sales_amount, currency, sales_amount_convt,
	order_date,
    YEAR(order_date) AS year1,
    MONTH(order_date) AS month1,
    DAYOFMONTH(order_date) AS day_of_month,
    QUARTER(order_date) as quarter1,
    MONTHNAME(order_date) as month_name,
    DAYNAME(order_date) day_name
FROM transactions2;



--  Quarterly sales amount and sales quantity and create a table quartely sales
CREATE TABLE quarterly_sales AS
SELECT
	year1,
    quarter1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) As total_sales_amount
FROM transactions3
GROUP BY year1, quarter1
ORDER BY year1, quarter1;



-- Creating a table of daily total sales
CREATE TABLE daily_total_sales AS
SELECT 
	order_date,
	year1,
    quarter1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) As total_sales_amount
FROM transactions3
GROUP BY order_date, year1
ORDER BY order_date, year1, quarter1;



-- Creating a table of monthly total sales
CREATE TABLE monthly_total_sales AS
SELECT 
	year1,
    month1,
    month_name,
    quarter1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) As total_sales_amount
FROM transactions3
GROUP BY year1, month1
ORDER BY year1, month1, quarter1;



-- Calculating the percentage change in yearly sales figures (with forecasted figures)
SELECT 
	year1,
    yearly_sales_qty,
    ROUND(100 * (yearly_sales_qty - LAG(yearly_sales_qty) OVER(ORDER BY year1)) /  LAG(yearly_sales_qty) OVER(ORDER BY year1), 1) AS perc_change_in_sales_qty,
    yearly_sales_amt,
	ROUND(100 * (yearly_sales_amt - LAG(yearly_sales_amt) OVER(ORDER BY year1)) /  LAG(yearly_sales_amt) OVER(ORDER BY year1), 1) AS perc_change_in_sales_amt
FROM (SELECT
		year1,
		SUM(total_sales_qty) AS yearly_sales_qty,
		SUM(total_sales_amount) AS yearly_sales_amt
	FROM quarterly_sales_forecasted
	GROUP BY year1
	ORDER BY year1) A;

-- > From the above figures, we can actually see that the overall performance of sales in yearly basis is not very good.
-- > We can actually see a decreasing performance in the yearly sales figures. 



-- Revenue by Zones
SELECT 
	zone,
    SUM(sales_amount_convt) AS total_revenue
FROM (
	SELECT
		t.market_code,
		m.markets_name,
		m.zone,
		t.sales_qty,
		t.sales_amount_convt,
		t.order_date,
		t.year1,
		t.month1,
		t.quarter1
	FROM transactions3 t
	LEFT JOIN markets m ON t.market_code = m.markets_code) A
    GROUP BY zone;


	
-- Creating a new transaction table by merging with newly updated data that has been added recently
CREATE TABLE transactions3_new AS
SELECT 
	t3.product_code,
    t3.customer_code,
    t3.market_code,
    t3.sales_qty,
    t3.sales_amount,
    t.currency,
    t3.sales_amount_convt,
    t3.order_date,
    t3.year1,
    t3.month1,
    t3.month_name,
    t3.day_of_month,
    t3.day_name,
    t3.quarter1,
    t.profit_margin,
    t.profit_margin_percentage,
    t.cost_price
FROM transactions3 t3
LEFT JOIN transactions t ON t3.product_code = t.product_code AND t3.customer_code = t.customer_code 
							AND t3.market_code = t.market_code AND t3.order_date = t.order_date;

-- > We can see that the number of records are more than the transactions3 table had earlier. So, we need to check for duplicate records.



-- Checking for duplicate records in the transactions3_new table
SELECT 
	product_code, customer_code, market_code, order_date, sales_qty, sales_amount,
    COUNT(*)
FROM transactions3_new
GROUP BY product_code, customer_code, market_code, order_date, sales_qty, sales_amount
HAVING COUNT(*) > 1;

-- > There appear to be 424 duplicate records. We will remove these records for the analysis.



-- Removing the duplicate records in the transactions3_new table and creating a new table transactions4
CREATE TABLE transactions4 AS
SELECT 
product_code, customer_code, market_code, sales_qty, sales_amount, currency, sales_amount_convt, order_date, year1, month1, 
month_name, day_of_month, day_name, quarter1, profit_margin, profit_margin_percentage, cost_price
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY product_code, customer_code, market_code, sales_qty, sales_amount, order_date) AS rn
	FROM transactions3_new) AS dup_trans
    WHERE rn < 2;



-- So, now we have updated the transactions table with profit margin and cost figures.
SELECT * FROM transactions4;



-- Let's delete unnecessary features like day_name and month_name since we already have their numerical values
ALTER TABLE transactions4
DROP COLUMN month_name, 
DROP COLUMN day_name;



-- Changing the column name from "profit_margin" to "profit" and "profit_margin_percentage" to "profit_margin"
ALTER TABLE transactions4
RENAME COLUMN profit_margin TO profit,
RENAME COLUMN profit_margin_percentage TO profit_margin;



-- Let's check the transactions4 table
SELECT * FROM transactions4;



-- Let's create sales_by_markets and sales_by_products tables containing profit and cost figures (since we updated our transactions table with some new data)
CREATE TABLE sales_by_markets1 AS 
SELECT
	t.market_code,
	m.markets_name,
	m.zone,
	t.sales_qty,
	t.sales_amount_convt,
	t.order_date,
	t.year1,
	t.month1,
	t.quarter1,
    t.profit,
    t.profit_margin,
    t.cost_price
FROM transactions4 t
LEFT JOIN markets m ON t.market_code = m.markets_code
WHERE m.zone IS NOT NULL;



CREATE TABLE sales_by_products1 AS
SELECT
	t.product_code,
	p.product_type,
	t.sales_qty,
	t.sales_amount_convt,
	t.order_date,
	t.year1,
	t.month1,
	t.quarter1,
    t.profit,
    t.profit_margin,
    t.cost_price
FROM transactions4 t
LEFT JOIN products p ON t.product_code = p.product_code;




-- Creating a new sales by products table with some imputations
CREATE TABLE sales_by_products2 AS
SELECT 
	*,
    CASE WHEN product_type IS NULL THEN "Other" ELSE product_type 
    END AS product_type1
FROM sales_by_products1;



-- Top 5 products with higest profit
SELECT 
	product_code,
    product_type1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_products2
GROUP BY product_code, product_type1
ORDER BY total_profit DESC
LIMIT 5;

-- > Prod329, Prod318, Prod316, Prod040 and Prod324 are the top 5 products with very high profits



-- Bottom 5 products with very low total profit
SELECT 
	product_code,
    product_type1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_products2
GROUP BY product_code, product_type1
ORDER BY total_profit
LIMIT 5;

-- > Prod073, Prod336, Prod044, Prod084 and Prod169 are the bottom 5 products with very low profits.



-- Let's check top 5 products with high profit margin
SELECT 
	product_code,
    product_type1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_products2
GROUP BY product_code, product_type1
ORDER BY total_profit_margin DESC
LIMIT 5;

-- > Prod001, Prod037, Prod111, Prod153 and Prod151 are top 5 products with very high profit margin



-- Bottom 5 products with very low profit margin
SELECT 
	product_code,
    product_type1,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_products2
GROUP BY product_code, product_type1
ORDER BY total_profit_margin
LIMIT 5;

-- > Prod080, Prod022, Prod066, Prod230 and Prod073 are the bottom 5 products with very low profit margin.



-- Dropping the irrelevant
ALTER TABLE sales_by_products2
DROP COLUMN product_type;



-- Top 5 markets with very high profits
SELECT 
	market_code,
    markets_name,
    zone,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_markets1
GROUP BY market_code, markets_name
ORDER BY total_profit DESC
LIMIT 5;

-- >  Delhi NCR, Mumbai, Ahmedabad Nagpur and Bhopal are the top 5 markets with  very high profits


-- Bottom 5 markets with very low profits
SELECT 
	market_code,
    markets_name,
    zone,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_markets1
GROUP BY market_code, markets_name
ORDER BY total_profit
LIMIT 5;

-- Bengaluru, Kanpur, Lucknow, Bhubaneshwar and Hyderabad are the bottom 5 markets with very low profits



-- Top 5 Markets with very high profit margin
SELECT 
	market_code,
    markets_name,
    zone,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_markets1
GROUP BY market_code, markets_name
ORDER BY total_profit_margin DESC
LIMIT 5;

-- > Bhopal, Surat, Patna, Bhubaneshwar and Kochi are the top 5 markets with very high profit margin



-- Bottom 5 markets with very low profit margin
SELECT 
	market_code,
    markets_name,
    zone,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_markets1
GROUP BY market_code, markets_name
ORDER BY total_profit_margin
LIMIT 5;

-- > Bengaluru, Kanpur, Hyderabad, Lucknow and Chennai are the botton 5 markets with very low profit margin



-- > Total profit and total profit margin by zones
SELECT
	zone,
    SUM(sales_qty) AS total_sales_qty,
    SUM(sales_amount_convt) AS total_revenue,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(cost_price), 0) AS total_cost
FROM sales_by_markets1
GROUP BY zone
ORDER BY total_profit_margin DESC;

-- > Looks like Central zone is having the highest profitability or total profit margin. North and South zones are having quite similar profitability.



-- Top 5 Customers in terms of profit margin
SELECT
	t.customer_code,
    c.custmer_name,
    c.customer_type,
    SUM(t.sales_qty) AS total_sales_qty,
    SUM(t.sales_amount_convt) AS total_revenue,
    ROUND(SUM(t.profit)) AS total_profit,
    ROUND(100 * SUM(t.profit) / SUM(t.sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(t.cost_price), 0) AS total_cost
FROM transactions4 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_code, c.custmer_name
ORDER BY total_profit_margin DESC
LIMIT 5;

-- > Top 5 customers with very high total profit margin: Leader, Electricalsquipo Stores, Power, Elite and Electricalsocity



-- Bottom 5 customers with very low profit margin
SELECT
	t.customer_code,
    c.custmer_name,
    c.customer_type,
    SUM(t.sales_qty) AS total_sales_qty,
    SUM(t.sales_amount_convt) AS total_revenue,
    ROUND(SUM(t.profit)) AS total_profit,
    ROUND(100 * SUM(t.profit) / SUM(t.sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(t.cost_price), 0) AS total_cost
FROM transactions4 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_code, c.custmer_name
ORDER BY total_profit_margin
LIMIT 5;

-- > Bottom 5 customer with very low total profit margin: Electricalslance Stores, Electricalsbea Stores, Info Stores, Insight and Zone.



-- Total profit margin by customer type
SELECT
    c.customer_type,
    SUM(t.sales_qty) AS total_sales_qty,
    SUM(t.sales_amount_convt) AS total_revenue,
    ROUND(SUM(t.profit)) AS total_profit,
    ROUND(100 * SUM(t.profit) / SUM(t.sales_amount_convt), 2) AS total_profit_margin,
    ROUND(SUM(t.cost_price), 0) AS total_cost
FROM transactions4 t
LEFT JOIN customers c ON t.customer_code = c.customer_code
GROUP BY c.customer_type
ORDER BY total_profit_margin DESC;

-- > E-commerce type is generating more profit margin than Brick & Mortar.



-- Calcluate the avg cost of each product and create a new transactions with avg cost of each product 
CREATE TABLE transactions5 AS
SELECT 
	t1.*,
    avg_cost_table.avg_cost
FROM 
	(SELECT 
		*,
		ROUND(SUM(cost_price) / SUM(sales_qty), 1) AS avg_cost
	FROM transactions4 t1
	GROUP BY product_code) AS avg_cost_table
RIGHT JOIN transactions4 t1 ON t1.product_code = avg_cost_table.product_code;



-- Creating a table for revenue and profit contribution by markets
CREATE TABLE markets_contribution AS
SELECT 
	market_code,
	markets_name,
    zone,
    total_revenue_by_markets,
    gross_revenue,
	ROUND(100 * total_revenue_by_markets / gross_revenue, 2) AS revenue_contribution_perc,
    total_profit_by_markets,
    gross_profit,
    ROUND(100 * total_profit_by_markets / gross_profit, 2) AS profit_contribution_perc
FROM 
(SELECT 
	market_code,
    markets_name,
    zone,
    total_revenue_by_markets,
    SUM(total_revenue_by_markets) OVER() AS gross_revenue,
    total_profit_by_markets,
    SUM(total_profit_by_markets) OVER() AS gross_profit
FROM (SELECT 
	market_code,
	markets_name,
	zone,
	SUM(sales_amount_convt) AS total_revenue_by_markets,
	ROUND(SUM(profit), 0) AS total_profit_by_markets
FROM sales_by_markets1 
GROUP BY market_code, markets_name) mr) gr
ORDER BY market_code;



-- Check the top 5 markets which are highly contributing to our revenue generation
SELECT * FROM markets_contribution
ORDER BY revenue_contribution_perc DESC
LIMIT 5;
    
-- > Delhi NCR, Mumbai, Ahmedabad, Nagpur and Bhopal are the top 5 markets having significant contribution towards revenue generation.



-- Top 5 markets by profit contribution
SELECT * FROM markets_contribution
ORDER BY profit_contribution_perc DESC
LIMIT 5;
    
-- > Seems like the same markets who are having very high revenue contribution are also having high profit contribution.



-- Revenue contribution by zones
WITH zone_revenue AS (
	SELECT
		zone,
		SUM(total_revenue_by_markets) AS total_zone_revenue,
		SUM(total_profit_by_markets) AS total_zone_profit
	FROM markets_contribution
	GROUP BY zone ),
gross_revenue AS (
	SELECT
		zone,
		total_zone_revenue,
		SUM(total_zone_revenue) OVER() AS gross_revenue,
		total_zone_profit,
		SUM(total_zone_profit) OVER() AS gross_profit
	FROM zone_revenue )
SELECT 
	zone,
		total_zone_revenue,
        gross_revenue,
        ROUND(100 * total_zone_revenue / gross_revenue, 1) AS revenue_contribution_perc,
		total_zone_profit,
		gross_profit,
        ROUND(100 * total_zone_profit / gross_profit, 1) AS profit_contribution_perc
FROM gross_revenue
ORDER BY revenue_contribution_perc DESC;

-- > North zone is highly contributing to revenue generation and profit earnings followed by Cental zone. However, South zone doesn't look much promising in its contribution.



-- Calculating the profit and revenue contribution made by each product and creating a table of it.
CREATE TABLE products_contribution AS
SELECT 
	product_code,
    product_type1,
    total_revenue_by_products,
    gross_revenue,
	ROUND(100 * total_revenue_by_products / gross_revenue, 3) AS revenue_contribution_perc,
    total_profit_by_products,
    gross_profit,
    ROUND(100 * total_profit_by_products / gross_profit, 3) AS profit_contribution_perc
FROM 
(SELECT 
	product_code,
    product_type1,
    total_revenue_by_products,
    SUM(total_revenue_by_products) OVER() AS gross_revenue,
    total_profit_by_products,
    SUM(total_profit_by_products) OVER() AS gross_profit
FROM (SELECT 
	product_code,
    product_type1,
	SUM(sales_amount_convt) AS total_revenue_by_products,
	ROUND(SUM(profit), 0) AS total_profit_by_products
FROM sales_by_products2 
GROUP BY product_code) pr) gr
ORDER BY product_code;



-- Top 5 Products having the very high revenue contribution
SELECT * FROM products_contribution
ORDER BY revenue_contribution_perc DESC
LIMIT 5;

-- > Prod318, Prod316, Prod324, Prod329 and Prod334 are the top 5 products with high revenue contribution



-- Top 5 Products with high profit contribution
SELECT * FROM products_contribution
ORDER BY profit_contribution_perc DESC
LIMIT 5;

-- > Prod329, Prod318, Prod316, Prod040 and Prod324 are the top 5 products with high profit contribution



-- Calculating the customers' contribution to revenue and profit generation and creating a table of it
CREATE TABLE customers_contribution AS
SELECT
	gr.customer_code,
    c.customer_name,
    c.customer_type,
    gr.total_revenue_by_cust,
    gr.gross_revenue,
    ROUND(100 * gr.total_revenue_by_cust / gr.gross_revenue, 1) AS revenue_contribution_perc,
    gr.total_profit_by_cust,
    gr.gross_profit,
    ROUND(100 * gr.total_profit_by_cust / gr.gross_profit, 1) AS profit_contribution_perc
FROM ( SELECT
			customer_code,
			total_revenue_by_cust,
			SUM(total_revenue_by_cust) OVER() AS gross_revenue,
			total_profit_by_cust,
			SUM(total_profit_by_cust) OVER() AS gross_profit
	   FROM ( SELECT 
			customer_code,
			SUM(sales_amount_convt) AS total_revenue_by_cust,
			ROUND(SUM(profit), 0) AS total_profit_by_cust
	   FROM transactions5
	   GROUP BY customer_code ) cust_r ) gr
LEFT JOIN customers c ON gr.customer_code = c.customer_code;



-- Top 5 Customers by revenue contribution
SELECT * FROM customers_contribution
ORDER BY revenue_contribution_perc DESC
LIMIT 5;

-- > Electricalsara Stores, Electricalslytical, Excel Stores, Premium Stores and Nixon are the top 5 customers with high revenue contribution. 
-- > Electricalsara Stores has a whopping 42% revenue contribution.



-- Top 5 customer by profit contribution
SELECT * FROM customers_contribution
ORDER BY profit_contribution_perc DESC
LIMIT 5;

-- > Electricalsara Stores has a very big profit contribution of about 38% followed by Nixon, Electricalslytical, Leader and Premium Stores.



