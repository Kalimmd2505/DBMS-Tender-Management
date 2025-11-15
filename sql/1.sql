-- *********************************************************************************
-- 1. SCHEMA CORRECTION (Database: tender)
-- *********************************************************************************

USE tender;

-- The ADD COLUMN and ADD CONSTRAINT lines are REMOVED because they caused Errors 1060 and 1826, 
-- meaning the columns/constraints are already in your schema.

-- Data Population (These update statements are necessary to link existing bids to tenders)
UPDATE bid SET Tender_ID = 1 WHERE Bid_ID IN (1, 2) AND Tender_ID IS NULL;
UPDATE bid SET Tender_ID = 2 WHERE Bid_ID IN (3, 4) AND Tender_ID IS NULL;
UPDATE bid SET Tender_ID = 3 WHERE Bid_ID = 5 AND Tender_ID IS NULL;
UPDATE bid SET Tender_ID = 4 WHERE Bid_ID = 6 AND Tender_ID IS NULL;
UPDATE bid SET Tender_ID = 5 WHERE Bid_ID = 7 AND Tender_ID IS NULL;
UPDATE bid SET Tender_ID = 6 WHERE Bid_ID = 8 AND Tender_ID IS NULL;

-- Final enforcement (Modify the column to NOT NULL if it was set to NULL previously)
ALTER TABLE bid MODIFY COLUMN Tender_ID INT NOT NULL; 


-- *********************************************************************************
-- 2. ALL 5 FUNCTIONS (FN1 to FN5)
-- *********************************************************************************

USE tender;

DROP FUNCTION IF EXISTS FN_GetAverageTenderScore;
DELIMITER //
CREATE FUNCTION FN_GetAverageTenderScore(p_Tender_ID INT) RETURNS DECIMAL(5, 2) READS SQL DATA
BEGIN DECLARE v_AvgScore DECIMAL(5, 2); SELECT AVG(Score) INTO v_AvgScore FROM evaluation WHERE Tender_ID = p_Tender_ID; RETURN IFNULL(v_AvgScore, 0.00); END //
DELIMITER ;

DROP FUNCTION IF EXISTS FN_GetLowestBidPrice;
DELIMITER //
CREATE FUNCTION FN_GetLowestBidPrice(p_Tender_ID INT) RETURNS DECIMAL(15, 2) READS SQL DATA
BEGIN DECLARE v_LowestPrice DECIMAL(15, 2); SELECT MIN(Price) INTO v_LowestPrice FROM bid WHERE Tender_ID = p_Tender_ID AND Status IN ('Submitted', 'Under Review'); RETURN IFNULL(v_LowestPrice, 0.00); END //
DELIMITER ;

DROP FUNCTION IF EXISTS FN_CountSubmittedBids;
DELIMITER //
CREATE FUNCTION FN_CountSubmittedBids(p_Tender_ID INT) RETURNS INT READS SQL DATA
BEGIN DECLARE v_BidCount INT; SELECT COUNT(Bid_ID) INTO v_BidCount FROM bid WHERE Tender_ID = p_Tender_ID; RETURN v_BidCount; END //
DELIMITER ;

DROP FUNCTION IF EXISTS FN_CheckIfVendorHasActiveContract;
DELIMITER //
CREATE FUNCTION FN_CheckIfVendorHasActiveContract(p_Vendor_ID INT) RETURNS INT READS SQL DATA
BEGIN DECLARE v_ActiveCount INT; SELECT COUNT(Contract_ID) INTO v_ActiveCount FROM contract WHERE Vendor_ID = p_Vendor_ID AND Status = 'Active'; RETURN IF(v_ActiveCount > 0, 1, 0); END //
DELIMITER ;

DROP FUNCTION IF EXISTS FN_IsTenderDeadlinePassed;
DELIMITER //
CREATE FUNCTION FN_IsTenderDeadlinePassed(p_Tender_ID INT) RETURNS INT READS SQL DATA
BEGIN DECLARE v_DeadlinePassed INT; DECLARE v_Deadline DATE; SELECT Deadline INTO v_Deadline FROM tender WHERE Tender_ID = p_Tender_ID; IF v_Deadline < CURDATE() THEN SET v_DeadlinePassed = 1; ELSE SET v_DeadlinePassed = 0; END IF; RETURN v_DeadlinePassed; END //
DELIMITER ;


-- *********************************************************************************
-- 3. ALL 3 TRIGGERS (T1 to T3)
-- *********************************************************************************

USE tender;

DROP TRIGGER IF EXISTS TR_UpdateBidStatusOnContractCreation;
DELIMITER //
CREATE TRIGGER TR_UpdateBidStatusOnContractCreation
AFTER INSERT ON contract FOR EACH ROW
BEGIN UPDATE bid SET Status = 'Accepted' WHERE Tender_ID = NEW.Tender_ID AND Vendor_ID = NEW.Vendor_ID AND Price = NEW.Value AND Status != 'Accepted'; END //
DELIMITER ;

