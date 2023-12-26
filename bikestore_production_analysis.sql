use production;

## Sales Performance Analysis:## 
-- 1.	What is the total quantity of each product sold?
select p.product_name ,
 sum(quantity) total_quantity 
 from products p
inner join order_items oi 
on p.product_id =oi.product_id
group by p.product_name
order by total_quantity DESC ;


-- 2.	What is the total revenue per brand?
select b.brand_name ,
sum(((oi.quantity * oi.list_price) - oi.discount)) total_revenue  
from brands b
left join products p
on b.brand_id = p.brand_id
left join order_items oi
on p.product_id = oi.product_id
group by b.brand_name 
order by total_revenue DESC;

-- 3.	What is the monthly sales trend for each store?
with cte_monthaly_trend as(
SELECT s.store_id, s.store_name,
EXTRACT(YEAR FROM o.order_date) AS Year,
EXTRACT(Month FROM o.order_date) AS Month_number,
Monthname(o.order_date) as Month_name ,
SUM(((oi.quantity * oi.list_price) - oi.discount)) AS monthly_sales
FROM order_items oi
INNER JOIN 
orders o ON oi.order_id = o.order_id
INNER JOIN
stores s ON s.store_id = o.store_id
GROUP BY s.store_id, s.store_name,year, Month_number,Month_name 
order by s.store_id, Year, Month_number ASC)
select store_id,store_name,Year,Month_name,monthly_sales from cte_monthaly_trend ;

-- 4.	What is the most popular category of products sold?
select ct.category_id , ct.category_name,
count(oi.quantity) count_of_sold_product from products p
inner join order_items oi 
on p.product_id = oi.product_id
inner join categories ct 
on ct.category_id = p.category_id
group by ct.category_id , ct.category_name
order by count_of_sold_product DESC 
limit 1;

-- 5.	What is the percentage contribution of each brand to the total sales?
with cte_percentage_contribution as (
select b.brand_name ,
 sum(((oi.quantity * oi.list_price) - oi.discount)) total_revenue_per_brnd ,
SUM(SUM(((oi.quantity * oi.list_price) - oi.discount))) OVER () AS total_revenue
from brands b
left join products p
on b.brand_id = p.brand_id
left join order_items oi
on p.product_id = oi.product_id
group by b.brand_name )
select Brand_name ,total_revenue_per_brnd , total_revenue,
 round(((total_revenue_per_brnd / total_revenue) *100),2) as percentage_contribution_per_brand 
from cte_percentage_contribution 
order by percentage_contribution_per_brand  desc ;

-- 6.	What are the top 5 best-selling products?
with cte_product as(select p.product_id, p.product_name, 
sum(quantity) total_quantity , dense_rank() over( order by sum(quantity) desc) as rk 
from products p inner join order_items oi 
on p.product_id = oi.product_id group by p.product_id, p.product_name)
select * from  cte_product where rk <6;

-- 7.	Which category of products generates the most revenue?
select  ct.category_id , ct.category_name,sum(((oi.quantity * oi.list_price) - oi.discount)) total_revenue  
from categories ct  
left join products p on ct.category_id = p.category_id
left join order_items oi on p.product_id = oi.product_id
group by ct.category_id , ct.category_name 
order by total_revenue DESC
limit 1;


-- 8.	What are the monthly sales trends for the current year 2018?
with cte_monthaly_trend as(
SELECT s.store_id, s.store_name,
EXTRACT(YEAR FROM o.order_date) AS Year,
EXTRACT(Month FROM o.order_date) AS Month_number,
Monthname(o.order_date) as Month_name ,
SUM(((oi.quantity * oi.list_price) - oi.discount)) AS monthly_sales
FROM order_items oi
INNER JOIN 
orders o ON oi.order_id = o.order_id
INNER JOIN
stores s ON s.store_id = o.store_id
GROUP BY s.store_id, s.store_name,year, Month_number,Month_name 
order by s.store_id, Year, Month_number ASC)
select store_id,store_name,
Year,Month_name,monthly_sales 
from cte_monthaly_trend 
where  year = 2018;



## Customer Analysis:##

-- 1.	Who are the top 5 customers by total spending?
with cte_top_customers as(
select c.customer_id ,c.first_name , c.last_name,
sum(((oi.quantity * oi.list_price) - oi.discount)) amount_spend,
dense_rank() over(order by sum(((oi.quantity * oi.list_price) - oi.discount)) DESC ) as rk
from customers c
left  join orders o 
on o.customer_id = c.customer_id
left join order_items oi
on oi.order_id = o.order_id
group by c.customer_id ,c.first_name , c.last_name)
select * from cte_top_customers  where rk <6 ;

-- 2.	What is the distribution of customers by region?
select state,
count(*)  customers_distribution   
from customers
group by state;









## Inventory Management:##
-- 1.	What is the total stock quantity for each product in each store?
select s.store_id ,s.store_name ,p.product_id,p.product_name, 
sum(quantity)  as total_stock_quantity
from stores s 
inner join stocks st 
on s.store_id = st.store_id 
inner join products p 
on p.product_id = st.product_id
group by store_id ,store_name ,p.product_id,p.product_name;

