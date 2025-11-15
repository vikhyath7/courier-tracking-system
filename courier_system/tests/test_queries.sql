-- Test queries for Review-2 and Review-3

-- 1. Nested Query: Select customers who have unpaid deliveries or not delivered packages
SELECT DISTINCT c.*
FROM Customer c
WHERE c.customer_id IN (
    SELECT p.customer_id
    FROM Package p
    LEFT JOIN Delivery d ON p.package_id = d.package_id
    WHERE p.status != 'Delivered'
    OR d.delivery_status = 'Pending'
);

-- 2. Join Query: List of packages with sender name, branch_name and current status
SELECT p.tracking_id, 
       c.name as customer_name, 
       b.branch_name,
       p.status as current_status,
       td.update_time
FROM Package p
JOIN Customer c ON p.customer_id = c.customer_id
JOIN Branch b ON p.branch_id = b.branch_id
LEFT JOIN (
    SELECT package_id, status, update_time
    FROM Tracking_Details td1
    WHERE update_time = (
        SELECT MAX(update_time)
        FROM Tracking_Details td2
        WHERE td1.package_id = td2.package_id
    )
) td ON p.package_id = td.package_id
ORDER BY td.update_time DESC;

-- 3. Aggregate Query: Daily shipment count and revenue per branch
SELECT 
    b.branch_name,
    DATE(p.booking_date) as date,
    COUNT(*) as shipment_count,
    SUM(p.cost) as total_revenue
FROM Package p
JOIN Branch b ON p.branch_id = b.branch_id
GROUP BY b.branch_name, DATE(p.booking_date)
ORDER BY date DESC, total_revenue DESC;

-- 4. Trigger demonstration
-- First, check current tracking details
SELECT * FROM Tracking_Details WHERE package_id = 1;

-- Update package status (this will trigger new tracking entry)
UPDATE Package SET status = 'In Transit' WHERE package_id = 1;

-- Check new tracking details
SELECT * FROM Tracking_Details WHERE package_id = 1;

-- 5. Testing stored procedures
-- Create new package
CALL sp_create_package(1, 1, 2.5, 'Express', @tracking_id);
SELECT @tracking_id;

-- Update package status
SELECT @tracking_id;
CALL sp_update_status(@tracking_id, 'Mumbai Hub', 'In Transit', 2);

-- Confirm delivery
CALL sp_confirm_delivery(@tracking_id, 'John Recipient', '9999999999', 2);

-- 6. Function test
-- Test shipping cost calculation
SELECT compute_shipping_cost(2.5, 'Standard') as standard_cost,
       compute_shipping_cost(2.5, 'Express') as express_cost;