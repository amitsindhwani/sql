/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT
product_name||', '|| 
COALESCE (product_size, '') || ' (' ||
COALESCE (product_qty_type, 'unit') || ')' AS product_details
from product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

-- using ROW_NUMBER() - Numbers every row uniquely, even if the market_date repeats.
SELECT customer_id
,market_date
,ROW_NUMBER() OVER (PARTITION by customer_id ORDER BY market_date) as customer_visit
FROM customer_purchases

-- using DENSE_RANK() - Assigns the same number for duplicate market_date values and increments 
-- only when the date changes.
SELECT customer_id
,market_date
,DENSE_RANK() OVER (PARTITION by customer_id ORDER BY market_date) as customer_visit
FROM customer_purchases

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */
SELECT customer_id, market_date
FROM (
	SELECT customer_id
	,market_date
	,ROW_NUMBER() OVER (PARTITION by customer_id ORDER BY market_date DESC) as customer_visit
	FROM customer_purchases
) as customer_recent_visits
WHERE customer_recent_visits.customer_visit = 1


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT customer_id
,product_id
,COUNT(product_id) OVER (PARTITION by customer_id, product_id ) as product_purchase_count
FROM customer_purchases

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

--uses IIF statement to check if hypen exists in the product name, else shows NULL 
-- Note:The IIF() function works in SQLite version 3.33.0 or later only.
SELECT product_id
,product_name
,IIF(INSTR(product_name, '-') > 0, TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1)), NULL) as product_description  
,product_size
,product_category_id
,product_qty_type
FROM product

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_id
,product_name
,IIF(INSTR(product_name, '-') > 0, TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1)), NULL) as product_description  
,product_size
,product_category_id
,product_qty_type
FROM product
WHERE product_size REGEXP '\d'

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

SELECT market_date, total_sales
FROM
	(
		SELECT market_date
		,SUM(quantity * cost_to_customer_per_qty) AS total_sales 
		FROM customer_purchases
		GROUP by market_date
		ORDER BY total_sales ASC
		LIMIT 1
	)
UNION
SELECT market_date, total_sales
FROM
	(
		SELECT market_date
		,SUM(quantity * cost_to_customer_per_qty) AS total_sales 
		FROM customer_purchases
		GROUP by market_date
		ORDER BY total_sales DESC
		LIMIT 1
	)

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT vendor_name
,product_name
,sum(5 * original_price) as total_amount_per_product
FROM (
	-- Select distinct vendors and their products
	SELECT DISTINCT vi.vendor_id, v.vendor_name, vi.product_id, p.product_name, vi.original_price
	FROM vendor_inventory as vi
	JOIN vendor as v
	ON v.vendor_id = vi.vendor_id
	JOIN product as p
	ON p.product_id = vi.product_id
	ORDER BY vi.vendor_id
) as vendor_products
CROSS JOIN (
	-- cross join with the customers - this will list all the vendors, their products for each of the customers 
	SELECT customer_id
	FROM customer
) AS all_customers
GROUP BY vendor_name, product_name

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

-- Drop the table 'product_units' if already exists
DROP TABLE IF EXISTS product_units
-- Create the table 'product_units' if it doesn't already exists.
CREATE table IF NOT EXISTS product_units as
--select query will automatically create the schema same as product table, include the additional timestamp column
SELECT product_id
,product_name
,product_size
,product_category_id
,product_qty_type
,CURRENT_TIMESTAMP as snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit'

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES (24, 'Farm Fresh Strawberries', 'pint',1,'unit',CURRENT_TIMESTAMP)

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units
WHERE product_id = 24


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT

UPDATE product_units
SET current_quantity = (
	SELECT COALESCE (vi.quantity, 0) as last_quantity
	FROM vendor_inventory as vi
	JOIN (
		-- select the maximum market_date that will have the last quantity and self join to return only one column
		-- to update the current quantity in the product_table
		SELECT product_id, max(market_date) as last_market_date 
		FROM vendor_inventory
		GROUP by product_id
		) as last_quantity_table
	ON vi.product_id= last_quantity_table.product_id 
	AND vi.market_date = last_quantity_table.last_market_date
	WHERE product_units.product_id = vi.product_id
)


