Create table Customers (
						CustomerID int primary key,
						FullName varchar(50) not null,
						Email varchar(80) not null unique check (Email LIKE '_%@_%._%'),
						Phone Varchar (20) not null unique check (Phone NOT LIKE '%[^0-9]%'),
						Country varchar(30) not null
						);

Create table Accounts (
						AccountID int primary key,
						CustomerID int not null,
						AccountType varchar (30) not null check (AccountType IN ('Savings', 'Current')),
						Balance decimal (10,2) not null check(Balance>0),
						OpenDate date not null default getdate() check (OpenDate<=getdate()),
						foreign key (CustomerID) references Customers(CustomerID) on update cascade on delete cascade,
						unique(AccountID,CustomerID),
						);

Create table Transactions (
							TransactionID int primary key,
							AccountID int not null,
							TransactionDate date not null default getdate() check(TransactionDate<=getdate()),
							Amount decimal (10,2) not null check (Amount>0),
							TransactionType varchar(20) not null check (TransactionType in('Debit','Credit')),
							foreign key(AccountID) references Accounts(AccountID) on update cascade on delete cascade
							);

Create Index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create Index Idx_Transactions_AccountID on Transactions(AccountID);
CREATE INDEX Idx_Transactions_Date ON Transactions(TransactionDate);

INSERT INTO Customers VALUES
(1, 'Ananya Sharma', 'ananya@example.com', '9876543210', 'India'),
(2, 'Rahul Mehta', 'rahul@example.com', '8765432109', 'India'),
(3, 'Liam Smith', 'liam@example.com', '9988776655', 'USA'),
(4, 'Emma Jones', 'emma@example.com', '8877665544', 'UK');

INSERT INTO Accounts VALUES
(101, 1, 'Savings', 25000.00, '2022-01-15'),
(102, 1, 'Current', 5000.00, '2023-03-10'),
(103, 2, 'Savings', 18000.00, '2021-10-05'),
(104, 3, 'Savings', 15000.00, '2022-06-25'),
(105, 4, 'Current', 7000.00, '2022-08-01');

INSERT INTO Transactions VALUES
(1001, 101, '2023-01-10', 2000.00, 'Credit'),
(1002, 101, '2023-01-11', 1000.00, 'Debit'),
(1003, 102, '2023-03-15', 3000.00, 'Credit'),
(1004, 103, '2023-04-01', 1500.00, 'Debit'),
(1005, 104, '2023-06-05', 4000.00, 'Credit'),
(1006, 105, '2023-07-10', 700.00, 'Debit'),
(1007, 105, '2023-07-15', 1300.00, 'Debit');

Select * from Customers 
Select * from Accounts 
Select * from Transactions 

--1) List all customers with their account types and current balances.
Select
	c.CustomerID,c.FullName as 'Customer Name',
	a.AccountType,a.Balance as 'Current Balance'
from
	Customers c
left join
	Accounts a
on c.CustomerID =a.CustomerID
ORDER BY 
	c.CustomerID, a.AccountType;

--2) Show total credits and debits per account.
SELECT
    a.AccountID,
    SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) AS 'Total Credits',
    SUM(CASE WHEN t.TransactionType = 'Debit' THEN t.Amount ELSE 0 END) AS 'Total Debits',
    COUNT(t.TransactionID) AS 'Transaction Count'
FROM
    Accounts a
LEFT JOIN
    Transactions t ON a.AccountID = t.AccountID
GROUP BY
    a.AccountID
ORDER BY
    a.AccountID;

--3) Identify accounts with more than 2 transactions in July 2023.
Select
	a.AccountID,
	Count(t.TransactionID) as [Transaction Count]
from
	Accounts a
join
	Transactions t
on a.AccountID =t.AccountID 
where
	t.TransactionDate between '2023-07-01' and '2023-07-30'
Group by
	a.AccountID
HAVING
    COUNT(t.TransactionID) > 2
Order by
	[Transaction Count] Desc;

--4) Find the average transaction amount per account and highlight those above the overall average.
SELECT
    a.AccountID,
    ROUND(AVG(t.Amount), 2) AS [Average Transaction Amount]
FROM
    Accounts a
JOIN
    Transactions t ON a.AccountID = t.AccountID
GROUP BY
    a.AccountID
HAVING
    AVG(t.Amount) > (SELECT AVG(Amount) FROM Transactions)
ORDER BY
    [Average Transaction Amount] DESC;

--5)  Display customers who never made a debit transaction.
SELECT
    c.CustomerID,c.FullName AS 'Customer Name'
FROM
    Customers c
WHERE
    c.CustomerID NOT IN (
        SELECT DISTINCT a.CustomerID
        FROM Accounts a
        JOIN Transactions t ON a.AccountID = t.AccountID
        WHERE t.TransactionType = 'Debit')
ORDER BY
    c.CustomerID;

--6) List top 2 highest single transactions for each account.
WITH RankedTransactions AS (
    SELECT
        t.AccountID,t.TransactionID,t.Amount,t.TransactionDate,t.TransactionType,
        RANK() OVER (PARTITION BY t.AccountID ORDER BY t.Amount DESC) AS TransactionRank
    FROM
        Transactions t)
SELECT
    a.AccountID,r.TransactionID,r.Amount,r.TransactionDate,r.TransactionType
