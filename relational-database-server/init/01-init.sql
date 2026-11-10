CREATE DATABASE IF NOT EXISTS minicloud;
USE minicloud;
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO notes (title) VALUES ('Hello from MariaDB!');

CREATE DATABASE IF NOT EXISTS studentdb;
USE studentdb;
CREATE TABLE IF NOT EXISTS students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id VARCHAR(10),
    fullname VARCHAR(100),
    dob DATE,
    major VARCHAR(50)
);
INSERT INTO students (student_id, fullname, dob, major) VALUES
('SV001', 'Nguyen Van A', '2004-01-12', 'Software Engineering'),
('SV002', 'Tran Thi B', '2004-08-21', 'Computer Science'),
('SV003', 'Le Van C', '2003-11-03', 'Information Systems'),
('SV004', 'Pham Thi D', '2004-04-15', 'Data Science'),
('SV005', 'Hoang Van E', '2003-12-08', 'Cyber Security');

GRANT ALL PRIVILEGES ON studentdb.* TO 'minicloud_user'@'%';
FLUSH PRIVILEGES;