-- 2.	What is the average quantity of each product across all stores?

select p.product_id, p.product_name,
 round(AVG(quantity),2) Avg_stock_quantity from stores s 
inner join stocks st 
on s.store_id = st.store_id 
inner join products p 
on p.product_id = st.product_id
group by p.product_id ,p.product_name 
order by Avg_stock_quantity  DESC ;

-- 3.	Which product has the highest quantity in stock?
select p.product_id, p.product_name,
sum(quantity) total_stock_quantity
from products p 
inner join  stocks st 
on p.product_id = st.product_id
group by p.product_id, p.product_name
order by total_stock_quantity desc
limit 1;
-- 4.	Are there any products that are out of stock (quantity = 0) in any of the stores?
select s.store_id ,s.store_name ,p.product_id,p.product_name, 
sum(quantity) total_stock_quantity from stores s 
inner join stocks st on s.store_id = st.store_id 
inner join products p  on p.product_id = st.product_id
group by store_id ,store_name ,p.product_id ,p.product_name
having total_stock_quantity = 0;



-- 5.	Which products have the highest and lowest turnover rates?
WITH cte_amount_spend AS (
    SELECT p.product_id, p.product_name,SUM(((oi.quantity * oi.list_price) - oi.discount)) AS amount_spend
    FROM products p INNER JOIN order_items oi 
    ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name
),
ranked_cte AS (
    SELECT product_id, product_name, amount_spend,RANK() OVER (ORDER BY amount_spend DESC) AS rank_high,
        RANK() OVER (ORDER BY amount_spend) AS rank_low FROM cte_amount_spend
)
SELECT product_id,product_name, amount_spend FROM ranked_cte
WHERE rank_high = 1 OR rank_low = 1;




-- 6.	What is the average time a product spends in inventory before being sold?
SELECT p.product_id, 
round(AVG(DATEDIFF(shipped_date, order_date)),2) AS avg_days_spent
FROM orders o
INNER JOIN order_items oi 
ON o.order_id = oi.order_id
INNER JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.product_id
order by avg_days_spent desc;



##Store Performance:## 
-- 1.	What is the average discount given by each store?
select s.store_id,
s.store_name ,
 avg(oi.discount)  avg_discount
 from stores s
 left join orders o 
 on s.store_id = o.store_id
 left join order_items oi 
 on o.order_id =oi.order_id
 group by s.store_id,
s.store_name 
order by  avg_discount DESC;

-- 2.	Which store has the highest total quantity of products?
select s.store_id ,s.store_name , sum(quantity) total_stock_quantity from stores s 
inner join stocks st 
on s.store_id = st.store_id 
group by store_id ,store_name
order by total_stock_quantity DESC
limit 1;

-- 3.	Which store has the highest sales volume?
select s.store_id ,s.store_name , 
SUM(((oi.quantity * oi.list_price) - oi.discount)) AS Sale_volume
 from stores s 
inner join orders o
on s.store_id = o.store_id 
inner join order_items oi 
on o.order_id = oi.order_id
group by store_id ,store_name
order by Sale_volume DESC
limit 1;

-- 4.	What is the revenue per employee for each store?
select s.store_id ,s.store_name , st.staff_id,
SUM(((oi.quantity * oi.list_price) - oi.discount)) AS Sale_volume
from stores s
left join staffs st 
on st.store_id = s.store_id
left join orders o
on st.staff_id = o.staff_id 
left join order_items oi 
on o.order_id = oi.order_id
group by store_id ,store_name,st.staff_id ;



##Staff Analysis:##
-- 1.	Which staff members have processed the most orders?
select s.staff_id,s.first_name ,s.last_name ,count(*) order_processed  from staffs s
inner join orders o 
on s.staff_id = o.staff_id
group by s.staff_id,s.first_name ,s.last_name 
order by order_processed  DESC
limit 1;

-- 2.	Which staff members have the highest sales numbers?
select st.staff_id,st.first_name,st.last_name,
SUM(((oi.quantity * oi.list_price) - oi.discount)) AS Sale_volume
from  staffs st 
left join orders o
on st.staff_id = o.staff_id 
left join order_items oi 
on o.order_id = oi.order_id
group by st.staff_id,st.first_name,st.last_name
order by Sale_volume DESC 
limit 1;



##Market Basket Analysis:##
-- 1.	Which products are most often sold together?
WITH cte_order_products AS (
    SELECT o.order_id, p.product_id, p.product_name,o.order_date
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
),
cte_product_pairs AS (
    SELECT op1.product_id AS product1_id,
        op1.product_name AS product1_name,
        op2.product_id AS product2_id,
        op2.product_name AS product2_name,
        COUNT(*) AS pair_count
    FROM cte_order_products op1
    INNER JOIN cte_order_products op2 
    ON op1.order_id = op2.order_id AND op1.product_id < op2.product_id
    GROUP BY op1.product_id, op1.product_name, op2.product_id, op2.product_name
    HAVING COUNT(*) > 1
)
SELECT product1_id,product1_name,
    product2_id, product2_name,pair_count
FROM cte_product_pairs
ORDER BY pair_count desc;




