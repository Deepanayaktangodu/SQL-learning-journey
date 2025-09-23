CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
						JoinDate DATE NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
						);

CREATE TABLE Accounts (
						AccountID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						AccountType VARCHAR(20)NOT NULL CHECK(AccountType in ('Savings','Checking')),
						Balance DECIMAL(12,2) NOT NULL CHECK(Balance>=0),
						UNIQUE (CustomerID, AccountType),
						Status VARCHAR(20) NOT NULL CHECK(Status IN ('Active','Inactive')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

CREATE TABLE Transactions (
							TransactionID INT PRIMARY KEY,
							AccountID INT NOT NULL,
							TransDate DATE NOT NULL DEFAULT GETDATE() CHECK(TransDate<=GETDATE()),
							Amount DECIMAL(12,2) NOT NULL CHECK(Amount>0),
							TransactionType VARCHAR(20) NOT NULL CHECK(TransactionType IN ('Withdrawal','Deposit')),
							Location VARCHAR(50) NOT NULL CHECK(LEN(Location)>=2),
							FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

CREATE TABLE FraudAlerts (
							AlertID INT PRIMARY KEY,
							TransactionID INT NOT NULL,
							Reason VARCHAR(255) NOT NULL,
							AlertDate DATE NOT NULL,
							FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON UPDATE NO ACTION ON DELETE NO ACTION
						);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create Index Idx_Accounts_Balance on Accounts(Balance);
Create Index Idx_Accounts_AccountType on Accounts(AccountType);
Create Index Idx_Accounts_Status on Accounts(Status);
Create Index Idx_Transactions_Amount on Transactions(Amount);
Create Index Idx_Transactions_TransactionType on Transactions(TransactionType);
Create Index Idx_Transactions_Location on Transactions(Location);
Create Index Idx_Transactions_AccountID on Transactions(AccountID);
Create Index Idx_FraudAlerts_TransactionID on FraudAlerts(TransactionID);
CREATE INDEX Idx_Transactions_Date ON Transactions(TransDate);
CREATE INDEX Idx_Customers_JoinDate ON Customers(JoinDate);
CREATE INDEX Idx_FraudAlerts_Date ON FraudAlerts(AlertDate);
CREATE INDEX Idx_Accounts_Customer_Status ON Accounts(CustomerID, Status);

INSERT INTO Customers VALUES
(1, 'Alice', 'USA', '2018-01-15'),
(2, 'Bob', 'India', '2019-05-10'),
(3, 'Charlie', 'UK', '2020-03-25'),
(4, 'David', 'Canada', '2021-07-18'),
(5, 'Eva', 'Germany', '2019-12-01');

INSERT INTO Accounts VALUES
(101, 1, 'Savings', 5000.00, 'Active'),
(102, 2, 'Checking', 12000.00, 'Active'),
(103, 3, 'Savings', 8000.00, 'Active'),
(104, 4, 'Checking', 15000.00, 'Active'),
(105, 5, 'Savings', 2000.00, 'Inactive');

INSERT INTO Transactions VALUES
(201, 101, '2023-01-10', 500.00, 'Withdrawal', 'New York'),
(202, 101, '2023-01-12', 2000.00, 'Withdrawal', 'New York'),
(203, 101, '2023-01-15', 3000.00, 'Withdrawal', 'Los Angeles'),
(204, 102, '2023-01-11', 4000.00, 'Deposit', 'Delhi'),
(205, 102, '2023-01-15', 1000.00, 'Withdrawal', 'Delhi'),
(206, 103, '2023-01-20', 500.00, 'Withdrawal', 'London'),
(207, 104, '2023-01-21', 6000.00, 'Withdrawal', 'Toronto'),
(208, 105, '2023-01-22', 1500.00, 'Withdrawal', 'Berlin'),
(209, 104, '2023-01-25', 7000.00, 'Withdrawal', 'Toronto'),
(210, 104, '2023-01-27', 7500.00, 'Withdrawal', 'New York');

INSERT INTO FraudAlerts VALUES
(301, 203, 'Unusual location', '2023-01-16'),
(302, 209, 'High withdrawal amount', '2023-01-26'),
(303, 210, 'Cross-border suspicious activity', '2023-01-28');

SELECT * FROM Customers 
SELECT * FROM Accounts 
SELECT * FROM Transactions 
SELECT * FROM FraudAlerts 

--1) Find the total transaction amount per customer.
SELECT
    c.CustomerID,c.Name,c.Country,
    COUNT(t.TransactionID) as [Total Transactions],
    ROUND(SUM(t.Amount),2) as [Total Transaction Amount],
    ROUND(AVG(t.Amount),2) as [Average Transaction Amount],
    MAX(t.Amount) as [Largest Transaction],
    MIN(t.Amount) as [Smallest Transaction]
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID 
JOIN Transactions t ON t.AccountID = a.AccountID 
GROUP BY c.CustomerID, c.Name, c.Country 
ORDER BY [Total Transaction Amount] DESC;

--2) Identify accounts with average withdrawal > 2000.
SELECT
	a.AccountID,c.CustomerID,c.Name,c.Country,
	COUNT(t.TransactionID) as [Total Transactions],
	ROUND(AVG(t.Amount),2) as [Average Withdrawal Amount]
FROM Customers c
JOIN Accounts a ON c.CustomerID =a.CustomerID 
JOIN Transactions t ON a.AccountID =t.AccountID AND t.TransactionType ='Withdrawal'
GROUP BY a.AccountID,c.CustomerID,c.Name,c.Country
HAVING AVG(t.Amount) >2000
ORDER BY [Average Withdrawal Amount] DESC;

--3) List customers who performed transactions in more than 1 country.
SELECT
    c.CustomerID,c.Name,c.Country as [Home Country],
    COUNT(t.TransactionID) as [Total Transactions],
    COUNT(DISTINCT t.Location) as [Unique Transaction Locations],
    STRING_AGG(t.Location, ', ') as [Locations Visited] 
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID 
JOIN Transactions t ON a.AccountID = t.AccountID 
GROUP BY c.CustomerID, c.Name, c.Country 
HAVING COUNT(DISTINCT t.Location) > 1
ORDER BY [Unique Transaction Locations] DESC;

