USE tender;

-- The column already exists, so we skip the ADD COLUMN command.

-- 1. Update existing users with SHA2 hash of 'password123'
-- This sets the login password for all existing users (e.g., manager1@pesu.edu).
-- Uses WHERE User_ID > 0 to satisfy Safe Update Mode (Error 1175).
UPDATE user 
SET Password_Hash = SHA2('password123', 256) 
WHERE User_ID > 0;

-- 2. Modify the SP2 procedure to automatically add the password hash for NEW users
-- This ensures any new user created via the Manager dashboard can log in.
DROP PROCEDURE IF EXISTS SP_CreateNewUserAndVendor;
DELIMITER //
CREATE PROCEDURE SP_CreateNewUserAndVendor(
    IN p_Login VARCHAR(100), 
    IN p_Role ENUM('Admin','Vendor','Manager','Evaluator'), 
    IN p_Permission VARCHAR(255), 
    IN p_CompanyName VARCHAR(200), 
    IN p_Credentials TEXT
)
BEGIN 
    -- Insert new user with default password hash ('password123')
    INSERT INTO user (Login, Role, Permission, Password_Hash)
    VALUES (p_Login, p_Role, p_Permission, SHA2('password123', 256));
    
    IF p_Role = 'Vendor' THEN 
        INSERT INTO vendor (Company_Name, Credentials) 
        VALUES (p_CompanyName, p_Credentials); 
    END IF;
END //
DELIMITER ;

-- Verification Check
SELECT 'Password Hash Setup Status' AS Status;
SELECT User_ID, Login, Password_Hash 
FROM user 
WHERE Login = 'manager1@pesu.edu';