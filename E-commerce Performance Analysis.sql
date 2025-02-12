USE mavenfuzzyfactory;
--Queries to show the growth in terms of sessions and orders on the website*
select year(w.created_at) as Year, 
quarter(w.created_at) as Quarter,
count(w.website_session_id) as sessions,
count(o.order_id) as orders
from website_sessions w left join orders o on w.website_session_id = o.website_session_id
group by Year, Quarter;

--Query to measure the company's performance through session-to-order conversion rate, revenue per order, or revenue per session
select year(w.created_at) as Year,
quarter(w.created_at) as quarter,
(count(o.order_id)/count(w.website_session_id)) as session_to_order,
(sum(o.price_usd*o.items_purchased)/count(o.order_id)) as revenue_per_order,
(sum(o.price_usd*o.items_purchased)/count(w.website_session_id)) as revenue_per_session
from website_sessions w left join orders o on w.website_session_id = o.website_session_id
group by Year, quarter;

--Query to display the growth of different segments by quarter based on orders.
select year(w.created_at) as Year,
quarter(w.created_at) as Quarter, 
count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end) as gsearch_brand_orders,
count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end) as gsearch_nonbrand_orders,
count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end) as bsearch_nonbrand_orders,
count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end) as bsearch_brand_orders 
from website_sessions w left join orders o on w.website_session_id = o.website_session_id
group by Year, Quarter;

--Query to display the session-to-order conversion rate for the segments mentioned in the previous requirement.
select year(w.created_at) as Year,
quarter(w.created_at) as Quarter, 
count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end)/count(distinct w.website_session_id) as gsearch_brand_orders,
count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end)/count(distinct w.website_session_id) as gsearch_nonbrand_orders,
count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end)/count(distinct w.website_session_id) as bsearch_nonbrand_orders,
count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end)/count(distinct w.website_session_id) as bsearch_brand_orders 
from website_sessions w left join orders o on w.website_session_id = o.website_session_id
group by Year, Quarter;

--Query to display revenue and profit by product, total revenue, and total profit for all products.
WITH product_data AS (
    SELECT 
        YEAR(o.created_at) AS Year,
        MONTH(o.created_at) AS Month,
        p.product_name,
        SUM(o.price_usd) AS revenue,
        SUM(o.price_usd - o.cogs_usd) AS margin
    FROM 
        products p 
    LEFT JOIN 
        order_items o 
    ON 
        p.product_id = o.product_id
    WHERE 
        p.product_name IN ('The Original Mr. Fuzzy', 'The Forever Love Bear', 
                           'The Birthday Sugar Panda', 'The Hudson River Mini bear')
    GROUP BY 
        Year, Month, p.product_name
),
summary AS (
    SELECT 
        Year,
        Month,
        SUM(CASE WHEN product_name = 'The Original Mr. Fuzzy' THEN revenue ELSE 0 END) AS mrfuzzy_rev,
        SUM(CASE WHEN product_name = 'The Original Mr. Fuzzy' THEN margin ELSE 0 END) AS mrfuzzy_mar,
        SUM(CASE WHEN product_name = 'The Forever Love Bear' THEN revenue ELSE 0 END) AS forever_love_bear_rev,
        SUM(CASE WHEN product_name = 'The Forever Love Bear' THEN margin ELSE 0 END) AS love_bear_mar,
        SUM(CASE WHEN product_name = 'The Birthday Sugar Panda' THEN revenue ELSE 0 END) AS birthday_sugar_panda_rev,
        SUM(CASE WHEN product_name = 'The Birthday Sugar Panda' THEN margin ELSE 0 END) AS sugar_panda_mar,
        SUM(CASE WHEN product_name = 'The Hudson River Mini bear' THEN revenue ELSE 0 END) AS mini_bear_rev,
        SUM(CASE WHEN product_name = 'The Hudson River Mini bear' THEN margin ELSE 0 END) AS mini_bear_mar,
        SUM(revenue) AS total_revenue,
        SUM(margin) AS total_margin
    FROM 
        product_data
    GROUP BY 
        Year, Month
)
SELECT * 
FROM summary
ORDER BY Year, Month;

--Query to analyse new products by tracking the percentage of sessions moving from /products to other pages and to the order page over time.
create temporary table product_session
select created_at,
website_session_id,
website_pageview_id
from website_pageviews
where pageview_url ='/products';

select * from product_session;
drop table product_session;

create temporary table next_product_session
select p.created_at, p.website_session_id, min(w.website_pageview_id) as next_page
from product_session p left join website_pageviews w on p.website_session_id = w.website_session_id and w.created_at > p.created_at
group by   p.created_at,p.website_session_id;

select * from next_product_session;

--Query to measure the effectiveness of bundled product sales.
select year(n.created_at) as year,
month(n.created_at) as month, 
count(n.website_session_id) as product_page_sessions,
count(case when n.next_page is not null then 1 else null end) as click_to_next,
sum(case when n.next_page is not null then 1 else null end)/count(n.website_session_id) as clickthrough_rate,
count(o.order_id) as orders,
count(o.order_id)/count(n.website_session_id) as product_to_order_rate
from next_product_session n left join orders o on n.website_session_id = o.website_session_id
group by year, month;





