
-- TABLE 1: Customers
CREATE TABLE customers (
    customer_id INTEGER,
    customer_name VARCHAR(100),
    email VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(100),
    signup_date DATE);


-- TABLE 2: Products
CREATE TABLE products (
    products_id INTEGER,
    products_name VARCHAR(100),
    category VARCHAR(100),
    unit_price NUMERIC(10,2),
    stock_quantity INTEGER);


-- TABLE 3: Employees
CREATE TABLE employees (
    employees_id INTEGER,
    employees_name VARCHAR(100),
    department VARCHAR(100),
    branch_city VARCHAR(100),
    monthly_salary NUMERIC(10,2));


-- TABLE 4: Orders
CREATE TABLE orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    employee_id INTEGER,
    order_status VARCHAR(50),
    payment_method VARCHAR(50));

-- TABLE 5: Order_Items
CREATE TABLE order_items (
    order_items_id INTEGER,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price NUMERIC(10,2),
    discount_rate NUMERIC(5,2));

-- TABLE 6: Returns
CREATE TABLE returns (
    return_id INTEGER,
    order_id INTEGER,
    return_date DATE,
    return_reason VARCHAR(200)
);


SELECT * FROM customers;
SELECT * FROM Products;
SELECT * FROM employees;
SELECT * FROM orders;
SELECT * FROM  order_items;
SELECT * FROM returns;


Q.1 List delivered orders placed between 1 October 2024 and 31 March 2025, showing order_id, 
order_date, customer_id, and payment_method. Sort by order_date descending. 

SELECT
    order_id,
    order_date,
    customer_id,
    payment_method
FROM orders
WHERE order_status = 'Delivered'
  AND order_date >= '2024-10-01'
  AND order_date < '2025-04-01'
ORDER BY order_date DESC;


Q-2 Display each delivered order with customer_name, order_id, order_date, employee_name, and 
order_status. Include only orders with matching customer and employee records.


SELECT
    c.customer_name,
    o.order_id,
    o.order_date,
    e.employees_name AS employee_name,
    o.order_status
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN employees e
    ON o.employee_id = e.employees_id
WHERE o.order_status = 'Delivered'
ORDER BY o.order_date DESC;

Q-3 For each product category, calculate total units sold and net revenue from delivered orders. Show 
only categories with net revenue greater than ₹10,000; sort by net revenue descending.


SELECT
    p.category,
    SUM(oi.quantity) AS total_units_sold,
    ROUND( SUM( oi.quantity * oi.unit_price * (1 - oi.discount_rate) ), 2 ) AS net_revenue
FROM products p
JOIN order_items oi
    ON p.products_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
HAVING SUM(oi.quantity * oi.unit_price * (1 - oi.discount_rate)) > 10000
ORDER BY net_revenue DESC;
	

Q-4 Find customers who have placed at least two delivered orders. Show customer_id, customer_name, 
number of delivered orders, and total net spend.


SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS delivered_order_count,
    ROUND( SUM(oi.quantity * oi.unit_price * (1 - oi.discount_rate)), 2) AS net_spend
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) >= 2
ORDER BY net_spend DESC;

Q-5 List all customers and the number of delivered orders each has placed, including customers with 
zero delivered orders.

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS delivered_order_count
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY c.customer_id;

Q-6 Find products whose unit_price is greater than the average unit_price of all products. Display 
product name, category, unit price, and the overall average price.

SELECT
    products_name AS product_name,category,unit_price,
    (SELECT ROUND(AVG(unit_price), 2)
     FROM products) AS overall_average_price
FROM products
WHERE unit_price > (
 SELECT AVG(unit_price)
    FROM products)
ORDER BY unit_price DESC;


Q-7 Find customers who have never placed a delivered order. Return their customer_id, customer_name, 
and city. 

SELECT
    c.customer_id,
    c.customer_name,
    c.city
FROM customers c
WHERE NOT EXISTS ( SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.order_status = 'Delivered')
ORDER BY c.customer_id;

Q-8 Group delivered orders by year and month, showing the number of orders and net revenue for each 
month. Sort chronologically. 

SELECT
    TO_CHAR(o.order_date, 'YYYY') AS order_year,
    TO_CHAR(o.order_date, 'MM') AS order_month,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    ROUND(SUM(oi.quantity * oi.unit_price* (1 - oi.discount_rate) ),2 ) AS net_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    DATE_TRUNC('month', o.order_date),
    TO_CHAR(o.order_date, 'YYYY'),
    TO_CHAR(o.order_date, 'MM')
ORDER BY
    DATE_TRUNC('month', o.order_date) ASC;

