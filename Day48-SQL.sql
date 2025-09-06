Create table Customers (
						CustomerID Int Primary key,
						Name Varchar(50) Not Null Check(Len(Name)>=2),
						Country Varchar(30) Not Null Check(Len(Country)>=2),
						JoinDate Date Not Null Default Getdate() Check(JoinDate<=Getdate()),
						Segment Varchar(50) Not Null Check(Segment in ('Retail','Corporate','Small Business'))
						);

Create table Accounts (
						AccountID Int Primary key,
						CustomerID Int Not null,
						AccountType Varchar(30) Not Null Check(AccountType in ('Savings','Checking')),
						OpenDate Date Not Null Default GetDate() Check(OpenDate<=Getdate()),
						Balance Decimal(10,2) Not Null Check(Balance>=0),
						Status Varchar(25) Not Null Check(Status in ('Active','Closed')),
						Foreign Key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
						);

Create Table Transactions (
							TxnID Int Primary Key,
							AccountID Int Not null,
							TxnDate date Not Null Default GetDate() Check (TxnDate<=Getdate()),
							Amount Decimal(10,2) Not Null Check(Amount>=0),
							TxnType Varchar(30) Not Null Check(TxnType in ('Debit','Credit')),
							Channel Varchar(30) Not Null Check (Channel in ('Online','Branch','ATM')),
							Status Varchar(50) Not Null Check(Status in ('Success','Failed')),
							Foreign Key (AccountID) references Accounts(AccountID) on update cascade on delete no action
							);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Customers_Segment on Customers(Segment);
Create Index Idx_Accounts_Balance on Accounts(Balance);
Create Index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create Index Idx_Transactions_Amount on Transactions(Amount);
Create Index Idx_Transactions_TxnType on Transactions(TxnType);
Create Index Idx_Transactions_Channel on Transactions(Channel);
Create Index Idx_Transactions_Status on Transactions(Status);
Create Index Idx_Transactions_AccountID on Transactions(AccountID);

INSERT INTO Customers (CustomerID, Name, Country, JoinDate, Segment) VALUES
(1, 'Alice', 'USA', '2020-01-01', 'Retail'),
(2, 'Bob', 'India', '2021-03-15', 'Corporate'),
(3, 'Charlie', 'UK', '2021-05-20', 'Small Business'),
(4, 'David', 'Canada', '2022-01-12', 'Retail'),
(5, 'Emma', 'India', '2022-06-25', 'Retail');

INSERT INTO Accounts (AccountID, CustomerID, AccountType, OpenDate, Balance, Status) VALUES
(101, 1, 'Savings', '2020-01-01', 5000.00, 'Active'),
(102, 2, 'Checking', '2021-03-15', 8000.00, 'Active'),
(103, 3, 'Savings', '2021-05-20', 2000.00, 'Active'),
(104, 4, 'Checking', '2022-01-12', 10000.00, 'Closed'),
(105, 5, 'Savings', '2022-06-25', 3000.00, 'Active');

INSERT INTO Transactions (TxnID, AccountID, TxnDate, Amount, TxnType, Channel, Status) VALUES
(1, 101, '2023-01-01', 1000, 'Debit', 'Online', 'Success'),
(2, 101, '2023-01-05', 2000, 'Credit', 'Branch', 'Success'),
(3, 102, '2023-01-06', 5000, 'Debit', 'Online', 'Success'),
(4, 103, '2023-02-01', 1000, 'Debit', 'ATM', 'Failed'),
(5, 104, '2023-02-05', 3000, 'Debit', 'Online', 'Success'),
(6, 105, '2023-03-01', 2000, 'Credit', 'Branch', 'Success'),
(7, 101, '2023-03-10', 1500, 'Debit', 'Online', 'Success'),
(8, 102, '2023-03-15', 4000, 'Debit', 'Online', 'Failed'),
(9, 105, '2023-04-01', 2500, 'Debit', 'ATM', 'Success'),
(10, 103, '2023-04-05', 1200, 'Credit', 'Online', 'Success');

Select * from Customers 
Select*from Accounts 
Select* from Transactions 

