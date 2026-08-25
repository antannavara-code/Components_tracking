CREATE DATABASE IF NOT EXISTS qr_asset_tracking;
USE qr_asset_tracking;

CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    department VARCHAR(100),
    phone VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'manager', 'employee') DEFAULT 'employee',
    employee_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    building VARCHAR(200),
    room VARCHAR(100),
    description TEXT
);

CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status ENUM('active', 'completed', 'on_hold') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS drones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    drone_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    model VARCHAR(200),
    status ENUM('active', 'maintenance', 'grounded') DEFAULT 'active',
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asset_id VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    serial_number VARCHAR(200),
    model VARCHAR(200),
    status ENUM('available', 'assigned', 'in_drone', 'testing', 'maintenance', 'missing', 'damaged') DEFAULT 'available',
    condition_type ENUM('good', 'fair', 'poor') DEFAULT 'good',
    current_user_id INT,
    current_location_id INT,
    current_drone_id INT,
    project_id INT,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (current_user_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (current_location_id) REFERENCES locations(id) ON DELETE SET NULL,
    FOREIGN KEY (current_drone_id) REFERENCES drones(id) ON DELETE SET NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS asset_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asset_id INT NOT NULL,
    action ENUM('assigned', 'transferred', 'returned', 'installed_drone', 'removed_drone', 'reported_missing', 'reported_damaged', 'created') NOT NULL,
    from_user_id INT,
    to_user_id INT,
    from_location_id INT,
    to_location_id INT,
    from_drone_id INT,
    to_drone_id INT,
    from_status VARCHAR(50),
    to_status VARCHAR(50),
    purpose TEXT,
    remarks TEXT,
    performed_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    FOREIGN KEY (from_user_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (to_user_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (from_location_id) REFERENCES locations(id) ON DELETE SET NULL,
    FOREIGN KEY (to_location_id) REFERENCES locations(id) ON DELETE SET NULL,
    FOREIGN KEY (from_drone_id) REFERENCES drones(id) ON DELETE SET NULL,
    FOREIGN KEY (to_drone_id) REFERENCES drones(id) ON DELETE SET NULL,
    FOREIGN KEY (performed_by) REFERENCES employees(id) ON DELETE SET NULL
);
