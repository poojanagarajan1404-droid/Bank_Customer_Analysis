--  Project Title: bank customer transaction analysis
 -- PROJECT COMPLETE: covers all  SQL concepts for a real-world banking dataset
-- USE, CREATE TABLE, INSERT, SELECT, WHERE, DISTINCT, UNION, GROUP BY, ORDER BY, HAVING, AGGREGATE FUNCTIONS, 
-- DATE_FORMAT, CASE, LIMIT, JOIN, VIEW, TRIGGER, PROCEDURE, FUNCTION, INDEX

use bank_customers;
select * from bank_customer_transaction;
select *from  foreign_cutomer;
select * from fraud dataset;
-- 1. Total Unique Customers , Location-wise customer count (Domestic and Foreign)
SELECT COUNT(DISTINCT CustomerID) AS Total_Unique_Customers
FROM (
    Select  CustomerID from foreign_customer
    UNION
    Select  CustomerID from bank_customer_transaction
    union
    SELECT CustomerID FROM `customer aggregation`
    UNION
    SELECT CustomerID FROM `fraud dataset`
    UNION
    SELECT CustomerID FROM rfm
) AS All_Customers;
SHOW TABLES from bank_customers;
SELECT CustLocation, COUNT(DISTINCT CustomerID) AS customer_count
FROM (
    SELECT CustomerID, CustLocation
    FROM bank_customer_transaction
    UNION ALL
    SELECT CustomerID, CustLocation
    FROM foreign_customer
) AS combined_customers
GROUP BY CustLocation
ORDER BY customer_count DESC;
-- 2. Monthly transaction trends?
SHOW TABLES;
DESCRIBE bank_customer_transaction;
SELECT 
    DATE_FORMAT(STR_TO_DATE(TransactionDate, '%d-%m-%Y'), '%Y-%m') AS month,
    COUNT(TransactionID) AS total_transactions,
    SUM(`TransactionAmount(INR)`) AS total_sales,
    AVG(CustAccountBalance) AS avg_account_balance
FROM bank_customer_transaction
Where  TransactionDate IS NOT NULL
Group by month
Order  by month;
-- 3.---- Show customer counts per RFM segment with Active vs Inactive customer  ----

Select segment,
count(*) as customercount
From rfm
group by segment 
order by customercount desc;

-- 4. Top 10 Customers (Domestic & Foreign)?
show tables;
Describe  bank_customer_transaction;
Describe foreign_customer;

Show Columns From bank_customer_transaction;
Show Columns FROM foreign_customer;
select 
  CustomerID, CustGender, CustLocation, SUM(total_spent) AS total_spent
From (
  select CustomerID, CustGender, CustLocation,
         SUM(CAST(`TransactionAmount(INR)`as double )) as total_spent
  From bank_customer_transaction
  Where  DATE_FORMAT(STR_TO_DATE(TransactionDate, '%d-%m-%Y'), '%Y-%m') 
        in ('2016-08','2016-09','2016-10')
  Group by  CustomerID, CustGender, CustLocation

  Union all 

  Select  CustomerID, CustGender, CustLocation,
         SUM(`TransactionAmountINR`) AS total_spent 
  From foreign_customer
  Where  DATE_FORMAT(STR_TO_DATE(TransactionDate, '%d-%m-%Y'), '%Y-%m') 
        in  ('2016-08','2016-09','2016-10')
  Group by  CustomerID, CustGender, CustLocation
) as  combined_spending
group by  CustomerID, CustGender, CustLocation
order by   total_spent desc
Limit  10;

-- 5.Male vs Female Ratio (Overall)
Select custgender , COUNT(customerid) as count
From bank_customer_transaction
Group by  custgender;
SELECT 
    SUM(CASE WHEN custgender = 'Male' THEN 1 ELSE 0 END) / 
    SUM(CASE WHEN custgender = 'Female' THEN 1 ELSE 0 END) AS male_female_ratio
FROM bank_customer_transaction;
-- 6. Identify customers with high RFM scores and flag potential fraud risks?
Select 
    CustomerID,
    R, F, M, 
    RFM_Score,
    Segment_Final,
    Case
        When R >= 4 And F >= 4 AND M >= 4 then '🚩 High Fraud Risk'
        When F >= 4 And  M >= 4 then '⚠️ Medium Risk'
        Else '🟢 Normal'
    End as Fraud_Flag
From RFM
Order by RFM_Score Desc;

-- 7.Trigger with Dummy Table — Add New Customer Transaction 
-- Create Dummy Table
Create table transaction_import (
    ImportID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    CustomerDOB DATE,
    CustGender VARCHAR(10),
    CustLocation VARCHAR(100),
    CustAccountBalance DECIMAL(12,2),
    TransactionDate DATE,
    `TransactionAmount(INR)` DECIMAL(12,2)
);

-- Create Trigger on dummy Table
DELIMITER $$

Create Trigger trg_after_insert_transaction_import
After Insert on transaction_import
For  each row 
Begin 
    Insert Into bank_customer_transaction
    (CustomerID, CustGender, CustLocation, CustAccountBalance, TransactionDate, `TransactionAmount(INR)`)
    Values
    (NEW.CustomerID, NEW.CustGender, NEW.CustLocation, NEW.CustAccountBalance, NEW.TransactionDate, NEW.`TransactionAmount(INR)`);
END$$

DELIMITER ;

--  Insert a record into dummy Table (Trigger fires automatically)
Insert Into  transaction_import
(CustomerID, CustomerDOB, CustGender, CustLocation, CustAccountBalance, TransactionDate, `TransactionAmount(INR)`)
Values 
(1011203, '1990-05-15', 'Male', 'Bangalore', 50000.00, '2025-10-07', 1500.00);

-- Check Dummy Table (Trigger output)
Select * From transaction_import;
Select * From bank_customer_transaction
Where CustomerID = 1011203;


-- PROJECT COMPLETE: covers all  SQL concepts for a real-world banking dataset
-- USE, CREATE TABLE, INSERT, SELECT, WHERE, DISTINCT, UNION, GROUP BY, ORDER BY, HAVING, AGGREGATE FUNCTIONS, 
-- DATE_FORMAT, CASE, LIMIT, JOIN, VIEW, TRIGGER, PROCEDURE, FUNCTION, INDEX