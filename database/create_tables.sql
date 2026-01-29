-- Queue System Database Schema
-- MySQL v.8 Compatible

-- Create database
CREATE DATABASE IF NOT EXISTS queue_system 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE queue_system;

-- Table: queue_status
-- Stores the current status of each queue number
CREATE TABLE queue_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queue_number VARCHAR(4) NOT NULL UNIQUE,
    has_data BOOLEAN DEFAULT FALSE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_queue_number (queue_number)
);

-- Table: queue_history  
-- Stores history of queue calls and their status
CREATE TABLE queue_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queue_numbers JSON NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_by VARCHAR(50) DEFAULT 'CALLER',
    status ENUM('SENT', 'DISPLAYED', 'COMPLETED') DEFAULT 'SENT'
);

-- Table: connection_settings
-- Stores system configuration settings
CREATE TABLE connection_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_name VARCHAR(50) NOT NULL UNIQUE,
    setting_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert initial queue numbers (0001-0009)
INSERT INTO queue_status (queue_number, has_data) VALUES
('0001', FALSE),
('0002', FALSE),
('0003', FALSE),
('0004', FALSE),
('0005', FALSE),
('0006', FALSE),
('0007', FALSE),
('0008', FALSE),
('0009', FALSE);

-- Insert default connection settings
INSERT INTO connection_settings (setting_name, setting_value) VALUES
('websocket_server_port', '8080'),
('websocket_client_host', 'localhost'),
('websocket_client_port', '8080'),
('auto_reconnect', 'true'),
('reconnect_interval', '5000'),
('blink_interval', '500'),
('blink_duration', '3000'),
('font_size', '48'),
('grid_spacing', '10');