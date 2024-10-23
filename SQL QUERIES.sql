-- Creating dimentional tables
CREATE TABLE customers(
	customer_id CHARACTER VARYING (50) PRIMARY KEY,
	customer_zip_code_prefix INTEGER,
	customer_city CHARACTER (50),
	customer_state CHARACTER (10)
);

CREATE TABLE products(
	product_id CHARACTER VARYING (50) PRIMARY KEY,
	product_category_name CHARACTER (50),
	product_name_lenght INTEGER,
	product_description_lenght INTEGER,
	product_photos_qty INTEGER,
	product_weight_g INTEGER,
	product_length_cm INTEGER,
	product_height_cm INTEGER,
	product_width_cm INTEGER
);

CREATE TABLE sellers (
	seller_id CHARACTER VARYING (50) PRIMARY KEY,
	seller_zip_code_prefix INTEGER,
	seller_city CHARACTER (50),
	seller_state CHARACTER (50)
);


CREATE TABLE reviews(
	review_id CHARACTER VARYING (50),
	order_id CHARACTER VARYING (50),
	review_score INTEGER,
	review_comment_title TEXT,
	review_comment_message TEXT,
	review_creation_date DATE,
	review_answer_timestamp DATE
);


-- Importing data from csv files
COPY customers
FROM 'D:\sql proj data\Group\customers_dim.csv'
DELIMITER ','
CSV HEADER;

COPY products
FROM 'D:\sql proj data\Group\products_dim.csv'
DELIMITER ','
CSV HEADER;

COPY sellers
FROM 'D:\sql proj data\Group\sellers_dim.csv'
DELIMITER ','
CSV HEADER;

COPY reviews
FROM 'D:\sql proj data\Group\reviews_dim.csv'
DELIMITER ','
CSV HEADER;


-- Checking missing values for Customers table
SELECT COUNT(*)
FROM customers
WHERE customer_id IS NULL;

SELECT COUNT(*)
FROM customers
WHERE customer_zip_code_prefix IS NULL;

SELECT COUNT(*)
FROM customers
WHERE customer_city IS NULL;

SELECT COUNT(*)
FROM customers
WHERE customer_state IS NULL;

-- Checking duplicate values for customer table

SELECT customer_id,COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) >1;

-- Checking missing values for products table
SELECT COUNT(*)
FROM products
WHERE product_id IS NULL;

-- Checking duplicates for product table
SELECT product_id,COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) >1;

-- Checking missing values for sellers table
SELECT COUNT(*)
FROM sellers
WHERE seller_id IS NULL;

SELECT COUNT(*)
FROM sellers
WHERE seller_zip_code_prefix IS NULL;

SELECT COUNT(*)
FROM sellers
WHERE seller_city IS NULL;

SELECT COUNT(*)
FROM sellers
WHERE seller_state IS NULL;

-- Checking duplicate values for sellers
SELECT seller_id
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) >1;

-- Checking missing values for reviews table
SELECT COUNT(*)
FROM reviews
WHERE review_id IS NULL;

SELECT COUNT(*)
FROM reviews
WHERE order_id IS NULL;

SELECT COUNT(*)
FROM reviews
WHERE review_score IS NULL;

-- Checking duplicate values for reviews table
SELECT review_id,count(*)
FROM reviews
GROUP BY review_id
HAVING COUNT(*) >1;


-- Deleting rows with duplicate values
DELETE FROM reviews a
USING reviews b 
WHERE a.ctid <b.ctid AND a.review_id = b.revie	w_id;


-- Updating reviews table primary key
ALTER TABLE reviews 
ADD PRIMARY KEY (review_id);