DROP TRIGGER IF EXISTS TR_CheckBidPricePositive;
DELIMITER //
CREATE TRIGGER TR_CheckBidPricePositive
BEFORE INSERT ON bid FOR EACH ROW
BEGIN IF NEW.Price <= 0.00 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A bid price must be a positive value greater than zero.'; END IF; END //
DELIMITER ;

DROP TRIGGER IF EXISTS TR_PreventLateBids;
DELIMITER //
CREATE TRIGGER TR_PreventLateBids
BEFORE INSERT ON bid FOR EACH ROW
BEGIN IF FN_IsTenderDeadlinePassed(NEW.Tender_ID) = 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot submit bid. The deadline for this tender has already passed.'; END IF; END //
DELIMITER ;


-- *********************************************************************************
-- 4. ALL 5 STORED PROCEDURES (SP1 to SP5)
-- *********************************************************************************

USE tender;

-- SP1: Award Tender And Create Contract (Complex Transaction)
DROP PROCEDURE IF EXISTS SP_AwardTenderAndCreateContract;
DELIMITER //
CREATE PROCEDURE SP_AwardTenderAndCreateContract(
    IN p_Tender_ID INT, IN p_Vendor_ID INT, IN p_Terms TEXT, IN p_Value DECIMAL(15, 2), IN p_Start_Date DATE, IN p_End_Date DATE, IN p_Signed_Date DATE)
BEGIN 
    INSERT INTO contract (Tender_ID, Vendor_ID, Terms, Value, Start_Date, End_Date, Signed_Date, Status) VALUES (p_Tender_ID, p_Vendor_ID, p_Terms, p_Value, p_Start_Date, p_End_Date, p_Signed_Date, 'Active');
    UPDATE bid SET Status = 'Accepted' WHERE Tender_ID = p_Tender_ID AND Vendor_ID = p_Vendor_ID AND Price = p_Value AND Status != 'Accepted';
    UPDATE bid SET Status = 'Rejected' WHERE Tender_ID = p_Tender_ID AND Vendor_ID != p_Vendor_ID AND Status IN ('Submitted', 'Under Review');
END //
DELIMITER ;

-- SP2: Create New User And Vendor
DROP PROCEDURE IF EXISTS SP_CreateNewUserAndVendor;
DELIMITER //
CREATE PROCEDURE SP_CreateNewUserAndVendor(
    IN p_Login VARCHAR(100), IN p_Role ENUM('Admin','Vendor','Manager','Evaluator'), IN p_Permission VARCHAR(255), IN p_CompanyName VARCHAR(200), IN p_Credentials TEXT)
BEGIN 
    INSERT INTO user (Login, Role, Permission) VALUES (p_Login, p_Role, p_Permission);
    IF p_Role = 'Vendor' THEN INSERT INTO vendor (Company_Name, Credentials) VALUES (p_CompanyName, p_Credentials); END IF;
END //
DELIMITER ;

-- SP3: Retrieve Tender Details With Bids (Join Query)
DROP PROCEDURE IF EXISTS SP_RetrieveTenderDetailsWithBids;
DELIMITER //
CREATE PROCEDURE SP_RetrieveTenderDetailsWithBids(IN p_Tender_ID INT)
BEGIN 
    SELECT t.Title, v.Company_Name, b.Price, b.Status, b.Documents
    FROM tender t
    JOIN bid b ON t.Tender_ID = b.Tender_ID
    JOIN vendor v ON b.Vendor_ID = v.Vendor_ID
    WHERE t.Tender_ID = p_Tender_ID ORDER BY b.Price ASC;
END //
DELIMITER ;

-- SP4: Submit Evaluation Score (CRUD Operation)
DROP PROCEDURE IF EXISTS SP_SubmitEvaluationScore;
DELIMITER //
CREATE PROCEDURE SP_SubmitEvaluationScore(
    IN p_Tender_ID INT, IN p_User_ID INT, IN p_Vendor_ID INT, IN p_Score DECIMAL(5, 2), IN p_Comments TEXT)
BEGIN 
    INSERT INTO evaluation (Tender_ID, User_ID, vid, Score, Comments)
    VALUES (p_Tender_ID, p_User_ID, p_Vendor_ID, p_Score, p_Comments);
END //
DELIMITER ;

-- SP5: Get Open Tenders (Nested Query)
DROP PROCEDURE IF EXISTS SP_GetOpenTenders;
DELIMITER //
CREATE PROCEDURE SP_GetOpenTenders()
BEGIN 
    SELECT Tender_ID, Title, Deadline
    FROM tender
    WHERE Tender_ID NOT IN (SELECT Tender_ID FROM contract)
    AND FN_IsTenderDeadlinePassed(Tender_ID) = 0
    ORDER BY Deadline ASC;
END //
DELIMITER ;