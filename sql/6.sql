-- Example SQL to create the SP_AwardContract (SP1)
-- **You may need to adjust the logic/names based on your exact schema**
DELIMITER $$

CREATE PROCEDURE SP_AwardContract(
    IN p_tender_id INT,
    IN p_vendor_id INT,
    IN p_value DECIMAL(10, 2),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_terms TEXT,
    IN p_awarded_by_uid INT
)
BEGIN
    -- 1. Insert the new contract record
    INSERT INTO contract (
        Tender_ID, 
        Vendor_ID, 
        Value, 
        Start_Date, 
        End_Date, 
        Terms, 
        Awarded_By_UID, 
        Status, 
        Signed_Date
    )
    VALUES (
        p_tender_id, 
        p_vendor_id, 
        p_value, 
        p_start_date, 
        p_end_date, 
        p_terms, 
        p_awarded_by_uid, 
        'Active', 
        CURDATE()
    );
    
    -- 2. Optionally, update the status of the corresponding tender (e.g., to 'Awarded')
    UPDATE tender
    SET Status = 'Awarded' 
    WHERE Tender_ID = p_tender_id;

    -- 3. Optionally, update the status of the winning bid (e.g., to 'Awarded')
    UPDATE bid
    SET Status = 'Awarded'
    WHERE Tender_ID = p_tender_id AND Vendor_ID = p_vendor_id;

END$$

DELIMITER ;