--1) Customer Balances
--Show each customer’s total credits, debits, and final balance (consider only Success transactions).
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,c.Segment,
	SUM(CASE WHEN t.TxnType='Debit' AND t.Status='Success' THEN t.Amount ELSE 0 END) as TotalCredits,
	SUM(CASE WHEN t.TxnType='Credit' AND t.Status='Success' Then t.Amount ELSE 0 END) as TotalDebits,
(SUM(CASE WHEN t.TxnType = 'Credit' AND t.Status = 'Success' THEN t.Amount ELSE 0 END) - 
SUM(CASE WHEN t.TxnType = 'Debit' AND t.Status = 'Success' THEN t.Amount ELSE 0 END)) AS FinalBalance
from Customers c
join Accounts  a on c.CustomerID =a.CustomerID 
join Transactions t on t.AccountID =a.AccountID 
where t.Status ='Success'
group by c.CustomerID,c.Name,c.Country,c.Segment 
order by c.CustomerID;

--2) High Transaction Customers
--Find customers who made transactions worth more than ₹5000 in a single month.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	YEAR(t.TxnDate) as TransactionYear,
	MONTH(t.TxnDate) as TransactionMonth,
	SUM(t.Amount) as TotalMonthlyAmount
from Customers c
join Accounts a on c.CustomerID =a.CustomerID 
join Transactions t on a.AccountID =t.AccountID 
group by c.CustomerID,c.Name,c.Country,YEAR(t.TxnDate),MONTH(t.TxnDate)
having SUM(t.Amount)>5000
order by c.CustomerID,TransactionYear,TransactionMonth;

--3) Channel Performance
--For each channel (Online, ATM, Branch), calculate success vs failed transaction percentages.
Select
	Channel,
	COUNT(TxnID) as 'Total Transaction',
	SUM(CASE WHEN Status='Success' THEN 1 ELSE 0 END) as 'Successful Transactions',
	SUM(CASE WHEN Status='Failed' THEN 1 ELSE 0 END) as 'Failed Transactions',
	ROUND((SUM(CASE WHEN Status = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(TxnID)), 2) AS 'Success Percentage',
    ROUND((SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(TxnID)), 2) AS 'Failure Percentage'
FROM Transactions
GROUP BY Channel
ORDER BY Channel;

--4) Top Spenders
--List the top 3 accounts by total debit amount.
Select Top 3
	c.CustomerID,c.Name as 'Customer Name',c.Country,c.Segment,
	SUM(t.Amount) as [Total Debit Amount]
from Customers c
join Accounts a on c.CustomerID =a.CustomerID 
join Transactions t on a.AccountID =t.AccountID 
where t.TxnType ='Debit'
group by c.CustomerID,c.Name,c.Country,c.Segment 
order by [Total Debit Amount] Desc;

--5) Fraud Detection – Multiple Failed Transactions
--Find accounts that had more than 1 failed transaction in the same month.
SELECT
    a.AccountID,c.CustomerID,
    c.Name AS 'Customer Name',
    YEAR(t.TxnDate) AS 'Year',
    MONTH(t.TxnDate) AS 'Month',
    COUNT(t.TxnID) AS 'Failed Transactions Count'
FROM Accounts a
JOIN Transactions t ON a.AccountID = t.AccountID
JOIN Customers c ON a.CustomerID = c.CustomerID
WHERE t.Status = 'Failed'
GROUP BY a.AccountID, c.CustomerID, c.Name, YEAR(t.TxnDate), MONTH(t.TxnDate)
HAVING COUNT(t.TxnID) > 1
ORDER BY a.AccountID, YEAR(t.TxnDate), MONTH(t.TxnDate);

