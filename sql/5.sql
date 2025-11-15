USE tender;

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
    DECLARE v_new_user_id INT;

    -- 1. Insert new user (Generates the next User_ID)
    INSERT INTO user (Login, Role, Permission, Password_Hash)
    VALUES (p_Login, p_Role, p_Permission, SHA2('password123', 256));
    
    -- Capture the User_ID just created
    SET v_new_user_id = LAST_INSERT_ID(); 
    
    IF p_Role = 'Vendor' THEN 
        -- 2. INSERT into vendor, using the captured User_ID as the Vendor_ID
        -- NOTE: We must temporarily disable auto-increment and override the Vendor_ID
        
        SET FOREIGN_KEY_CHECKS = 0; -- Allow PK overwrite
        
        INSERT INTO vendor (Vendor_ID, Company_Name, Credentials) 
        VALUES (v_new_user_id, p_CompanyName, p_Credentials); 
        
        SET FOREIGN_KEY_CHECKS = 1; -- Re-enable checks
        
        -- Optional: Reset vendor AUTO_INCREMENT to ensure future non-SP inserts continue correctly
        -- ALTER TABLE vendor AUTO_INCREMENT = (SELECT MAX(Vendor_ID) + 1 FROM vendor);
    END IF;
END //
DELIMITER ;