CREATE TABLE orders (
	order_id CHARACTER VARYING (50),
	order_item_id INTEGER,
	product_id CHARACTER VARYING (50),
	seller_id CHARACTER VARYING (50),
	customer_id CHARACTER VARYING (50),
	review_id CHARACTER VARYING (50),
	shipping_limit_date DATE,
	order_estimated_delivery_date DATE,
	price FLOAT,
	freight_value FLOAT,
	payment_sequential INTEGER,
	payment_type CHARACTER (50),
	payment_installments INTEGER,
	payment_value FLOAT,
	FOREIGN KEY (product_id) REFERENCES products (product_id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (seller_id) REFERENCES sellers (seller_id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (review_id) REFERENCES reviews (review_id) ON UPDATE CASCADE ON DELETE CASCADE
);


COPY orders
FROM 'D:\sql proj data\Group\orders_fact.csv'
DELIMITER ','
CSV HEADER;

--Checking missing values in Orders Table
SELECT COUNT(*)
FROM orders
WHERE order_id IS NULL;

SELECT COUNT(*)
FROM orders
WHERE product_id IS NULL;

SELECT COUNT(*)
FROM orders
WHERE seller_id IS NULL;

SELECT COUNT(*)
FROM orders
WHERE customer_id IS NULL;

-- Checking missing review_id
SELECT COUNT(*)
FROM orders
WHERE review_id IS NULL;

-- Deleting missing review ids
DELETE FROM orders
WHERE review_id IS NULL;


SELECT COUNT(*)
FROM orders
WHERE payment_sequential IS NULL;

DELETE FROM orders
WHERE payment_sequential IS NULL;

-- Checking duplicate values
SELECT order_id,count(order_id)
FROM orders
GROUP BY order_id
HAVING COUNT(order_id) >1;

-- removing duplicate values 

DELETE FROM orders a
USING orders b 
WHERE a.ctid <b.ctid AND a.order_id = b.order_id;

--Average Review Score by Product Category

SELECT p.product_category_name,
AVG(r.review_score) AS avg_review_score
FROM products p
JOIN orders o ON p.product_id = o.product_id
JOIN reviews r ON o.review_id = r.review_id
GROUP BY p.product_category_name
ORDER BY avg_review_score DESC;

--Product categories that have the highest average number of product photos

SELECT product_category_name, AVG (product_photos_qty) AS avg_photos
FROM products
GROUP BY product_category_name
ORDER BY avg_photos DESC;

--List the top 5 product categories with the highest average product weights

SELECT product_category_name, AVG(product_weight_g) AS avg_weight
FROM products
GROUP BY product_category_name
ORDER BY avg_weight DESC
LIMIT 5;

--Product with highest sale

SELECT p.product_category_name,
       ROUND(SUM(o.price::NUMERIC), 2) AS total_sales
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC;

--Revenue by product category

SELECT p.product_category_name,
       ROUND(SUM(o.price)::NUMERIC, 2) AS total_revenue
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

--Total Revenue by State

SELECT c.customer_state,
       ROUND(SUM(o.price::NUMERIC), 2) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

--Average Delivery Time vs. Average Product Weight

SELECT p.product_category_name,
       ROUND(AVG(o.order_estimated_delivery_date - o.shipping_limit_date), 2) AS avg_delivery_time,
       ROUND(AVG(p.product_weight_g), 2) AS avg_product_weight,
       CASE 
           WHEN AVG(o.order_estimated_delivery_date - o.shipping_limit_date) > (
               SELECT AVG(order_estimated_delivery_date - shipping_limit_date) FROM orders
           ) THEN 'Delayed'
           ELSE 'On Time'
       END AS delivery_status
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_delivery_time DESC;

--Total Freight Value Analysis by City and State

SELECT c.customer_city,
       c.customer_state,
       ROUND(SUM(o.freight_value)::NUMERIC, 2) AS total_freight_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_city, c.customer_state
ORDER BY total_freight_value DESC;

--Average delivery time per state

SELECT c.customer_state,
       ROUND(AVG(o.order_estimated_delivery_date - o.shipping_limit_date), 2) AS avg_delivery_time
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY avg_delivery_time DESC;

--Top 5 cities with the highest number of customers
SELECT customer_city, COUNT(*) AS customer_count
FROM customers
GROUP BY customer_city
ORDER BY customer_count DESC
LIMIT 5

--Different payment types used by customers for orders.

SELECT payment_type,
       (COUNT(payment_type) * 100.0) / (SELECT COUNT(*) FROM orders) AS payment_type_percentage
FROM orders
GROUP BY payment_type;

--Identify Top Customers by Total Spent

SELECT c.customer_id,
       c.customer_city,
       c.customer_state,
       SUM(o.price + o.freight_value) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_city, c.customer_state
ORDER BY total_spent DESC
LIMIT 10;

--Top 10 Customers with the Highest Total Payment Value 
   
SELECT c.customer_id,
       c.customer_city,
       c.customer_state,
       SUM(o.payment_value) AS total_payment_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_city, c.customer_state
ORDER BY total_payment_value DESC
LIMIT 10;


-- Retrieve the most common words used in review comments along with their frequencies, excluding common English stopwords

WITH Words AS (
    SELECT regexp_split_to_table(LOWER(review_comment_message), E'\\s+') AS word
    FROM reviews
)
SELECT word, COUNT(*) AS word_count
FROM Words
WHERE word NOT IN ('the', 'and', 'is', 'in', 'it', 'of', 'this') -- Add more stopwords as needed
GROUP BY word
ORDER BY word_count DESC
LIMIT 10;

--Find top 10  Sellers with Highest Total Sales Value

SELECT s.seller_id,
       s.seller_city,
       s.seller_state,
       SUM(o.price + o.freight_value) AS total_sales
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_sales DESC
LIMIT 10;