FROM
    Accounts a
LEFT JOIN
    RankedTransactions r ON a.AccountID = r.AccountID AND r.TransactionRank <= 2
ORDER BY
    a.AccountID,r.Amount DESC;

--7) Count number of transactions per customer and their total credited amount.
Select
	c.CustomerID,c.FullName as 'Customer Name',
	Count (t.TransactionID) as 'Transaction Count',
	SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) AS 'Total Credits'
from
	Customers c
left join
	Accounts a
on c.CustomerID =a.CustomerID 
left join
	Transactions t
on t.AccountID =a.AccountID 
Group by
	c.CustomerID,c.FullName
Order by
	SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) Desc;

--8) Show customers with at least one transaction greater than 3000.
SELECT DISTINCT
    c.CustomerID,c.FullName AS 'Customer Name',
    MAX(t.Amount) OVER (PARTITION BY c.CustomerID) AS 'Max Transaction Amount',
    COUNT(t.TransactionID) OVER (PARTITION BY c.CustomerID) AS 'Total Transactions'
FROM
    Customers c
JOIN
    Accounts a ON a.CustomerID = c.CustomerID
JOIN
    Transactions t ON t.AccountID = a.AccountID
WHERE
    t.Amount > 3000
ORDER BY
    'Max Transaction Amount' DESC;

--9) Identify customers whose savings account has a lower balance than the average of all current accounts.
WITH CurrentAccountAvg AS (
    SELECT AVG(Balance) AS AvgCurrentBalance
    FROM Accounts
    WHERE AccountType = 'Current')
SELECT 
    c.CustomerID,c.FullName AS 'Customer Name',
    a.Balance AS 'Savings Balance',
    ca.AvgCurrentBalance AS 'Average Current Account Balance'
FROM 
    Customers c
JOIN 
    Accounts a ON c.CustomerID = a.CustomerID
CROSS JOIN 
    CurrentAccountAvg ca
WHERE 
    a.AccountType = 'Savings'
    AND a.Balance < ca.AvgCurrentBalance
ORDER BY 
    a.Balance;

--10) Detect potential fraud: list accounts with more than 2 debit transactions in the same week.
WITH WeeklyDebits AS (
    SELECT
        t.AccountID,
        DATEPART(YEAR, t.TransactionDate) AS Year,
        DATEPART(WEEK, t.TransactionDate) AS Week,
        COUNT(*) AS DebitCount
    FROM
        Transactions t
    WHERE
        t.TransactionType = 'Debit'
    GROUP BY
        t.AccountID,
        DATEPART(YEAR, t.TransactionDate),
        DATEPART(WEEK, t.TransactionDate)
    HAVING
        COUNT(*) > 2)
SELECT
    a.AccountID,c.CustomerID,c.FullName AS 'Customer Name',
    a.AccountType,w.Year,w.Week,
    w.DebitCount AS 'Number of Debits',
    STRING_AGG(CONVERT(VARCHAR(10), t.TransactionDate, 120) + ' ($' + 
        CONVERT(VARCHAR(10), t.Amount) + ')', ', ') AS 'Transaction Details'
FROM
    WeeklyDebits w
JOIN
    Accounts a ON w.AccountID = a.AccountID
JOIN
    Customers c ON a.CustomerID = c.CustomerID
JOIN
    Transactions t ON t.AccountID = w.AccountID
    AND DATEPART(YEAR, t.TransactionDate) = w.Year
    AND DATEPART(WEEK, t.TransactionDate) = w.Week
    AND t.TransactionType = 'Debit'
GROUP BY
    a.AccountID,c.CustomerID,c.FullName,
    a.AccountType,w.Year,w.Week,w.DebitCount
ORDER BY
    w.DebitCount DESC,a.AccountID;

-- Bonus Challenge
-- Rank customers by total transaction volume (credit + debit) and return top customer(s) per country.
WITH CustomerTransactions AS (
    SELECT
        c.CustomerID,c.FullName,c.Country,
        SUM(t.Amount) AS 'TotalTransactionVolume',
        SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) AS 'TotalCredits',
        SUM(CASE WHEN t.TransactionType = 'Debit' THEN t.Amount ELSE 0 END) AS 'TotalDebits',
        COUNT(t.TransactionID) AS 'TransactionCount'
    FROM
        Customers c
    LEFT JOIN
        Accounts a ON c.CustomerID = a.CustomerID
    LEFT JOIN
        Transactions t ON a.AccountID = t.AccountID
    GROUP BY
        c.CustomerID, c.FullName, c.Country),
RankedCustomers AS (
    SELECT
        CustomerID,FullName,Country,
        TotalTransactionVolume,TotalCredits,TotalDebits,TransactionCount,
        DENSE_RANK() OVER (PARTITION BY Country ORDER BY TotalTransactionVolume DESC) AS 'CountryRank'
    FROM
        CustomerTransactions
    WHERE
        TotalTransactionVolume IS NOT NULl)
SELECT
    CustomerID,FullName AS 'CustomerName',Country,
    TotalTransactionVolume,TotalCredits,TotalDebits,TransactionCount
FROM
    RankedCustomers
WHERE
    CountryRank = 1
ORDER BY
    Country, TotalTransactionVolume DESC;
								