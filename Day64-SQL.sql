Create Table Customers (
							CustomerID INT PRIMARY KEY,
							Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
							Country VARCHAR(30) NOT NULL CHECK(LEN(Country)>=2),
							JoinDate Date NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE()),
							AccountType VARCHAR(20) NOT NULL CHECK(AccountType in ('Savings','Current'))
						);

Create Table Accounts (
						AccountID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						Balance DECIMAL(10,2) NOT NULL CHECK(Balance>=0),
						Status VARCHAR(15) NOT NULL CHECK(Status in ('Active','Dormant')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

Create Table Transactions(
							TransactionID INT PRIMARY KEY,
							AccountID INT NOT NULL,
							TransactionDate Date NOT NULL DEFAULT GETDATE() CHECK(TransactionDate<=GETDATE()),
							Amount DECIMAL(10,2) NOT NULL CHECK(Amount>0),
							Type VARCHAR(25) NOT NULL CHECK(Type in ('Debit','Credit')),
							FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID) ON UPDATE CASCADE ON DELETE CASCADE
							);

Create Index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create Index Idx_Transactions_AccountID on Transactions(AccountID);
Create Index Idx_Customers_Name_Country on Customers(Name,Country);
Create Index Idx_Accounts_Balance_Status on Accounts(Status,Balance);
Create Index Idx_Transactions_Amount_Type on Transactions(Amount,Type);

INSERT INTO Customers VALUES
(1, 'Rahul Mehta', 'India', '2019-05-20', 'Savings'),
(2, 'Sarah Johnson', 'USA', '2018-11-15', 'Current'),
(3, 'Aditi Sharma', 'India', '2020-02-12', 'Savings'),
(4, 'James Brown', 'UK', '2017-07-01', 'Current'),
(5, 'Arjun Nair', 'India', '2021-08-10', 'Savings');

INSERT INTO Accounts VALUES
(101, 1, 120000.00, 'Active'),
(102, 2, 56000.00, 'Active'),
(103, 3, 34000.00, 'Dormant'),
(104, 4, 200000.00, 'Active'),
(105, 5, 8000.00, 'Active');

INSERT INTO Transactions VALUES
(5001, 101, '2022-01-10', 20000.00, 'Credit'),
(5002, 101, '2022-01-12', 5000.00, 'Debit'),
(5003, 102, '2022-02-05', 30000.00, 'Credit'),
(5004, 103, '2022-02-15', 8000.00, 'Debit'),
(5005, 104, '2022-03-01', 75000.00, 'Credit'),
(5006, 105, '2022-03-10', 2000.00, 'Debit'),
(5007, 101, '2022-04-05', 40000.00, 'Credit'),
(5008, 102, '2022-04-12', 10000.00, 'Debit'),
(5009, 104, '2022-05-15', 90000.00, 'Credit');

SELECT * FROM Customers;
SELECT * FROM Accounts;
SELECT * FROM Transactions;

--1) Basic Join – List all customers with their current account balance.
SELECT
	c.CustomerID,c.Name as CustomerName, c.Country,a.Balance as CurrentBalance
FROM Customers c
JOIN Accounts a ON c.CustomerID =a.CustomerID 
ORDER BY c.CustomerID;

--2) Aggregation – Find the total credited and debited amount for each account.
SELECT
    a.AccountID,a.CustomerID,
    COUNT(t.TransactionID) as TotalTransactions,
    COALESCE(SUM(CASE WHEN t.Type = 'Credit' THEN t.Amount END), 0) as TotalCredit,
    COALESCE(SUM(CASE WHEN t.Type = 'Debit' THEN t.Amount END), 0) as TotalDebit,
    COALESCE(SUM(CASE WHEN t.Type = 'Credit' THEN t.Amount END), 0) - 
    COALESCE(SUM(CASE WHEN t.Type = 'Debit' THEN t.Amount END), 0) as NetAmount
FROM Accounts a
LEFT JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY a.AccountID, a.CustomerID
ORDER BY a.AccountID;

