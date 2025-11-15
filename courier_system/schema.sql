-- Drop database if exists and create new one
DROP DATABASE IF EXISTS courier_db;
CREATE DATABASE courier_db;
USE courier_db;

-- Tables creation
DROP TABLE IF EXISTS Delivery;
DROP TABLE IF EXISTS Tracking_Details;
DROP TABLE IF EXISTS Package;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Branch;
DROP TABLE IF EXISTS Customer;

-- Customer table
CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    mobile_no VARCHAR(15),
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

-- Branch table
CREATE TABLE Branch (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    address TEXT,
    contact_no VARCHAR(15)
);

-- Staff table
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    role ENUM('Admin', 'DeliveryAgent') DEFAULT 'DeliveryAgent',
    contact_no VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255) NOT NULL,
    FOREIGN KEY(branch_id) REFERENCES Branch(branch_id) ON DELETE CASCADE
);

-- Package table
CREATE TABLE Package (
    package_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    tracking_id VARCHAR(20) UNIQUE NOT NULL,
    weight DECIMAL(6,2),
    cost DECIMAL(10,2),
    booking_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    delivery_date DATETIME NULL,
    status ENUM('Booked', 'Picked Up', 'In Transit', 'Out for Delivery', 'Delivered') DEFAULT 'Booked',
    FOREIGN KEY(customer_id) REFERENCES Customer(customer_id) ON DELETE CASCADE,
    FOREIGN KEY(branch_id) REFERENCES Branch(branch_id)
);

-- Tracking_Details table
CREATE TABLE Tracking_Details (
    tracking_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT,
    current_location VARCHAR(100),
    status VARCHAR(50),
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(package_id) REFERENCES Package(package_id) ON DELETE CASCADE
);

-- Delivery table
CREATE TABLE Delivery (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT,
    staff_id INT,
    recipient_name VARCHAR(100),
    recipient_contact VARCHAR(15),
    delivery_date DATETIME,
    delivery_status ENUM('Pending', 'Delivered') DEFAULT 'Pending',
    FOREIGN KEY(package_id) REFERENCES Package(package_id) ON DELETE CASCADE,
    FOREIGN KEY(staff_id) REFERENCES Staff(staff_id)
);

-- Function to compute shipping cost
DELIMITER //
CREATE FUNCTION compute_shipping_cost(weight DECIMAL, service VARCHAR(20))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE base DECIMAL(10,2);
    DECLARE per_kg DECIMAL(10,2);
    DECLARE total_cost DECIMAL(10,2);
    
    SET base = 50;
    SET per_kg = 20 * weight;
    SET total_cost = base + per_kg;
    
    IF service = 'Express' THEN
        SET total_cost = total_cost * 1.5;
    END IF;
    
    RETURN total_cost;
END //
DELIMITER ;

-- Procedure to create package
DELIMITER //
CREATE PROCEDURE sp_create_package(
    IN p_customer INT,
    IN p_branch INT,
    IN p_weight DECIMAL,
    IN p_service VARCHAR(20),
    OUT p_tracking VARCHAR(20)
)
BEGIN
    DECLARE v_cost DECIMAL(10,2);
    DECLARE v_random INT;
    
    -- Generate tracking ID (TRK + YYYYMMDD + random 4 digits)
    SET v_random = FLOOR(RAND() * 9000) + 1000;
    SET p_tracking = CONCAT('TRK', DATE_FORMAT(NOW(), '%Y%m%d'), v_random);
    
    -- Compute cost
    SET v_cost = compute_shipping_cost(p_weight, p_service);
    
    -- Insert package
    INSERT INTO Package (customer_id, branch_id, tracking_id, weight, cost)
    VALUES (p_customer, p_branch, p_tracking, p_weight, v_cost);
    
    -- Insert initial tracking detail
    INSERT INTO Tracking_Details (package_id, status)
    VALUES (LAST_INSERT_ID(), 'Booked');
END //
DELIMITER ;

-- Procedure to update status
DELIMITER //
CREATE PROCEDURE sp_update_status(
    IN p_tracking VARCHAR(20),
    IN p_location VARCHAR(100),
    IN p_status VARCHAR(50),
    IN p_staff_id INT
)
BEGIN
    DECLARE v_package_id INT;
    
    -- Get package_id
    SELECT package_id INTO v_package_id
    FROM Package
    WHERE tracking_id = p_tracking;
    
    -- Update package status
    UPDATE Package
    SET status = p_status,
        delivery_date = CASE WHEN p_status = 'Delivered' THEN NOW() ELSE delivery_date END
    WHERE package_id = v_package_id;
    
    -- Insert tracking detail
    INSERT INTO Tracking_Details (package_id, current_location, status)
    VALUES (v_package_id, p_location, p_status);
    
    -- If delivered, update delivery record
    IF p_status = 'Delivered' THEN
        UPDATE Delivery
        SET delivery_status = 'Delivered',
            delivery_date = NOW()
        WHERE package_id = v_package_id;
    END IF;
