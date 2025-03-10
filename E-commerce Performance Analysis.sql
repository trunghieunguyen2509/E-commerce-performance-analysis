
-- QUARTERLY BUSINESS GROWTH ANALYSIS
-- Tracks sessions and orders over time to measure business growth trajectory
SELECT 
    YEAR(w.created_at) AS Year,
    QUARTER(w.created_at) AS Quarter,
    COUNT(w.website_session_id) AS sessions,
    COUNT(o.order_id) AS orders
FROM website_sessions w 
LEFT JOIN orders o ON w.website_session_id = o.website_session_id
GROUP BY Year, Quarter;

-- KEY PERFORMANCE INDICATORS BY QUARTER
-- Measures conversion rate and revenue metrics to evaluate overall business performance
SELECT 
    YEAR(w.created_at) AS Year,
    QUARTER(w.created_at) AS Quarter,
    (COUNT(o.order_id) / COUNT(w.website_session_id)) AS session_to_order_conv_rate, 
    (SUM(o.price_usd * o.items_purchased) / COUNT(o.order_id)) AS avg_revenue_per_order, 
    (SUM(o.price_usd * o.items_purchased) / COUNT(w.website_session_id)) AS avg_revenue_per_session
FROM website_sessions w 
LEFT JOIN orders o ON w.website_session_id = o.website_session_id
GROUP BY Year, Quarter;

-- MARKETING CHANNEL PERFORMANCE BY QUARTER
-- Tracks order volume from different marketing channels to evaluate campaign effectiveness
SELECT 
    YEAR(w.created_at) AS Year,
    QUARTER(w.created_at) AS Quarter,
    COUNT(CASE WHEN w.utm_source = 'gsearch' AND w.utm_campaign = 'brand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) AS gsearch_brand_orders,
    COUNT(CASE WHEN w.utm_source = 'gsearch' AND w.utm_campaign = 'nonbrand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) AS gsearch_nonbrand_orders,
    COUNT(CASE WHEN w.utm_source = 'bsearch' AND w.utm_campaign = 'nonbrand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) AS bsearch_nonbrand_orders,
    COUNT(CASE WHEN w.utm_source = 'bsearch' AND w.utm_campaign = 'brand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) AS bsearch_brand_orders 
FROM website_sessions w 
LEFT JOIN orders o ON w.website_session_id = o.website_session_id
GROUP BY Year, Quarter;

-- MARKETING CHANNEL CONVERSION RATES
-- Compares conversion efficiency across marketing channels to identify top performers
SELECT 
    YEAR(w.created_at) AS Year,
    QUARTER(w.created_at) AS Quarter,
    COUNT(CASE WHEN w.utm_source = 'gsearch' AND w.utm_campaign = 'brand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) / COUNT(DISTINCT w.website_session_id) AS gsearch_brand_conv_rate,
    COUNT(CASE WHEN w.utm_source = 'gsearch' AND w.utm_campaign = 'nonbrand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) / COUNT(DISTINCT w.website_session_id) AS gsearch_nonbrand_conv_rate,
    COUNT(CASE WHEN w.utm_source = 'bsearch' AND w.utm_campaign = 'nonbrand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) / COUNT(DISTINCT w.website_session_id) AS bsearch_nonbrand_conv_rate,
    COUNT(CASE WHEN w.utm_source = 'bsearch' AND w.utm_campaign = 'brand' AND o.order_id IS NOT NULL THEN 1 ELSE NULL END) / COUNT(DISTINCT w.website_session_id) AS bsearch_brand_conv_rate 
FROM website_sessions w 
LEFT JOIN orders o ON w.website_session_id = o.website_session_id
GROUP BY Year, Quarter;

-- PRODUCT PERFORMANCE ANALYSIS
-- Evaluates revenue and profitability of key products to identify best performers
WITH product_data AS (
    -- Calculate revenue and margin by product per month
    SELECT 
        YEAR(o.created_at) AS Year,
        MONTH(o.created_at) AS Month,
        p.product_name,
        SUM(o.price_usd) AS revenue,
        SUM(o.price_usd - o.cogs_usd) AS margin
    FROM products p 
    LEFT JOIN order_items o ON p.product_id = o.product_id
    WHERE p.product_name IN ('The Original Mr. Fuzzy', 'The Forever Love Bear', 
                          'The Birthday Sugar Panda', 'The Hudson River Mini bear')
    GROUP BY Year, Month, p.product_name
),
summary AS (
    -- Aggregate monthly performance by product and calculate totals
    SELECT 
        Year, Month,
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
    FROM product_data
    GROUP BY Year, Month
)
SELECT * FROM summary
ORDER BY Year, Month;

-- PRODUCT PAGE NAVIGATION ANALYSIS - STEP 1
-- Identify sessions that viewed the products page
CREATE TEMPORARY TABLE product_session AS
SELECT 
    created_at,
    website_session_id,
    website_pageview_id
FROM website_pageviews
WHERE pageview_url = '/products';

-- PRODUCT PAGE NAVIGATION ANALYSIS - STEP 2
-- Track the next page users visit after the products page
CREATE TEMPORARY TABLE next_product_session AS
SELECT 
    p.created_at, 
    p.website_session_id, 
    MIN(w.website_pageview_id) AS next_page
FROM product_session p 
LEFT JOIN website_pageviews w 
    ON p.website_session_id = w.website_session_id 
    AND w.created_at > p.created_at
GROUP BY p.created_at, p.website_session_id;

-- PRODUCT PAGE EFFECTIVENESS
-- Measures user engagement with products and conversion to orders
SELECT 
    YEAR(n.created_at) AS year,
    MONTH(n.created_at) AS month,
    COUNT(n.website_session_id) AS product_page_sessions,
    COUNT(CASE WHEN n.next_page IS NOT NULL THEN 1 ELSE NULL END) AS click_to_next,
    COUNT(CASE WHEN n.next_page IS NOT NULL THEN 1 ELSE NULL END) / COUNT(n.website_session_id) AS clickthrough_rate,
    COUNT(o.order_id) AS orders,
    COUNT(o.order_id) / COUNT(n.website_session_id) AS product_to_order_rate
FROM next_product_session n 
LEFT JOIN orders o ON n.website_session_id = o.website_session_id
GROUP BY year, month;