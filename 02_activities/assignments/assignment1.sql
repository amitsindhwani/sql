/* ASSIGNMENT 1 */
/* SECTION 2 */


--SELECT
/* 1. Write a query that returns everything in the customer table. */
--use individual column names instead of wild card '*' - it prevents breakage 
--if table schema changes
SELECT customer_id
,customer_first_name
,customer_last_name
,customer_postal_code
FROM customer


/* 2. Write a query that displays all of the columns and 10 rows from the customer table, 
sorted by customer_last_name, then customer_first_ name. */
-- using LIMIT 10 - returns the top 10 rows after sort criteria is applied
SELECT customer_id
,customer_first_name
,customer_last_name
,customer_postal_code
FROM customer
ORDER by customer_last_name, customer_first_name
LIMIT 10;

--WHERE
/* 1. Write a query that returns all customer purchases of product IDs 4 and 9. */
-- option 1
-- using OR operator in WHERE clause: Select all customers who have purchased products with product id is 4 or 9. Although you see some
-- duplicate rows in resultset but their transaction time is different, shows customers have purchased the product multiple times. 
-- No customer purchased product id 9, so you don't see the same in the result set.
-- Note: It seems from the requirement that we just need to pull data from the customer_purchases table only, but showing customer name 
-- and product name shows result set more understandable.
SELECT c.customer_id
,customer_first_name
,customer_last_name
,customer_postal_code
,cp.product_id
,product_name
,transaction_time
FROM customer as c
JOIN customer_purchases as cp
ON c.customer_id = cp.customer_id
JOIN product as p
ON p.product_id  = cp.product_id
WHERE cp.product_id = 4 OR cp.product_id = 9

-- option 2
-- using IN operator in WHERE clause : Select all customers who have purchased products with product id is 4 or 9 Although you see some
-- duplicate rows in resultset but their transaction time is different, shows customers have purchased the product multiple times.
-- No customer purchased product id 9, so you don't see the same in the result set.
-- Note: It seems from the requirement that we just need to pull data from the customer_purchases table only, but showing customer name 
-- and product name shows result set more understandable.
SELECT c.customer_id
,customer_first_name
,customer_last_name
,customer_postal_code
,cp.product_id
,product_name
,transaction_time
FROM customer as c
JOIN customer_purchases as cp
ON c.customer_id = cp.customer_id
JOIN product as p
ON p.product_id  = cp.product_id
WHERE cp.product_id IN (4, 9)

/*2. Write a query that returns all customer purchases and a new calculated column 'price' (quantity * cost_to_customer_per_qty), 
filtered by vendor IDs between 8 and 10 (inclusive) using either:
	1.  two conditions using AND
	2.  one condition using BETWEEN
*/
-- option 1
-- two conditions using AND operator
SELECT c.customer_id
,customer_first_name
,customer_last_name
,customer_postal_code
,cp.product_id
,product_name
,(quantity * cost_to_customer_per_qty) as price
,transaction_time
FROM customer as c
JOIN customer_purchases as cp
ON c.customer_id = cp.customer_id
JOIN product as p
ON p.product_id  = cp.product_id
WHERE vendor_id >= 8 AND 
vendor_id <=10


-- option 2
--one condition using BETWEEN operator	
SELECT c.customer_id
,customer_first_name
,customer_last_name
,customer_postal_code
,cp.product_id
,product_name
,(quantity * cost_to_customer_per_qty) as price
,transaction_time
FROM customer as c
JOIN customer_purchases as cp
ON c.customer_id = cp.customer_id
JOIN product as p
ON p.product_id  = cp.product_id
WHERE vendor_id BETWEEN 8 AND 10


--CASE
/* 1. Products can be sold by the individual unit or by bulk measures like lbs. or oz. 
Using the product table, write a query that outputs the product_id and product_name
columns and add a column called prod_qty_type_condensed that displays the word “unit” 
if the product_qty_type is “unit,” and otherwise displays the word “bulk.” */

--Note that where product_size is oz, the product_qty_type is mentioned "unit" but we are checking the 
--column product_qty_type that has values either "unit" or "bulk". 
--There are NULL values as well in product_qty_type so need to be specific WHEN clause for unit and (lbs,oz).
SELECT product_id
,product_name
,CASE 
	WHEN product_qty_type = 'unit' THEN "unit"
	WHEN product_qty_type IN ('lbs', 'oz') THEN "bulk"
END as product_qty_type_condensed
FROM product