--4) Find the largest transaction for each account.
WITH TransactionStats AS( 
    SELECT
        a.AccountID,a.AccountType,
		c.CustomerID,c.Name,c.Country,
        t.TransactionID,t.Amount,t.TransactionType,t.TransDate,
        RANK() OVER (PARTITION BY a.AccountID ORDER BY t.Amount DESC) AS TransactionRank
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID 
    JOIN Transactions t ON a.AccountID = t.AccountID ) 
SELECT
    AccountID,AccountType,
    CustomerID,Name,Country,
    TransactionID,Amount,
    TransactionType,TransDate
FROM TransactionStats 
WHERE TransactionRank = 1
ORDER BY Amount DESC;  

--5) Show customers who had more than 2 withdrawals in the same week.
SELECT
    c.CustomerID,c.Name,c.Country,
    YEAR(t.TransDate) as [Year],
    DATEPART(WEEK, t.TransDate) as [WeekNumber],
    COUNT(t.TransactionID) as [Withdrawal Count],
    MIN(t.TransDate) as [Week Start],
    MAX(t.TransDate) as [Week End],
    STRING_AGG(CONVERT(VARCHAR, t.TransDate, 103), ', ') as [Withdrawal Dates]
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID 
JOIN Transactions t ON a.AccountID = t.AccountID 
WHERE t.TransactionType = 'Withdrawal'
GROUP BY c.CustomerID, c.Name, c.Country, YEAR(t.TransDate), DATEPART(WEEK, t.TransDate)
HAVING COUNT(t.TransactionID) > 2
ORDER BY [Year] DESC, [WeekNumber] DESC, [Withdrawal Count] DESC;

--6) Using a window function, calculate the running total balance after each transaction.
SELECT
	t.TransactionID,t.AccountID,c.CustomerID,c.Name,
	a.AccountType,t.TransDate,t.TransactionType,
	t.Amount,t.Location,
	SUM(CASE WHEN t.TransactionType='Deposit' THEN t.Amount ELSE -t.Amount END)
	OVER (PARTITION BY a.AccountID ORDER BY t.TransDate, t.TransactionID
        ROWS UNBOUNDED PRECEDINg ) as [Running Balance]
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID 
JOIN Transactions t ON a.AccountID = t.AccountID 
ORDER BY a.AccountID, t.TransDate, t.TransactionID;

