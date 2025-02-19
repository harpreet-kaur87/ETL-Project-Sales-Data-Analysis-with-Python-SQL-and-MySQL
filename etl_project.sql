drop database orders_db;
create database orders_db;
use orders_db;

create table orders
(order_id int,
order_date date,
ship_mode varchar(30),
segment varchar(40),
country varchar(50),
city varchar(50),
state varchar(50),
postal_code int,
region varchar(30),
category varchar(30),
sub_category varchar(50),
product_id varchar(50),
quantity int,
discount float,
sales_price float,
profit float);

select * from orders;

-- Purchase Frequency by category
select category, count(order_id) as total_orders from orders
group by category order by total_orders desc;

-- Display total sales of each category in each region;
select region,
round(sum(case when category = 'Furniture' then sales_price end),0) as furniture,
round(sum(case when category = 'Office Supplies' then sales_price end),0) as office_supplies,
round(sum(case when category = 'Technology' then sales_price end),0) as technology
from orders group by region;

-- Top 3 best selling products in Each Category
with cte as(
select category, sub_category, product_id, round(sum(quantity*sales_price),0) as total_price
from orders group by category, sub_category, product_id),
cte2 as (
select *,
dense_rank() over(partition by category order by total_price desc) as rn
from cte)
select * from cte2 where rn <= 3; 

-- Top 3 Cities by Sales in Each Region
with cte as(
select region, city, round(sum(quantity * sales_price),0) as total from orders group by region, city),
cte2 as(
select *,
dense_rank() over(partition by region order by total desc) as rn
from cte)
select * from cte2 where rn <= 3;

-- Month-over-Month (MoM) Sales Growth
with cte as(
select date_format(order_date,'%Y-%m') as month_and_year, round(sum(quantity * sales_price),0) as total from orders group by date_format(order_date,'%Y-%m') order by date_format(order_date,'%Y-%m')),
previous_month as(
select month_and_year, total as current_month_sales,
lag(total,1) over(partition by left(month_and_year,4)) as previous_month_sales
from cte)
select month_and_year, current_month_sales, previous_month_sales,
concat(round((current_month_sales - previous_month_sales)*100 / previous_month_sales,0),'%') as mom_growth
 from previous_month;

-- For each product category, find the month with the highest total sales;
with cte as(
select date_format(order_date, '%Y-%m') as year_and_month, category, round(sum(sales_price * quantity),0) as total
from orders group by category, date_format(order_date, '%Y-%m')),
cte2 as(
select *,
row_number() over(partition by category, left(year_and_month,4) order by total desc) as rn
from cte)
select * from cte2 where rn = 1;

-- Total sales by each segment for each year
select year(order_date) as year,
round(sum(case when segment = 'Consumer' then quantity * sales_price end),0) as consumer_segment,
round(sum(case when segment = 'Corporate' then quantity * sales_price end),0) as corporate_segment,
round(sum(case when segment = 'Home Office' then quantity * sales_price end),0) as homeoffice_segment
from orders group by year;

-- Year-over-Year (YoY) Sales Growth
with current_year_sales as(
select year(order_date) as year, round(sum(quantity * sales_price),0) as total_sales from orders group by year order by year),
previous_year as(
select year, total_sales as current_year_sales, 
lag(total_sales,1) over() as previous_year_sales
from current_year_sales)
select year, previous_year_sales, current_year_sales,
concat(round((current_year_sales - previous_year_sales)*100 / previous_year_sales,2),'%') as YOY_growth
 from previous_year;
 
-- Top 3 Most Profitable Product in Each Category
with most_profitable_products as(
select category, product_id, sub_category, round(sum(profit),0) as total_profit
from orders group by category, product_id, sub_category),
top_3_products as(
select *,
dense_rank() over(partition by category order by total_profit desc) as rn
from most_profitable_products)
select *
from top_3_products where rn <= 3;

-- Identify the top 3 products with the highest quantity sold across all categories. Ensure these products are closely monitored to avoid stockouts.
with cte as(
select category, product_id, sub_category, sum(quantity) as total_quantity_sold
from orders group by category,product_id, sub_category),
top_quantity_products as(
select *,
dense_rank() over(partition by category order by total_quantity_sold desc) as rn
from cte)
select * from top_quantity_products where rn <= 3;