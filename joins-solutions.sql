-- 1. Get all customers and their addresses
-- one customer to many addresses 
SELECT * FROM customers as c
JOIN addresses as a 
ON c.id = a.id;

-- 2. Get all orders and their line items (orders, quantity, product)
-- one order can have 1 or more line item(s). Each line item can have one or more product(s)
SELECT o.id AS order_id, l.product_id, l.quantity  FROM orders AS o
JOIN line_items as l 
ON o.id = l.order_id;

-- 3. Which warehouses have cheetos?
-- this will use a many-to-many join because many warehouses can many products
SELECT w.warehouse FROM warehouse AS w
JOIN warehouse_product AS wp ON w.id = wp.warehouse_id
JOIN products AS p ON p.id = wp.product_id
WHERE p.description = 'cheetos';

-- 4. Which warehouses have diet pepsi?
-- Same as #3 above -> many-to-many join
SELECT w.warehouse FROM warehouse AS w
JOIN warehouse_product AS wp ON w.id = wp.warehouse_id
JOIN products AS p ON p.id = wp.product_id
WHERE p.description = 'diet pepsi';

-- 5. Get the number of orders for each customer (if customer doesn't have order, don't need to include).
-- one customer can have many addresses. One address can have many orders
--TESTER
SELECT c.id AS customer_id, o.address_id AS order_addr_id, o.id AS order_id, c.first_name, c.last_name, a.street, a.city, a.state, a.zip FROM customers AS c
JOIN addresses AS a ON c.id = a.customer_id
JOIN orders AS o ON o.address_id = a.id;

-- ***FINAL ANSWER for COUNT is tallied below***
SELECT c.id AS customer_id, c.first_name, c.last_name, COUNT (o.id) AS order_count FROM customers AS c
JOIN addresses AS a ON c.id = a.customer_id
JOIN orders AS o ON o.address_id = a.id
GROUP BY c.id
ORDER BY c.id ASC;

-- 6. How many customers do we have?
SELECT COUNT (id) FROM customers;

-- 7. How many products do we carry
-- I am going to inference that this means HOW MANY DISTINCT products do we carry and not the TOTAL number.
SELECT count (id) FROM products;
--BUT...if we wanted to know the total number of products, here it is:
SELECT SUM (on_hand) AS total_num_products
FROM warehouse_product;

-- 8. What is the total available on-hand quantity of diet pepsi?
SELECT SUM (on_hand) AS total_product, products.description
FROM products JOIN warehouse_product ON products.id = warehouse_product.product_id
WHERE products.description = 'diet pepsi'
GROUP BY products.id;

-- 9. How much was the total cost per each order
-- one order can have many line items, 1 line item will have 1 product which has 1 price.
-- So, get all orders and line items first
SELECT o.id AS order_id, li.product_id AS product_id FROM orders AS o
JOIN line_items AS li
ON o.id = li.order_id;
-- Now try tying in the product price
SELECT o.id AS order_id, li.product_id AS product_id, p.unit_price FROM orders AS o
JOIN line_items AS li ON li.order_id = o.id
JOIN products AS p ON p.id = li.product_id;
-- Okay, now sum up the unit_price by order
-- ***FINAL ANSWER BELOW***
SELECT o.id AS order_id, SUM(p.unit_price) FROM orders AS o
JOIN line_items AS li ON li.order_id = o.id
JOIN products AS p ON p.id = li.product_id
GROUP BY o.id
ORDER BY o.id ASC;

-- 10. How much has each customer spent in total? --> This is a multi step answer in order to work out the logic in my head.
-- Step #1, get the customers, addresses and order.
SELECT c.id AS customer_id, a.id AS address_id, o.id AS order_id, c.first_name, c.last_name FROM customers AS c
JOIN addresses AS a ON a.customer_id = c.id
JOIN orders AS o ON o.address_id = a.id
ORDER BY customer_id, order_id;

-- Step #2 Get the line items
SELECT c.id AS customer_id, a.id AS address_id, o.id AS order_id, li.id AS line_id, c.first_name, c.last_name FROM customers AS c
JOIN addresses AS a ON a.customer_id = c.id
JOIN orders AS o ON o.address_id = a.id
JOIN line_items AS li ON li.order_id = o.id
ORDER BY customer_id, order_id, line_id;

-- Step #3 Get the products
SELECT c.id AS customer_id, a.id AS address_id, o.id AS order_id, li.id AS line_id, p.id AS product_id, p.unit_price, li.quantity, c.first_name, c.last_name FROM customers AS c
JOIN addresses AS a ON a.customer_id = c.id
JOIN orders AS o ON o.address_id = a.id
JOIN line_items AS li ON li.order_id = o.id
JOIN products AS p ON p.id = li.product_id
ORDER BY customer_id, order_id, line_id;

-- Step #4 Get the price per order
SELECT c.id AS customer_id, o.id AS order_id, li.id AS line_id, p.id AS product_id, p.unit_price, li.quantity, p.unit_price*li.quantity AS total_price, c.first_name, c.last_name FROM customers AS c
JOIN addresses AS a ON a.customer_id = c.id
JOIN orders AS o ON o.address_id = a.id
JOIN line_items AS li ON li.order_id = o.id
JOIN products AS p ON p.id = li.product_id
GROUP BY c.id, a.id, o.id, li.id, p.id
ORDER BY customer_id, order_id, line_id;

-- Step #5 Get the price per customer
SELECT c.id AS customer_id, c.first_name, c.last_name, SUM(p.unit_price*li.quantity) AS total_price 
FROM customers AS c
JOIN addresses AS a ON a.customer_id = c.id
JOIN orders AS o ON o.address_id = a.id
JOIN line_items AS li ON li.order_id = o.id
JOIN products AS p ON p.id = li.product_id
GROUP BY c.id
ORDER BY customer_id;

-- 11. How much has each customer spent in total? Customers who have spent $0 should still show up in the table.
-- Use FULL OUTER JOIN to get all records even if joining table doesn't have a corresponding record
SELECT c.id AS customer_id, c.first_name, c.last_name, COALESCE(SUM(p.unit_price*li.quantity),0) AS total_price 
FROM customers AS c
JOIN addresses AS a ON a.customer_id = c.id
FULL OUTER JOIN orders AS o ON o.address_id = a.id
FULL OUTER JOIN line_items AS li ON li.order_id = o.id
FULL OUTER JOIN products AS p ON p.id = li.product_id
GROUP BY c.id
ORDER BY customer_id;