USE mavenfuzzyfactory;

--------------------------------------------------------------------------------
-- Query 1: Growth in Sessions and Orders by Quarter
-- This query aggregates the total number of website sessions and orders grouped
-- by Year and Quarter, which helps to observe growth trends over time.
--------------------------------------------------------------------------------
select 
    year(w.created_at) as Year,              -- Extracts the year from the session timestamp.
    quarter(w.created_at) as Quarter,          -- Extracts the quarter from the session timestamp.
    count(w.website_session_id) as sessions,   -- Counts total sessions.
    count(o.order_id) as orders                -- Counts total orders (note: using LEFT JOIN ensures sessions with no orders are still counted).
from website_sessions w 
left join orders o on w.website_session_id = o.website_session_id
group by Year, Quarter;

--------------------------------------------------------------------------------
-- Query 2: Company Performance Metrics
-- This query calculates key performance indicators (KPIs) such as:
-- 1. Session-to-order conversion rate (orders divided by sessions).
-- 2. Revenue per order (total revenue divided by the number of orders).
-- 3. Revenue per session (total revenue divided by the number of sessions).
--------------------------------------------------------------------------------
select 
    year(w.created_at) as Year,              -- Year of the session.
    quarter(w.created_at) as quarter,          -- Quarter of the session.
    (count(o.order_id) / count(w.website_session_id)) as session_to_order, -- Conversion rate from session to order.
    (sum(o.price_usd * o.items_purchased) / count(o.order_id)) as revenue_per_order, -- Average revenue per order.
    (sum(o.price_usd * o.items_purchased) / count(w.website_session_id)) as revenue_per_session -- Average revenue per session.
from website_sessions w 
left join orders o on w.website_session_id = o.website_session_id
group by Year, quarter;

--------------------------------------------------------------------------------
-- Query 3: Growth of Different Marketing Segments by Quarter
-- This query segments orders by the combination of utm_source and utm_campaign.
-- It counts orders per quarter for:
-- - Google Search (gsearch) with brand and nonbrand campaigns.
-- - Bing Search (bsearch) with nonbrand and brand campaigns.
--------------------------------------------------------------------------------
select 
    year(w.created_at) as Year,              -- Year of the session.
    quarter(w.created_at) as Quarter,          -- Quarter of the session.
    count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end) as gsearch_brand_orders,
    count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end) as gsearch_nonbrand_orders,
    count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end) as bsearch_nonbrand_orders,
    count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end) as bsearch_brand_orders 
from website_sessions w 
left join orders o on w.website_session_id = o.website_session_id
group by Year, Quarter;

--------------------------------------------------------------------------------
-- Query 4: Session-to-Order Conversion Rate for Marketing Segments
-- Similar to Query 3, but now calculates the conversion rate for each segment by dividing
-- the number of orders by the distinct sessions in each quarter.
--------------------------------------------------------------------------------
select 
    year(w.created_at) as Year,              -- Year of the session.
    quarter(w.created_at) as Quarter,          -- Quarter of the session.
    count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end) / count(distinct w.website_session_id) as gsearch_brand_orders,
    count(case when w.utm_source = 'gsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end) / count(distinct w.website_session_id) as gsearch_nonbrand_orders,
    count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'nonbrand' and o.order_id is not null then 1 else null end) / count(distinct w.website_session_id) as bsearch_nonbrand_orders,
    count(case when w.utm_source = 'bsearch' and w.utm_campaign = 'brand' and o.order_id is not null then 1 else null end) / count(distinct w.website_session_id) as bsearch_brand_orders 
from website_sessions w 
left join orders o on w.website_session_id = o.website_session_id
group by Year, Quarter;

--------------------------------------------------------------------------------
-- Query 5: Revenue and Profit by Product and Overall Totals
-- This query first creates a common table expression (CTE) 'product_data' to calculate
-- monthly revenue and margin (profit) for each product of interest.
-- The 'summary' CTE then aggregates this data to provide:
-- - Revenue and margin per product.
-- - Total revenue and margin across all products.
--------------------------------------------------------------------------------
WITH product_data AS (
    SELECT 
        YEAR(o.created_at) AS Year,          -- Year of the order.
        MONTH(o.created_at) AS Month,          -- Month of the order.
        p.product_name,                        -- Name of the product.
        SUM(o.price_usd) AS revenue,           -- Total revenue for the product.
        SUM(o.price_usd - o.cogs_usd) AS margin  -- Total margin (profit) for the product.
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
        SUM(revenue) AS total_revenue,         -- Total revenue across all products.
        SUM(margin) AS total_margin            -- Total margin (profit) across all products.
    FROM 
        product_data
    GROUP BY 
        Year, Month
)
SELECT * 
FROM summary
ORDER BY Year, Month;

--------------------------------------------------------------------------------
-- Query 6: Analysis of New Products Navigation Behavior
-- This section analyzes how sessions flow from the '/products' page to subsequent pages,
-- helping to track user behavior related to new products.

-- Create a temporary table capturing sessions that visited the '/products' page.
create temporary table product_session as
select 
    created_at,                              -- Timestamp of the pageview.
    website_session_id,                      -- Session ID.
    website_pageview_id                      -- Unique ID for the pageview.
from website_pageviews
where pageview_url = '/products';

-- Display the temporary table to verify its contents.
select * from product_session;

-- Create a temporary table to find the next page visited in the same session after '/products'.
create temporary table next_product_session as
select 
    p.created_at, 
    p.website_session_id, 
    min(w.website_pageview_id) as next_page   -- Finds the next pageview ID after the '/products' pageview.
from product_session p 
left join website_pageviews w on p.website_session_id = w.website_session_id and w.created_at > p.created_at
group by p.created_at, p.website_session_id;

-- Display the table to see the next page navigation.
select * from next_product_session;

--------------------------------------------------------------------------------
-- Query 7: Effectiveness of Bundled Product Sales
-- This query evaluates the effectiveness of bundled product sales by calculating:
-- 1. The number of sessions on product pages.
-- 2. The number of sessions where users clicked to view the next page (indicating interest).
-- 3. The click-through rate from the product page to the next page.
-- 4. The number of orders from these sessions.
-- 5. The conversion rate from product page sessions to orders.
--------------------------------------------------------------------------------
select 
    year(n.created_at) as year,             -- Year from the next_product_session timestamp.
    month(n.created_at) as month,           -- Month from the next_product_session timestamp.
    count(n.website_session_id) as product_page_sessions, -- Total sessions starting on the product page.
    count(case when n.next_page is not null then 1 else null end) as click_to_next, -- Count of sessions that navigated to a next page.
    sum(case when n.next_page is not null then 1 else null end) / count(n.website_session_id) as clickthrough_rate, -- Click-through rate calculation.
    count(o.order_id) as orders,            -- Total orders from these sessions.
    count(o.order_id) / count(n.website_session_id) as product_to_order_rate -- Conversion rate from product page sessions to orders.
from next_product_session n 
left join orders o on n.website_session_id = o.website_session_id
group by year, month;