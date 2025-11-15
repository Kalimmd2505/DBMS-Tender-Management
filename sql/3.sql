USE tender;
SELECT '--- FUNCTIONS AND QUERIES TEST ---' AS Status_Check;

-- FN1 Test (Aggregate) and FN3 Test (Count)
SELECT 
    -- FN1: Get average score for Tender 6 (Should return approx. 91.75)
    tender.FN_GetAverageTenderScore(6) AS Avg_Score, 
    -- FN3: Count bids for Tender 1 (Should return 2)
    tender.FN_CountSubmittedBids(1) AS Bid_Count;

-- FN2 Test (Lowest Bid)
SELECT 
    -- FN2: Get lowest bid for Tender 2 (Should return 2450000.00)
    tender.FN_GetLowestBidPrice(2) AS Lowest_Price; 

-- FN4 Test (Active Contract) and FN5 Test (Deadline Check)
SELECT 
    -- FN4: Check Vendor 1 (Has an active contract, should return 1)
    tender.FN_CheckIfVendorHasActiveContract(1) AS Has_Active_Contract, 
    -- FN5: Check Tender 3 (Deadline passed, should return 1)
    tender.FN_IsTenderDeadlinePassed(3) AS Deadline_Passed;