/* 2. We want to flag all of the different types of pepper products that are sold at the market. 
add a column to the previous query called pepper_flag that outputs a 1 if the product_name 
contains the word “pepper” (regardless of capitalization), and otherwise outputs 0. */

--Note that where product_size is oz, the product_qty_type is mentioned "unit" but we are checking the 
--column product_qty_type that has values either "unit" or "bulk"
--There are NULL values as well in product_qty_type so need to be specific WHEN clause for unit and (lbs,oz).
SELECT product_id
,product_name
,CASE 
	WHEN product_qty_type = 'unit' THEN "unit"
	WHEN product_qty_type IN ('lbs', 'oz') THEN "bulk"
END as product_qty_type_condensed
,CASE 
	WHEN product_name like '%pepper%' THEN 1
	ELSE 0
END as pepper_flag
FROM product


--JOIN
/* 1. Write a query that INNER JOINs the vendor table to the vendor_booth_assignments table on the 
vendor_id field they both have in common, and sorts the result by vendor_name, then market_date. */

--Selected vendor name, type, booth number, market_date (only some fields) to show the results
SELECT vendor_name
,vendor_type
,booth_number
,market_date
FROM vendor as v
INNER JOIN vendor_booth_assignments as vba
ON v.vendor_id = vba.vendor_id
ORDER BY vendor_name, market_date


/* SECTION 3 */

-- AGGREGATE
/* 1. Write a query that determines how many times each vendor has rented a booth 
at the farmer’s market by counting the vendor booth assignments per vendor_id. */

--used LEFT Join to include vendors who didn't rent any booth
SELECT v.vendor_id, vendor_name
,count(booth_number) as number_of_times_booth_rented
FROM vendor as v
LEFT JOIN vendor_booth_assignments as vba
ON v.vendor_id = vba.vendor_id
GROUP BY v.vendor_id, vendor_name

/* 2. The Farmer’s Market Customer Appreciation Committee wants to give a bumper 
sticker to everyone who has ever spent more than $2000 at the market. Write a query that generates a list 
of customers for them to give stickers to, sorted by last name, then first name. 

HINT: This query requires you to join two tables, use an aggregate function, and use the HAVING keyword. */

-- grouped based on the customer id 
SELECT c.customer_id
,(customer_first_name ||' '|| customer_last_name) as customer_name
,SUM(quantity * cost_to_customer_per_qty) as money_spent
FROM customer as c
JOIN customer_purchases as cp
ON c.customer_id = cp.customer_id
GROUP BY c.customer_id
HAVING money_spent > 2000
ORDER by customer_last_name, customer_first_name


--Temp Table
/* 1. Insert the original vendor table into a temp.new_vendor and then add a 10th vendor: 
Thomass Superfood Store, a Fresh Focused store, owned by Thomas Rosenthal

HINT: This is two total queries -- first create the table from the original, then insert the new 10th vendor. 
When inserting the new vendor, you need to appropriately align the columns to be inserted 
(there are five columns to be inserted, I've given you the details, but not the syntax) 

-> To insert the new row use VALUES, specifying the value you want for each column:
VALUES(col1,col2,col3,col4,col5) 
*/

-- drop the table if already EXISTS
DROP TABLE IF EXISTS new_vendor

--create a TEMPORARY TABLE from the vendor TABLE
CREATE TEMP TABLE new_vendor AS
SELECT *
FROM vendor

--insert the 10th vendor into the newly created table
INSERT INTO new_vendor
VALUES(10, 'Thomass Superfood Store', 'a Fresh Focused store', 'Thomas', 'Rosenthal')

-- Date
/*1. Get the customer_id, month, and year (in separate columns) of every purchase in the customer_purchases table.

HINT: you might need to search for strfrtime modifers sqlite on the web to know what the modifers for month 
and year are! */

SELECT customer_id
,strftime("%m", market_date) as purchase_month
,strftime("%Y", market_date) as purchase_year
FROM customer_purchases

/* 2. Using the previous query as a base, determine how much money each customer spent in April 2022. 
Remember that money spent is quantity*cost_to_customer_per_qty. 

HINTS: you will need to AGGREGATE, GROUP BY, and filter...
but remember, STRFTIME returns a STRING for your WHERE statement!! */

-- To show customer names, we can join with the customer table, but we are pulling customer details who have purchased something
SELECT customer_id
,sum(quantity*cost_to_customer_per_qty) as money_spent
FROM customer_purchases
WHERE strftime("%m", market_date) = '04'
AND strftime("%Y", market_date) = '2022'
GROUP by customer_id