--3) Filtering + Date Functions – Show all transactions made in March 2022.
SELECT
    t.TransactionID,a.AccountID,a.CustomerID,
    t.TransactionDate,t.Type,t.Amount,
    c.Name AS CustomerName
FROM Transactions t
JOIN Accounts a ON t.AccountID = a.AccountID  
JOIN Customers c ON a.CustomerID = c.CustomerID
WHERE t.TransactionDate >= '2022-03-01' AND t.TransactionDate < '2022-04-01'
ORDER BY t.TransactionDate, t.TransactionID;

--4) CASE Statement – Categorize accounts as “High Balance” (>1,00,000) or “Low Balance”.
SELECT
	AccountID,CustomerID,Balance,
	CASE WHEN Balance >100000 THEN 'HighBalance' ELSE 'LowBalance' END AS AccCategory
FROM Accounts
ORDER BY AccountID;

--5) Subquery – Find the customer(s) who have the highest account balance.
SELECT TOP 1 WITH TIES
	c.CustomerID,c.Name,c.Country,
	a.AccountID,a.Balance
FROM Customers c
JOIN Accounts a ON c.CustomerID =a.CustomerID 
ORDER BY a.Balance DESC;

--Using Subquery
SELECT
    c.CustomerID,c.Name AS CustomerName,c.Country,a.AccountID,a.Balance
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
WHERE a.Balance = (SELECT MAX(Balance) FROM Accounts);

--6) Window Function (ROW_NUMBER) – Retrieve the latest transaction per account.
WITH LatestTransactions AS (
    SELECT
        t.TransactionID,t.AccountID,a.CustomerID,
        c.Name AS CustomerName,t.TransactionDate,t.Amount,t.Type,
        ROW_NUMBER() OVER (PARTITION BY t.AccountID  ORDER BY t.TransactionDate DESC, t.TransactionID DESC) AS TransactionRank
    FROM Transactions t
    JOIN Accounts a ON t.AccountID = a.AccountID
    JOIN Customers c ON a.CustomerID = c.CustomerID)
SELECT
    TransactionID,AccountID,CustomerID,CustomerName,TransactionDate,Amount,Type
FROM LatestTransactions
WHERE TransactionRank = 1
ORDER BY AccountID;

--7) Window Function (RANK) – Rank customers by their total credited amount.
-- Include all customers, even those with no credits
SELECT
    c.CustomerID,c.Name,c.Country,
    COALESCE(SUM(CASE WHEN t.Type = 'Credit' THEN t.Amount END), 0) AS TotalCreditedAmount,
    RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN t.Type = 'Credit' THEN t.Amount END), 0) DESC) AS CreditRank
FROM Customers c
LEFT JOIN Accounts a ON a.CustomerID = c.CustomerID
LEFT JOIN Transactions t ON t.AccountID = a.AccountID AND t.Type = 'Credit'
GROUP BY c.CustomerID, c.Name, c.Country
ORDER BY CreditRank;

--8) CTE (Recursive) – Generate a running balance for AccountID = 101 based on transactions.
SELECT 
    t.TransactionID,t.AccountID,t.TransactionDate,t.Amount,t.Type,a.Balance AS CurrentBalance,
    SUM(CASE  WHEN t.Type = 'Credit' THEN t.Amount WHEN t.Type = 'Debit' THEN -t.Amount END) 
	OVER (PARTITION BY t.AccountID ORDER BY t.TransactionDate, t.TransactionID ROWS UNBOUNDED PRECEDING) AS RunningBalance
FROM Transactions t
JOIN Accounts a ON t.AccountID = a.AccountID
WHERE t.AccountID = 101
ORDER BY t.TransactionDate, t.TransactionID;