--7) Identify suspicious transactions: withdrawal > 70% of current account balance.
SELECT
	t.TransactionID,t.AccountID,
	c.CustomerID,c.Name,c.Country,
	a.AccountType,a.Balance as [Current Balance],
	t.TransDate,t.Amount as [Withdrawal Amount],
	ROUND((t.Amount / a.Balance) * 100, 2) as [Percentage of Balance],
    t.Location,
    CASE 
        WHEN (t.Amount / a.Balance) > 0.7 THEN 'HIGH RISK'
        WHEN (t.Amount / a.Balance) > 0.5 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END as [Risk Level]
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID 
JOIN Transactions t ON a.AccountID = t.AccountID 
WHERE t.TransactionType = 'Withdrawal'
    AND t.Amount > (a.Balance * 0.7)  -- More than 70% of current balance
ORDER BY [Percentage of Balance] DESC, t.Amount DESC;

--8) Find customers who had transactions flagged in FraudAlerts and their reasons.
SELECT DISTINCT
    c.CustomerID,c.Name,c.Country,f.Reason,
    COUNT(f.AlertID) as [Number of Alerts]
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID 
JOIN Transactions t ON a.AccountID = t.AccountID 
JOIN FraudAlerts f ON t.TransactionID = f.TransactionID 
GROUP BY c.CustomerID, c.Name, c.Country, f.Reason
ORDER BY [Number of Alerts] DESC, c.CustomerID;

--9) Detect customers with multiple transactions in different cities on the same day.
SELECT
    c.CustomerID,c.Name,c.Country,t.TransDate,
    COUNT(DISTINCT t.Location) as [Unique Cities],
    COUNT(t.TransactionID) as [Total Transactions],
    STRING_AGG(t.Location, ', ') as [Cities Visited],
    STRING_AGG(t.TransactionType, ', ') as [Transaction Types]
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY c.CustomerID, c.Name, c.Country, t.TransDate
HAVING COUNT(DISTINCT t.Location) > 1
ORDER BY t.TransDate DESC, [Unique Cities] DESC;

--10) Rank transactions for each customer by amount (descending) using RANK().
WITH CustomerTransactions AS (
    SELECT
        c.CustomerID,c.Name,c.Country,
        t.TransactionID,a.AccountID,a.AccountType,
        t.TransDate,t.TransactionType,t.Location,t.Amount,
        RANK() OVER (PARTITION BY c.CustomerID ORDER BY t.Amount DESC) AS TransactionRank
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID 
    JOIN Transactions t ON a.AccountID = t.AccountID)
SELECT
    CustomerID,Name,Country,
    AccountID,AccountType,
    TransactionID,TransDate,TransactionType,
    Location,Amount,TransactionRank
FROM CustomerTransactions
ORDER BY CustomerID, TransactionRank ASC;

--Bonus (Advanced):
--11) Build a query to detect potential fraud risk accounts:
--Accounts with ≥ 2 fraud alerts in last 30 days, OR Transactions from ≥ 3 different locations in a single month
WITH FraudAlertsRecent AS (
    SELECT 
        a.AccountID,
        COUNT(fa.AlertID) as AlertCount
    FROM Accounts a
    JOIN Transactions t ON a.AccountID = t.AccountID
    JOIN FraudAlerts fa ON t.TransactionID = fa.TransactionID
    WHERE fa.AlertDate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY a.AccountID
    HAVING COUNT(fa.AlertID) >= 2
),
MultiLocationMonthly AS (
    SELECT 
        a.AccountID,
        COUNT(DISTINCT t.Location) as LocationCount
    FROM Accounts a
    JOIN Transactions t ON a.AccountID = t.AccountID
    WHERE t.TransDate >= DATEADD(MONTH, -1, GETDATE())
    GROUP BY a.AccountID
    HAVING COUNT(DISTINCT t.Location) >= 3
)
SELECT 
    a.AccountID,
    c.CustomerID,c.Name,c.Country,
    a.AccountType,a.Balance,a.Status,
    COALESCE(far.AlertCount, 0) as FraudAlerts,
    COALESCE(mlm.LocationCount, 0) as UniqueLocations,
    CASE 
        WHEN far.AccountID IS NOT NULL AND mlm.AccountID IS NOT NULL THEN 'EXTREME RISK'
        WHEN far.AccountID IS NOT NULL THEN 'HIGH RISK'
        WHEN mlm.AccountID IS NOT NULL THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END as RiskLevel
FROM Accounts a
JOIN Customers c ON a.CustomerID = c.CustomerID
LEFT JOIN FraudAlertsRecent far ON a.AccountID = far.AccountID
LEFT JOIN MultiLocationMonthly mlm ON a.AccountID = mlm.AccountID
WHERE far.AccountID IS NOT NULL OR mlm.AccountID IS NOT NULL
ORDER BY RiskLevel, FraudAlerts DESC, UniqueLocations DESC;