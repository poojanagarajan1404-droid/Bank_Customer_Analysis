-- store procedure
USE bank_customers;
DELIMITER $$

CREATE PROCEDURE bank_analysis()
BEGIN
    -- 1.Total Unique Customers (Domestic + Foreign)
    SELECT COUNT(DISTINCT CustomerID) AS Total_Unique_Customers
    FROM (
        SELECT CustomerID FROM foreign_customer
        UNION
        SELECT CustomerID FROM bank_customer_transaction
        UNION
        SELECT CustomerID FROM `customer aggregation`
        UNION
        SELECT CustomerID FROM `fraud dataset`
        UNION
        SELECT CustomerID FROM rfm
    ) AS All_Customers;

    -- 1️  Location-wise Customer Count
    SELECT CustLocation, COUNT(DISTINCT CustomerID) AS customer_count
    FROM (
        SELECT CustomerID, CustLocation FROM bank_customer_transaction
        UNION ALL
        SELECT CustomerID, CustLocation FROM foreign_customer
    ) AS combined_customers
    GROUP BY CustLocation
    ORDER BY customer_count DESC;

    -- 2️ Monthly Transaction Trends
    SELECT 
        DATE_FORMAT(STR_TO_DATE(TransactionDate, '%d-%m-%Y'), '%Y-%m') AS Month,
        COUNT(TransactionID) AS Total_Transactions,
        SUM(`TransactionAmount(INR)`) AS Total_Sales,
        AVG(CustAccountBalance) AS Avg_Account_Balance
    FROM bank_customer_transaction
    WHERE TransactionDate IS NOT NULL
    GROUP BY Month
    ORDER BY Month;

    -- 3️ Customer Count per RFM Segment
    SELECT Segment, COUNT(*) AS CustomerCount
    FROM RFM
    GROUP BY Segment
    ORDER BY CustomerCount DESC;

    -- 4️ Top 10 Customers (Domestic + Foreign)
    SELECT 
      CustomerID, CustGender, CustLocation, SUM(total_spent) AS total_spent
    FROM (
      SELECT CustomerID, CustGender, CustLocation,
             SUM(CAST(`TransactionAmount(INR)`AS DOUBLE)) AS total_spent
      FROM bank_customer_transaction
      GROUP BY CustomerID, CustGender, CustLocation

      UNION ALL

      SELECT CustomerID, CustGender, CustLocation,
             SUM(`TransactionAmountINR`) AS total_spent
      FROM foreign_customer
      GROUP BY CustomerID, CustGender, CustLocation
    ) AS combined_spending
    GROUP BY CustomerID, CustGender, CustLocation
    ORDER BY total_spent DESC
    LIMIT 10;

    -- 5.Male vs Female Ratio (Overall)
    SELECT custgender, COUNT(customerid) AS count
    FROM bank_customer_transaction
    GROUP BY custgender;

    SELECT 
        SUM(CASE WHEN custgender = 'Male' THEN 1 ELSE 0 END) /
        SUM(CASE WHEN custgender = 'Female' THEN 1 ELSE 0 END) AS male_female_ratio
    FROM bank_customer_transaction;

    -- 6️ .Detect Potential Fraud Risks using RFM
    SELECT 
        CustomerID,
        R, F, M, 
        RFM_Score,
        Segment_Final,
        CASE 
            WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'High Fraud Risk'
            WHEN F >= 4 AND M >= 4 THEN ' Medium Risk'
            ELSE 'Normal'
        END AS Fraud_Flag
    FROM RFM
    ORDER BY RFM_Score DESC;

    -- 7️. Demonstrate Trigger with Dummy Table
    INSERT INTO transaction_import
    (CustomerID, CustomerDOB, CustGender, CustLocation, CustAccountBalance, TransactionDate, `TransactionAmount(INR)`)
    VALUES
    (1011203, '1990-05-15', 'Male', 'Bangalore', 50000.00, '2025-10-07', 1500.00);

    SELECT * FROM transaction_import;
    SELECT * FROM bank_customer_transaction WHERE CustomerID = 1011203;

END$$

DELIMITER ;
CALL bank_analysis();
drop procedure if exists bank_analysis;
