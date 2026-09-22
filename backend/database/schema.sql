CREATE DATABASE IF NOT EXISTS fadelab_barbershop;
USE fadelab_barbershop;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  role ENUM('admin', 'barber', 'customer') NOT NULL,
  active_status BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_email (email),
  INDEX idx_role (role),
  INDEX idx_active_status (active_status)
);

-- ============================================
-- SERVICES TABLE
-- ============================================
CREATE TABLE services (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  duration_minutes INT NOT NULL,
  active_status BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CHECK (price >= 0),
  CHECK (duration_minutes > 0),
  
  INDEX idx_name (name),
  INDEX idx_active_status (active_status)
);

-- ============================================
-- BARBERS TABLE
-- ============================================
CREATE TABLE barbers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNIQUE NOT NULL,
  active_status BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_active_status (active_status)
);

-- ============================================
-- CUSTOMERS TABLE
-- ============================================
CREATE TABLE customers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNIQUE NOT NULL,
  preferred_barber_id INT NULL,
  preferred_service_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (preferred_barber_id) REFERENCES barbers(id) ON DELETE SET NULL,
  FOREIGN KEY (preferred_service_id) REFERENCES services(id) ON DELETE SET NULL,
  
  INDEX idx_user_id (user_id)
);

-- ============================================
-- BARBER_SCHEDULES TABLE
-- ============================================
CREATE TABLE barber_schedules (
  id INT PRIMARY KEY AUTO_INCREMENT,
  barber_id INT NOT NULL,
  day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
  is_working BOOLEAN NOT NULL DEFAULT TRUE,
  start_time TIME NULL,
  end_time TIME NULL,
  break_start_time TIME NULL,
  break_end_time TIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (barber_id) REFERENCES barbers(id) ON DELETE CASCADE,
  UNIQUE KEY unique_barber_day (barber_id, day_of_week),
  
  CONSTRAINT chk_working_hours CHECK (
    is_working = FALSE
    OR (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time)
  ),
  
  CONSTRAINT chk_break_times CHECK (
    (break_start_time IS NULL AND break_end_time IS NULL)
    OR (break_start_time IS NOT NULL AND break_end_time IS NOT NULL AND break_start_time < break_end_time)
  ),
  
  INDEX idx_barber_id (barber_id),
  INDEX idx_day_of_week (day_of_week)
);

-- ============================================
-- BARBER_SCHEDULE_EXCEPTIONS TABLE
-- ============================================
CREATE TABLE barber_schedule_exceptions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  barber_id INT NOT NULL,
  exception_date DATE NOT NULL,
  exception_type ENUM('unavailable', 'available_override') NOT NULL,
  start_time TIME NULL,
  end_time TIME NULL,
  reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (barber_id) REFERENCES barbers(id) ON DELETE CASCADE,
  UNIQUE KEY unique_barber_exception_date (barber_id, exception_date),
  
  INDEX idx_barber_id (barber_id),
  INDEX idx_exception_date (exception_date)
);

-- ============================================
-- SHOP_SETTINGS TABLE
-- ============================================
CREATE TABLE shop_settings (
  id INT PRIMARY KEY AUTO_INCREMENT,
  setting_key VARCHAR(100) UNIQUE NOT NULL,
  setting_value VARCHAR(255) NOT NULL,
  description TEXT,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_setting_key (setting_key)
);

-- ============================================
-- CLOSED_DATES TABLE
-- ============================================
CREATE TABLE closed_dates (
  id INT PRIMARY KEY AUTO_INCREMENT,
  closed_date DATE NOT NULL UNIQUE,
  reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_closed_date (closed_date)
);

-- ============================================
-- APPOINTMENTS TABLE
-- ============================================
CREATE TABLE appointments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  barber_id INT NOT NULL,
  service_id INT NOT NULL,
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  duration_minutes INT NOT NULL,
  status ENUM('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show') DEFAULT 'pending',
  
  confirmed_at TIMESTAMP NULL,
  confirmed_by_id INT NULL,
  
  completed_at TIMESTAMP NULL,
  
  cancelled_at TIMESTAMP NULL,
  cancelled_by ENUM('customer', 'barber', 'admin') NULL,
  cancelled_by_id INT NULL,
  cancellation_reason VARCHAR(255) NULL,
  
  no_show_at TIMESTAMP NULL,
  no_show_reason VARCHAR(255) NULL,
  
  rescheduled_from_id INT NULL,
  rescheduled_at TIMESTAMP NULL,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  FOREIGN KEY (barber_id) REFERENCES barbers(id) ON DELETE RESTRICT,
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
  FOREIGN KEY (confirmed_by_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (cancelled_by_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (rescheduled_from_id) REFERENCES appointments(id) ON DELETE SET NULL,
  
  CONSTRAINT chk_duration CHECK (duration_minutes > 0),
  UNIQUE KEY unique_barber_appointment_start (barber_id, appointment_date, appointment_time),
  
  INDEX idx_customer_id (customer_id),
  INDEX idx_barber_id (barber_id),
  INDEX idx_service_id (service_id),
  INDEX idx_appointment_date (appointment_date),
  INDEX idx_status (status),
  INDEX idx_customer_date (customer_id, appointment_date),
  INDEX idx_barber_date (barber_id, appointment_date),
  INDEX idx_confirmed_at (confirmed_at)
);

-- ============================================
-- TRANSACTIONS TABLE
-- ============================================
CREATE TABLE transactions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  appointment_id INT UNIQUE NOT NULL,
  customer_id INT NOT NULL,
  barber_id INT NOT NULL,
  service_id INT NOT NULL,
  service_amount DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  discount_reason VARCHAR(255) NULL,
  tip_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_method ENUM('cash', 'gcash', 'card') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE RESTRICT,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  FOREIGN KEY (barber_id) REFERENCES barbers(id) ON DELETE RESTRICT,
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
  
  CHECK (service_amount >= 0),
  CHECK (discount_amount >= 0),
  CHECK (tip_amount >= 0),
  CHECK (total_amount >= 0),
  
  INDEX idx_customer_id (customer_id),
  INDEX idx_barber_id (barber_id),
  INDEX idx_service_id (service_id),
  INDEX idx_created_at (created_at),
  INDEX idx_payment_method (payment_method)
);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  notification_type ENUM(
    'booking_confirmation',
    'appointment_confirmed',
    'appointment_cancelled',
    'appointment_rescheduled',
    'appointment_reminder',
    'appointment_completed',
    'new_booking_for_staff'
  ) NOT NULL,
  appointment_id INT NULL,
  recipient_email VARCHAR(255) NOT NULL,
  status ENUM('sent', 'failed', 'pending') DEFAULT 'sent',
  sent_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
  
  INDEX idx_user_id (user_id),
  INDEX idx_notification_type (notification_type),
  INDEX idx_appointment_id (appointment_id),
  INDEX idx_sent_at (sent_at),
  INDEX idx_created_at (created_at)
);