--6) Customer Lifetime Value (CLV) For each customer:
--CLV = Total Successful Debits + Total Successful Credits, Normalize CLV by dividing by years since JoinDate.
Select
	c.CustomerID,c.Name as 'Customer Name',c.Country,c.Segment,c.JoinDate,
	DATEDIFF(YEAR,c.JoinDate,GetDate())/365.0 as 'YearsSinceJoin',
	SUM(CASE WHEN t.Status='Success' THEN t.Amount Else 0 END) as 'TotalSuccessfulTransactions',
	SUM(CASE WHEN t.Status = 'Success' THEN t.Amount ELSE 0 END) / 
    NULLIF(DATEDIFF(DAY, c.JoinDate, GETDATE()) / 365.0, 0) AS 'CLV'
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
WHERE t.Status = 'Success'
GROUP BY c.CustomerID, c.Name, c.Country, c.Segment, c.JoinDate
ORDER BY CLV DESC;

--7) Window Function – Running Balance
--For each account, show transactions with a running balance after each transaction (ordered by TxnDate).
SELECT
    a.AccountID,
    c.CustomerID,c.Name AS 'Customer Name',
    t.TxnID,t.TxnDate,t.TxnType,t.Amount,t.Channel,t.Status,
    SUM(CASE 
            WHEN t.TxnType = 'Credit' THEN t.Amount 
            WHEN t.TxnType = 'Debit' THEN -t.Amount 
        END) OVER (
        PARTITION BY a.AccountID 
        ORDER BY t.TxnDate, t.TxnID
    ) AS 'RunningBalance'
FROM Accounts a
JOIN Customers c ON a.CustomerID = c.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
WHERE t.Status = 'Success'
ORDER BY a.AccountID, t.TxnDate, t.TxnID;

--8) Inactive Customers
--Find customers who have not made any transaction in the last 90 days (relative to max TxnDate).
WITH LatestTransaction AS (
    SELECT 
        c.CustomerID,
        MAX(t.TxnDate) AS LastTransactionDate
    FROM Customers c
    LEFT JOIN Accounts a ON c.CustomerID = a.CustomerID
    LEFT JOIN Transactions t ON a.AccountID = t.AccountID AND t.Status = 'Success'
    GROUP BY c.CustomerID
),
MaxTxnDate AS (
    SELECT MAX(TxnDate) AS OverallMaxDate FROM Transactions
)
SELECT 
    c.CustomerID,c.Name AS 'Customer Name',c.Country,c.Segment,c.JoinDate,lt.LastTransactionDate,
    DATEDIFF(DAY, lt.LastTransactionDate, md.OverallMaxDate) AS 'DaysSinceLastActivity'
FROM Customers c
JOIN LatestTransaction lt ON c.CustomerID = lt.CustomerID
CROSS JOIN MaxTxnDate md
WHERE lt.LastTransactionDate IS NULL 
   OR DATEDIFF(DAY, lt.LastTransactionDate, md.OverallMaxDate) > 90
ORDER BY DaysSinceLastActivity DESC;

--9) Recursive CTE – Managerial Fraud Chain
--Assume if an account has failed >2 transactions, mark it as “High Risk”.
--Build a recursive CTE that propagates risk to all accounts belonging to the same customer.
-- First, identify high-risk accounts (base case)
WITH CustomerRisk AS (
    SELECT 
        a.CustomerID,
        CASE 
            WHEN COUNT(CASE WHEN t.Status = 'Failed' THEN 1 END) > 2 THEN 1
            ELSE 0
        END AS IsHighRiskCustomer
    FROM Accounts a
    JOIN Transactions t ON a.AccountID = t.AccountID
    GROUP BY a.CustomerID
    HAVING COUNT(CASE WHEN t.Status = 'Failed' THEN 1 END) > 2
)
SELECT 
    c.CustomerID,c.Name AS 'Customer Name',c.Country,c.Segment,
    a.AccountID,a.AccountType,a.Status AS 'Account Status',
    COUNT(CASE WHEN t.Status = 'Failed' THEN 1 END) AS FailedTransactionCount,
    CASE 
        WHEN COUNT(CASE WHEN t.Status = 'Failed' THEN 1 END) > 2 THEN 'Direct High Risk'
        ELSE 'Propagated Risk'
    END AS RiskCategory,
    'High Risk Customer' AS OverallStatus
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
WHERE c.CustomerID IN (SELECT CustomerID FROM CustomerRisk)
GROUP BY c.CustomerID, c.Name, c.Country, c.Segment, a.AccountID, a.AccountType, a.Status
ORDER BY c.CustomerID, FailedTransactionCount DESC;