END //
DELIMITER ;

-- Trigger for package status change
DELIMITER //
CREATE TRIGGER trg_package_status_change
AFTER UPDATE ON Package
FOR EACH ROW
BEGIN
    IF NEW.status <> OLD.status THEN
        INSERT INTO Tracking_Details (package_id, current_location, status)
        VALUES (NEW.package_id, NULL, NEW.status);
    END IF;
END //
DELIMITER ;

-- Procedure to confirm delivery
DELIMITER //
CREATE PROCEDURE sp_confirm_delivery(
    IN p_tracking VARCHAR(20),
    IN p_recipient_name VARCHAR(100),
    IN p_recipient_contact VARCHAR(15),
    IN p_staff_id INT
)
BEGIN
    DECLARE v_package_id INT;
    
    -- Get package_id
    SELECT package_id INTO v_package_id
    FROM Package
    WHERE tracking_id = p_tracking;
    
    -- Insert/Update delivery record
    INSERT INTO Delivery (package_id, staff_id, recipient_name, recipient_contact, delivery_date, delivery_status)
    VALUES (v_package_id, p_staff_id, p_recipient_name, p_recipient_contact, NOW(), 'Delivered')
    ON DUPLICATE KEY UPDATE
        recipient_name = p_recipient_name,
        recipient_contact = p_recipient_contact,
        delivery_date = NOW(),
        delivery_status = 'Delivered';
    
    -- Update package status
    UPDATE Package
    SET status = 'Delivered',
        delivery_date = NOW()
    WHERE package_id = v_package_id;
END //
DELIMITER ;

-- Sample data insertion
-- Branches
INSERT INTO Branch (branch_name, location, address, contact_no) VALUES
('Main Branch', 'Bangalore', '123 MG Road, Bangalore', '9876543210'),
('North Branch', 'Delhi', '456 Chandni Chowk, Delhi', '9876543211'),
('South Branch', 'Chennai', '789 Anna Salai, Chennai', '9876543212');

-- Customers
INSERT INTO Customer (name, address, mobile_no, email, password) VALUES
('John Doe', '123 Main St', '9898989898', 'john@example.com', 'hashed_password_1'),
('Jane Smith', '456 Park Ave', '9797979797', 'jane@example.com', 'hashed_password_2'),
('Bob Wilson', '789 Lake View', '9696969696', 'bob@example.com', 'hashed_password_3'),
('Alice Brown', '321 Hill Road', '9595959595', 'alice@example.com', 'hashed_password_4'),
('Charlie Davis', '654 Valley St', '9494949494', 'charlie@example.com', 'hashed_password_5');

-- Staff
-- NOTE: For testing convenience the admin login below uses username 'admin' and password 'admin'.
-- In production, replace this with a secure hashed password.
INSERT INTO Staff (branch_id, name, role, contact_no, email, password) VALUES
(1, 'Admin User', 'Admin', '9999999999', 'admin@1', 'admin'),
(1, 'Delivery Agent 1', 'DeliveryAgent', '8888888888', 'agent1@courier.com', 'hashed_agent_pass1'),
(2, 'Delivery Agent 2', 'DeliveryAgent', '7777777777', 'agent2@courier.com', 'hashed_agent_pass2');

-- Packages (with varying statuses)
CALL sp_create_package(1, 1, 2.5, 'Standard', @trk1);
CALL sp_create_package(2, 1, 1.5, 'Express', @trk2);
CALL sp_create_package(3, 2, 3.0, 'Standard', @trk3);
CALL sp_create_package(4, 2, 2.0, 'Express', @trk4);
CALL sp_create_package(5, 3, 4.0, 'Standard', @trk5);
CALL sp_create_package(1, 3, 1.0, 'Express', @trk6);
CALL sp_create_package(2, 1, 2.2, 'Standard', @trk7);
CALL sp_create_package(3, 2, 3.5, 'Express', @trk8);

-- Update some package statuses to create history
CALL sp_update_status((SELECT tracking_id FROM Package WHERE package_id = 1), 'Bangalore Hub', 'Picked Up', 2);
CALL sp_update_status((SELECT tracking_id FROM Package WHERE package_id = 1), 'Delhi Hub', 'In Transit', 2);
CALL sp_update_status((SELECT tracking_id FROM Package WHERE package_id = 2), 'Bangalore Hub', 'Picked Up', 2);
CALL sp_update_status((SELECT tracking_id FROM Package WHERE package_id = 2), 'Chennai Hub', 'In Transit', 2);
CALL sp_update_status((SELECT tracking_id FROM Package WHERE package_id = 2), 'Chennai Local', 'Out for Delivery', 2);
CALL sp_confirm_delivery((SELECT tracking_id FROM Package WHERE package_id = 2), 'Jane Recipient', '9090909090', 2);


show tables;