Q-9 Classify each product as 'Low Stock' when stock_quantity < 20, 'Moderate Stock' when 
stock_quantity is between 20 and 40 inclusive, and 'High Stock' when stock_quantity > 40. Display 
product_name, stock_quantity, and stock label.

SELECT
    products_name AS product_name,
    stock_quantity,
    CASE
        WHEN stock_quantity < 20 THEN 'Low Stock'
        WHEN stock_quantity BETWEEN 20 AND 40 THEN 'Moderate Stock'
        WHEN stock_quantity > 40 THEN 'High Stock'
    END AS stock_label
FROM products
ORDER BY products_id;
-Q=10 For each employee, calculate delivered, returned, and cancelled order counts using conditional 
aggregation. Include employees with no orders.

SELECT
    e.employees_name AS employee_name,
 SUM(CASE WHEN o.order_status = 'Delivered'
        THEN 1 ELSE 0 END) AS delivered_orders,
SUM(CASE WHEN r.order_id IS NOT NULL
        THEN 1 ELSE 0 END) AS returned_orders,
 SUM(CASE WHEN o.order_status = 'Cancelled'
        THEN 1 ELSE 0 END) AS cancelled_orders
FROM employees e
LEFT JOIN orders o
    ON e.employees_id = o.employee_id
LEFT JOIN returns r
    ON o.order_id = r.order_id
GROUP BY e.employees_id, e.employees_name
ORDER BY e.employees_id;

Q-11 Rank products within each category by net revenue from delivered orders, highest first. Show 
category, product_name, net revenue, and rank. Products with no delivered sales should still be 
eligible to appear with zero revenue. 

SELECT
    category,
    product_name,
    net_revenue,
    RANK() OVER ( PARTITION BY category ORDER BY net_revenue DESC) AS product_rank
FROM (SELECT p.category,p.products_name AS product_name, COALESCE(SUM(CASE WHEN o.order_status = 'Delivered'
                    THEN oi.quantity * oi.unit_price * (1 - oi.discount_rate)ELSE 0 END ), 0) AS net_revenue
 FROM products p
    LEFT JOIN order_items oi
        ON p.products_id = oi.product_id
    LEFT JOIN orders o
        ON oi.order_id = o.order_id
 GROUP BY p.products_id, p.category, p.products_name) AS product_revenue
ORDER BY category, product_rank;

Q-12 For each month, calculate delivered-order net revenue and a cumulative running total of revenue 
across months in chronological order. 

WITH monthly_revenue AS (SELECT DATE_TRUNC('month', o.order_date) AS order_month,
        SUM(oi.quantity * oi.unit_price* (1 - oi.discount_rate) ) AS net_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_TRUNC('month', o.order_date))
SELECT
    TO_CHAR(order_month, 'YYYY-MM') AS month,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(SUM(net_revenue) OVER (ORDER BY order_month ), 2 ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY order_month;

Q-13 List each returned order with customer name, return date, return reason, and the total pre-discount 
value of its order items. 

SELECT
    c.customer_name,
    r.return_date,
    r.return_reason,
    SUM(oi.quantity * oi.unit_price) AS total_pre_discount_value
FROM returns r
JOIN orders o
    ON r.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    r.return_id,
    c.customer_name,
    r.return_date,
    r.return_reason
ORDER BY r.return_date;

Q-14 Using a CTE, calculate net revenue per customer from delivered orders, then return customers 
whose net revenue is above the average customer net revenue. State whether the average is 
calculated across all customers or only customers with delivered purchases.

WITH customer_revenue AS (SELECT c.customer_id, c.customer_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_rate)) AS net_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name)
SELECT
    customer_id,
    customer_name,
    ROUND(net_revenue, 2) AS net_revenue
FROM customer_revenue
WHERE net_revenue > (
    SELECT AVG(net_revenue)
    FROM customer_revenue)
ORDER BY net_revenue DESC;

Q-15 Identify the top three customers by delivered net spend. Show customer name, number of delivered 
orders, net spend, and each customer's percentage contribution to total delivered net revenue.

WITH customer_spend AS (
    SELECT c.customer_id,c.customer_name, COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM( oi.quantity * oi.unit_price * (1 - oi.discount_rate) ) AS net_spend
  FROM customers c
     JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name)
SELECT
    customer_name,
    delivered_orders,
    ROUND(net_spend, 2) AS net_spend,
    ROUND( net_spend * 100.0 /
        (SELECT SUM(net_spend) FROM customer_spend), 2) AS percentage_contribution
FROM customer_spend
ORDER BY net_spend DESC
LIMIT 3;

