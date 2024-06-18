use magist;


drop temporary table if exists tech_products;
create temporary table tech_products
select distinct p.product_id, p.product_category_name, pc.product_category_name_english, "Tech_products"
from products as p
inner join product_category_name_translation as pc using (product_category_name)
-- where product_category_name_english in ("console", "")
where pc.product_category_name_english like '%audio%'
or pc.product_category_name_english like '%console%'
or pc.product_category_name_english like '%game%'
or pc.product_category_name_english like '%pc%'
or pc.product_category_name_english like '%computer%'
or pc.product_category_name_english like '%dvd%'
or pc.product_category_name_english like '%electronic%'
or pc.product_category_name_english like '%tele%'
or pc.product_category_name_english like '%tablet%'
or pc.product_category_name_english like '%phone%';

select * from tech_products;


-- 3.1. In relation to the products:

-- What categories of tech products does Magist have?

select distinct product_category_name, product_category_name_english
from tech_products ;


-- How many products of these tech categories have been sold 
-- (within the time window of the database snapshot)? 

-- answer 1

select count(distinct product_id) as "number of products sold"
from products
inner join order_items using (product_id)
inner join product_category_name_translation using (product_category_name)
inner join orders using (order_id)
where (product_category_name_english like '%audio%'
or product_category_name_english like '%console%'
or product_category_name_english like '%game%'
or product_category_name_english like '%pc%'
or product_category_name_english like '%computer%'
or product_category_name_english like '%dvd%'
or product_category_name_english like '%electronic%'
or product_category_name_english like '%tele%'
or product_category_name_english like '%tablet%'
or product_category_name_english like '%phone%')
and (orders.order_status not in ("canceled", "unavailable"));

-- answer 2

select count(distinct product_id) as "number of products sold"
from tech_products
inner join order_items using (product_id)
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable");


-- What percentage does that represent from the overall number of products sold?

select
round(
(select count(distinct product_id) as "number of products sold"
from tech_products
inner join order_items using (product_id)
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable"))
/
(select count(distinct product_id) as "number of products sold"
from products
inner join order_items using (product_id)
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable"))
* 100
, 2) as "% tech products";



-- What’s the average price of the products being sold?

-- Average price of all products being sold

select round(avg(price),2)
from order_items
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable");

-- Average price of tech products being sold

select round(avg(price), 2)
from tech_products
inner join order_items using (product_id)
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable");

-- Are expensive tech products popular? *
-- * TIP: Look at the function CASE WHEN to accomplish this task.

select CASE
WHEN price>500 THEN 'Expensive'
WHEN price> 100 THEN 'Mid-level'
ELSE 'Cheap'
END AS prices, count(product_id) as counts
from order_items 
inner join tech_products using (product_id)
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable")
group by prices;


-- 3.2. In relation to the sellers:

-- How many months of data are included in the magist database?

-- ??


-- How many sellers are there? 

SELECT count(seller_id) FROM sellers;


-- How many Tech sellers are there?
 
select count(distinct seller_id) 
from sellers
inner join order_items using (seller_id)
inner join tech_products using (product_id);


-- What percentage of overall sellers are Tech sellers?

select (
  round( 
    (select count(distinct seller_id) 
    from sellers
    inner join order_items using (seller_id)
    inner join tech_products using (product_id))
    /
    (select count(seller_id) from sellers)
    * 100, 2
  )
) as "% of tech sellers";


-- What is the total amount earned by all sellers?

select round(sum(price), 2) as total_seller_earnings 
from order_items
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable");


--  What is the total amount earned by all Tech sellers?

select round(sum(price), 2) as total_tech_seller_earnings 
from order_items
inner join tech_products using (product_id)
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable");


-- Can you work out the average monthly income of all sellers?

select year(order_purchase_timestamp) as years, month(order_purchase_timestamp) as months, round(avg(price), 2) 
from order_items
inner join orders using (order_id)
where orders.order_status not in ("canceled", "unavailable")
group by years, months;


-- Can you work out the average monthly income of Tech sellers?

select year(order_purchase_timestamp) as years, month(order_purchase_timestamp) as months, round(avg(price), 2) 
from order_items
inner join orders using (order_id)
inner join tech_products using (product_id)
where orders.order_status not in ("canceled", "unavailable")
group by years, months;



-- 3.3. In relation to the delivery time:

-- > What’s the average time between the order being placed and the product being delivered?

select "average order duration" as "description", ROUND(avg(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp)), 2) as Days
from orders
where order_status = "delivered";


-- > How many orders are delivered on time vs orders delivered with a delay?

select
case 
when DATEDIFF(order_estimated_delivery_date,order_delivered_customer_date) >= 0 THEN "ON TIME"
else "DELAY"
end as DELIVERY, count(order_id) as Divered
from orders
where order_status = "delivered"
group by DELIVERY;

with timely_delivery as (
select order_id,
case 
when DATEDIFF(order_estimated_delivery_date,order_delivered_customer_date) >= 0 THEN "ON TIME"
else "DELAY"
end as DELIVERY
from orders
where order_status = "delivered"
)
SELECT DELIVERY, count(*)
from timely_delivery 
group by DELIVERY;



-- > Is there any pattern for delayed orders, e.g. big products being delayed more often?

-- lets compare the size and weight of the delay delivery products with the on_time ones
-- to see if size and weight causes delay

with deliveree as (
select order_id, product_id, customer_id, seller_id, product_category_name_translation.product_category_name_english,
case 
when DATEDIFF(order_estimated_delivery_date,order_delivered_customer_date) > 0 THEN "on time"
else "delay"
end as delivery
from orders
inner join order_items using (order_id)
inner join products using (product_id)
inner join product_category_name_translation using (product_category_name)
where orders.order_status = "delivered"
)
select pcnt.product_category_name_english, product_weight_g, product_length_cm, product_height_cm, product_width_cm, delivery -- , count(*)
from product_category_name_translation as pcnt
inner join products using (product_category_name)
inner join deliveree using (product_id)
where deliveree.delivery = "delay";


with deliveree as (
select order_id, product_id, customer_id, seller_id, product_category_name_translation.product_category_name_english,
case 
when DATEDIFF(order_delivered_customer_date,order_purchase_timestamp) > 0 THEN "on time"
else "delay"
end as delivery
from orders
inner join order_items using (order_id)
inner join products using (product_id)
inner join product_category_name_translation using (product_category_name)
where orders.order_status = "delivered"
)
select pcnt.product_category_name_english, product_weight_g, product_length_cm, product_height_cm, product_width_cm, delivery -- , count(*)
from product_category_name_translation as pcnt
inner join products using (product_category_name)
inner join deliveree using (product_id)
where deliveree.delivery = "on time";

-- we have observed no correlation of weight and size to delays, therefore are not a cause for the delays