--10) Country-Wise Insights
--Find total transactions, total credits, total debits, and average transaction value per country.
SELECT
    c.Country,
    COUNT(t.TxnID) AS 'Total Transactions',
    SUM(CASE WHEN t.TxnType = 'Credit' THEN 1 ELSE 0 END) AS 'Total Credits',
    SUM(CASE WHEN t.TxnType = 'Debit' THEN 1 ELSE 0 END) AS 'Total Debits',
    SUM(CASE WHEN t.Status = 'Success' THEN 1 ELSE 0 END) AS 'Successful Transactions',
    SUM(CASE WHEN t.Status = 'Failed' THEN 1 ELSE 0 END) AS 'Failed Transactions',
    SUM(t.Amount) AS 'Total Transaction Value',
    ROUND(AVG(t.Amount), 2) AS 'Average Transaction Value',
    ROUND(SUM(CASE WHEN t.TxnType = 'Credit' THEN t.Amount ELSE 0 END), 2) AS 'Total Credit Amount',
    ROUND(SUM(CASE WHEN t.TxnType = 'Debit' THEN t.Amount ELSE 0 END), 2) AS 'Total Debit Amount',
    ROUND((SUM(CASE WHEN t.TxnType = 'Credit' THEN t.Amount ELSE 0 END) - 
           SUM(CASE WHEN t.TxnType = 'Debit' THEN t.Amount ELSE 0 END)), 2) AS 'Net Flow'
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY c.Country
ORDER BY 'Total Transactions' DESC;

--Bonus Challenge (Advanced Fraud Detection)
--Suspicious Transaction Pattern
--Find accounts that: Made back-to-back debits within 1 day (use LAG + DATEDIFF) Where each debit was above ₹1000
--These accounts should be flagged as “Suspicious”.
WITH DebitTransactions AS (
    SELECT 
        a.AccountID,
        c.CustomerID,c.Name AS 'Customer Name',c.Country,
        t.TxnID,t.TxnDate,t.Amount,t.Channel,
        LAG(t.TxnDate) OVER (PARTITION BY a.AccountID ORDER BY t.TxnDate) AS PreviousDebitDate,
        LAG(t.Amount) OVER (PARTITION BY a.AccountID ORDER BY t.TxnDate) AS PreviousDebitAmount,
        DATEDIFF(MINUTE, 
                 LAG(t.TxnDate) OVER (PARTITION BY a.AccountID ORDER BY t.TxnDate), 
                 t.TxnDate) AS MinutesSinceLastDebit
    FROM Accounts a
    JOIN Customers c ON a.CustomerID = c.CustomerID
    JOIN Transactions t ON a.AccountID = t.AccountID
    WHERE t.TxnType = 'Debit' 
      AND t.Status = 'Success'
      AND t.Amount > 1000
),
SuspiciousPatterns AS (
    SELECT 
        *,
        CASE 
            WHEN MinutesSinceLastDebit <= 1440 -- 1440 minutes = 24 hours
            THEN 'Suspicious'
            ELSE 'Normal'
        END AS PatternFlag
    FROM DebitTransactions
    WHERE PreviousDebitDate IS NOT NULL
)
SELECT 
    AccountID,CustomerID,'Customer Name' = MAX([Customer Name]),Country,
    COUNT(*) AS 'SuspiciousSequenceCount',
    MIN(TxnDate) AS 'FirstSuspiciousDate',
    MAX(TxnDate) AS 'LastSuspiciousDate',
    AVG(Amount) AS 'AverageDebitAmount',
    STRING_AGG(CONCAT(TxnID, '(', Amount, ')'), ' -> ') WITHIN GROUP (ORDER BY TxnDate) AS 'TransactionSequence',
    'Suspicious' AS 'FlagReason'
FROM SuspiciousPatterns
WHERE PatternFlag = 'Suspicious'
GROUP BY AccountID, CustomerID, Country
ORDER BY 'SuspiciousSequenceCount' DESC;
