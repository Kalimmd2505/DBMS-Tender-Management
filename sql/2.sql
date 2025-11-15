-- *************************************************************************
-- ** 1. TRANSACTION TEST (SP1, T1) - Must use explicit schema name 'tender' **
-- *************************************************************************
USE tender;
SELECT '--- SP1/T1 Verification ---' AS Status_Check;

-- Reset Bid 7 status 
UPDATE bid SET Status = 'Submitted' WHERE Bid_ID = 7; 

-- Call SP1 explicitly using the CORRECT schema name: 'tender'
CALL tender.SP_AwardTenderAndCreateContract(5, 6, 'Final Terms', 750000.00, '2025-12-01', '2026-12-01', '2025-11-05');

-- Verification
SELECT 'Bid Status (Bid 7) updated by T1:' AS Result;
SELECT Bid_ID, Status FROM bid WHERE Bid_ID = 7; -- Should be 'Accepted'

-- *************************************************************************
-- ** 2. FAILURE TESTS (T2 & T3) **
-- *************************************************************************
SELECT '--- TRIGGER FAILURE TESTS (Expected to Error) ---' AS Status_Check;

-- T2 Test (Price Constraint): MUST FAIL
INSERT INTO bid (Tender_ID, Vendor_ID, Price, Status, Documents)
VALUES (1, 6, 0.00, 'Submitted', 'bad_price.pdf'); 

-- T3 Test (Late Bid Constraint): MUST FAIL (Tender 3 deadline is old)
INSERT INTO bid (Tender_ID, Vendor_ID, Price, Status, Documents)
VALUES (3, 6, 1500000.00, 'Submitted', 'late_bid.pdf');