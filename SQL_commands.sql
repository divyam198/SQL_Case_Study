SELECT * FROM dannys_diner..members;
SELECT * FROM dannys_diner..menu;
SELECT * FROM dannys_diner..sales;

-- What is the total amount each customer spent at the restaurant?
SELECT s.customer_id,
SUM(m.price) amount_spent
FROM dannys_diner..sales s
INNER JOIN dannys_diner..menu m
ON m.product_id = s.product_id
GROUP BY s.customer_id;

-- How many days has each customer visited the restaurant?
SELECT customer_id, 
COUNT(DISTINCT order_date) AS days
FROM dannys_diner..sales
GROUP BY customer_id
ORDER BY 2 DESC;

-- What was the first item from the menu purchased by each customer?
WITH CTE AS (
SELECT customer_id, 
product_id,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranks
FROM dannys_diner..sales
)
SELECT c.customer_id,
m.product_name
FROM CTE c
INNER JOIN dannys_diner..menu m
ON c.product_id = m.product_id
WHERE c.ranks = 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH purchase_count AS (
SELECT product_id,
COUNT(product_id) frequency
FROM dannys_diner..sales
GROUP BY product_id
)
SELECT TOP 1 m.product_name,
p.frequency
FROM purchase_count p
INNER JOIN dannys_diner..menu m
ON p.product_id = m.product_id
ORDER BY 2 DESC;

-- Which item was the most popular for each customer?
-- popular item will be the one which the customer purchases many no. of times
WITH popular_items AS 
(
SELECT customer_id,
product_id,
COUNT(product_id) times_purchased,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) ranking
FROM dannys_diner..sales 
GROUP BY customer_id, product_id
)
SELECT p.customer_id,
m.product_name,
p.times_purchased
FROM popular_items p
INNER JOIN dannys_diner..menu m
ON m.product_id = p.product_id
WHERE ranking = 1;

-- Which item was purchased first by the customer after they became a member?
-- Here I am filtering all the sales records after the customer became member
WITH member_records AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) ranks
FROM dannys_diner..sales s
WHERE order_date > (SELECT join_date 
					FROM dannys_diner..members m
					WHERE s.customer_id = m.customer_id)
)
SELECT mr.customer_id,
m.product_name
FROM member_records mr
INNER JOIN dannys_diner..menu m
ON m.product_id = mr.product_id
WHERE ranks = 1;


-- Which item was purchased just before the customer became a member?
WITH before_member_records AS
(
SELECT *,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) ranks
FROM dannys_diner..sales s
WHERE order_date < (SELECT join_date 
					FROM dannys_diner..members m
					WHERE s.customer_id = m.customer_id)
)
SELECT mr.customer_id,
m.product_name
FROM before_member_records mr
INNER JOIN dannys_diner..menu m
ON m.product_id = mr.product_id
WHERE ranks = 1;

-- What is the total items and amount spent for each member before they became a member?
-- Going one step ahead by printing products in list form
SELECT s.customer_id, 
STRING_AGG(m.product_name, ',') AS items_purchased, 
SUM(m.price) AS total_amount_spent
FROM dannys_diner..sales s
LEFT JOIN dannys_diner..menu m
ON m.product_id = s.product_id
WHERE order_date < (SELECT join_date 
					FROM dannys_diner..members m
					WHERE s.customer_id = m.customer_id)
GROUP BY s.customer_id;

-- The following question is related to creating basic data tables that Danny and his team can use to quickly derive 
-- insights without needing to join the underlying tables using SQL.
SELECT t.customer_id,
t.order_date,
m.product_name,
t.member
FROM
(
SELECT *,
'N' AS member
FROM dannys_diner..sales s
WHERE order_date < (SELECT join_date 
					FROM dannys_diner..members m
					WHERE s.customer_id = m.customer_id)
UNION ALL
SELECT *,
'Y' AS member
FROM dannys_diner..sales s
WHERE order_date >= (SELECT join_date 
					FROM dannys_diner..members m
					WHERE s.customer_id = m.customer_id)
) t
JOIN dannys_diner..menu m
ON m.product_id = T.product_id
ORDER BY 1,2,3;