--9) Advanced Aggregation – For each customer, calculate the average debit amount per transaction.
WITH CustomerDebitStats AS (
    SELECT
        c.CustomerID,c.Name AS CustomerName,c.Country,
        COUNT(t.TransactionID) AS TotalDebitTransactions,
        AVG(t.Amount) AS AvgDebitAmount,
        SUM(t.Amount) AS TotalDebitedAmount,
        MIN(t.Amount) AS MinDebitAmount,
        MAX(t.Amount) AS MaxDebitAmount,
        COUNT(DISTINCT a.AccountID) AS AccountsWithDebits
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID
    JOIN Transactions t ON a.AccountID = t.AccountID
    WHERE t.Type = 'Debit'
    GROUP BY c.CustomerID, c.Name, c.Country)
SELECT
    CustomerID,CustomerName,Country,TotalDebitTransactions,
    ROUND(AvgDebitAmount, 2) AS AverageDebitAmount,
    TotalDebitedAmount,MinDebitAmount,MaxDebitAmount,AccountsWithDebits,
    ROUND(TotalDebitedAmount / NULLIF(TotalDebitTransactions, 0), 2) AS ManualAverage -- Verification
FROM CustomerDebitStats
ORDER BY AverageDebitAmount DESC;

--10) Fraud-style Query – Identify accounts where more than 2 transactions above 50,000 occurred within 60 days.
WITH LargeTransactions AS (
    SELECT 
        t1.AccountID,t1.TransactionID,
        t1.TransactionDate,t1.Amount,t1.Type,
        a.CustomerID,c.Name AS CustomerName
    FROM Transactions t1
    JOIN Accounts a ON t1.AccountID = a.AccountID
    JOIN Customers c ON a.CustomerID = c.CustomerID
    WHERE t1.Amount > 50000
),
SuspiciousPatterns AS (
    SELECT 
        lt1.AccountID,lt1.CustomerID,lt1.CustomerName,lt1.TransactionDate AS StartDate,
        MAX(lt2.TransactionDate) AS EndDate,
        COUNT(DISTINCT lt2.TransactionID) AS LargeTransactionsInPeriod,
        SUM(lt2.Amount) AS TotalLargeAmount,
        AVG(lt2.Amount) AS AverageLargeAmount
    FROM LargeTransactions lt1
    JOIN LargeTransactions lt2 ON lt1.AccountID = lt2.AccountID
        AND lt2.TransactionDate BETWEEN lt1.TransactionDate AND DATEADD(DAY, 60, lt1.TransactionDate)
    GROUP BY lt1.AccountID, lt1.CustomerID, lt1.CustomerName, lt1.TransactionDate
    HAVING COUNT(DISTINCT lt2.TransactionID) > 2
)
SELECT DISTINCT
    AccountID,CustomerID,CustomerName,
    LargeTransactionsInPeriod,TotalLargeAmount,
    ROUND(AverageLargeAmount, 2) AS AverageLargeAmount,
    StartDate,EndDate,
    DATEDIFF(DAY, StartDate, EndDate) AS DaysInPeriod
FROM SuspiciousPatterns
ORDER BY TotalLargeAmount DESC, LargeTransactionsInPeriod DESC;

--11)	Bonus Challenge 
--Find the customer who contributed the highest share of total credits in the bank and display their percentage contribution.
WITH CustomerCredits AS(
				SELECT
					c.CustomerID,c.Name,c.Country,
					SUM(t.Amount) AS TotalCustomerCredit
				FROM Customers c
				JOIN Accounts a ON c.CustomerID =a.AccountID 
				JOIN Transactions t ON t.AccountID =a.AccountID 
				WHERE t.Type ='Credit'
				GROUP BY c.CustomerID,c.Name,c.Country),
OverAllCredits AS (
	SELECT SUM(TotalCustomerCredit) AS TotalBankCredit
	FROM CustomerCredits)
SELECT
	CustomerID,Name,Country,TotalCustomerCredit,
	ROUND((TotalCustomerCredit * 100.0 / TotalBankCredit), 2) AS CreditContributionPercent
FROM CustomerCredits, OverAllCredits 
ORDER BY CreditContributionPercent DESC;