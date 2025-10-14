Create Table Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Country VARCHAR(30) NOT NULL CHECK(LEN(Country)>=2),
						JoinDate DATE NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE()),
						Age INT NOT NULL CHECK(Age>18)
						);

Create Table Accounts (
						AccountID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						AccountType Varchar(30) NOT NULL CHECK(AccountType in ('Savings','Current')),
						Balance DECIMAL(10,2) NOT NULL CHECK(Balance>=0),
						OpenDate DATE NOT NULL CHECK(OpenDate<=GETDATE()),
						UNIQUE(CustomerID,AccountType),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE
					);

Create Table Transactions (
							TransactionID INT PRIMARY KEY,
							AccountID INT NOT NULL,
							Amount DECIMAL(10,2) NOT NULL CHECK(Amount>0),
							TransactionType VARCHAR(20) NOT NULL CHECK(TransactionType in ('Credit','Debit')),
							TransactionDate DATE NOT NULL DEFAULT GETDATE(),
							Channel VARCHAR(20) NOT NULL,
							FOREIGN KEY(AccountID) REFERENCES Accounts(AccountID) ON UPDATE CASCADE ON DELETE CASCADE
						  );

Create Table Loans (
					LoanID INT PRIMARY KEY,
					CustomerID INT NOT NULL,
					LoanType VARCHAR(20) NOT NULL CHECK(LoanType in ('Personal','Home','Car')),
					LoanAmount DECIMAL(10,2) NOT NULL CHECK(LoanAmount>0),
					StartDate DATE NOT NULL DEFAULT GETDATE(),
					InterestRate DECIMAL (10,2) NOT NULL CHECK(InterestRate>0),
					FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE
					);

Create Index Idx_Customers_Name_Country on Customers(Name,Country);
Create Index Idx_Customers_JoinDate on Customers(JoinDate);
Create Index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create Index Idx_Accounts_AccountType_Balance on Accounts(AccountType,Balance);
Create Index Idx_Accounts_OpenDate on Accounts(OpenDate);
Create Index Idx_Transactions_AccountID on Transactions(AccountID);
Create Index Idx_Transactions_Amount on Transactions(Amount);
Create Index Idx_Transactions_TransactionType_TransactionDate on Transactions(TransactionType,TransactionDate);
Create Index Idx_Transactions_Channel on Transactions(Channel);
Create Index Idx_Loans_LoanType_LoanAmount on Loans(LoanType,LoanAmount);
Create Index Idx_Loans_StartDate on Loans(StartDate);
Create Index Idx_Transactions_AccountID_TransactionDate on Transactions(AccountID,TransactionDate);
Create Index Idx_Transactions_TransactionType_Amount on Transactions(TransactionType,Amount);
Create index Idx_Customers_Country on Customers(Country);
CREATE INDEX Idx_Accounts_Balance ON Accounts(Balance);
CREATE INDEX Idx_Customers_Age_Country ON Customers(Age, Country);

INSERT INTO Customers (CustomerID, Name, Country, JoinDate, Age) VALUES
(1, 'Priya Nair', 'India', '2020-03-05', 28),
(2, 'David Lee', 'USA', '2021-06-15', 35),
(3, 'Fatima Noor', 'UAE', '2019-11-22', 30),
(4, 'Rohan Mehta', 'India', '2022-01-10', 26),
(5, 'Maria Garcia', 'Spain', '2021-02-20', 33);

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, OpenDate) VALUES
(101, 1, 'Savings', 55000.00, '2020-03-05'),
(102, 2, 'Current', 88000.00, '2021-06-15'),
(103, 3, 'Savings', 67000.00, '2019-11-22'),
(104, 4, 'Current', 30000.00, '2022-01-10'),
(105, 5, 'Savings', 75000.00, '2021-02-20');

INSERT INTO Transactions (TransactionID, AccountID, Amount, TransactionType, TransactionDate, Channel) VALUES
(1001, 101, 2000.00, 'Credit', '2022-06-01', 'UPI'),
(1002, 101, 1500.00, 'Debit', '2022-06-05', 'Card'),
(1003, 102, 3000.00, 'Credit', '2022-06-07', 'Online'),
(1004, 102, 2500.00, 'Debit', '2022-06-08', 'Card'),
(1005, 103, 4000.00, 'Credit', '2022-06-10', 'Branch'),
(1006, 103, 1000.00, 'Debit', '2022-06-12', 'UPI'),
(1007, 104, 5000.00, 'Credit', '2022-06-15', 'UPI'),
(1008, 104, 2000.00, 'Debit', '2022-06-18', 'Online'),
(1009, 105, 6000.00, 'Credit', '2022-06-20', 'Branch'),
(1010, 105, 1000.00, 'Debit', '2022-06-22', 'Card');

INSERT INTO Loans (LoanID, CustomerID, LoanType, LoanAmount, StartDate, InterestRate) VALUES
(201, 1, 'Personal', 200000.00, '2021-03-01', 9.50),
(202, 3, 'Home', 500000.00, '2020-05-10', 8.00),
(203, 5, 'Car', 300000.00, '2021-07-01', 10.20);

SELECT * FROM Customers;
SELECT * FROM Accounts;
SELECT * FROM Transactions;
SELECT * FROM Loans;

--1) Join Practice
--Show customer name, account type, and their latest transaction date.
SELECT
	c.CustomerID,c.Name,a.AccountType,
	MAX(t.TransactionDate) as LatestTransactionDate
FROM Customers c
JOIN Accounts a ON c.CustomerID =a.CustomerID 
LEFT JOIN Transactions t ON t.AccountID=a.AccountID 
GROUP BY c.CustomerID,c.Name,a.AccountType
ORDER BY C.CustomerID;

--2) Aggregation + Conditional Logic
--Calculate total credited and debited amount for each customer using CASE WHEN.
SELECT
    c.CustomerID,c.Name,c.Country,
    SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) AS TotalCreditAmount,
    SUM(CASE WHEN t.TransactionType = 'Debit' THEN t.Amount ELSE 0 END) AS TotalDebitAmount,
    SUM(CASE 
            WHEN t.TransactionType = 'Credit' THEN t.Amount 
            WHEN t.TransactionType = 'Debit' THEN -t.Amount 
            ELSE 0 END) AS NetAmount
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
LEFT JOIN Transactions t ON t.AccountID = a.AccountID
GROUP BY c.CustomerID, c.Name, c.Country
ORDER BY c.CustomerID;

--3) CTE + Aggregation
--Using a CTE, calculate total transaction amount per customer, and list only those who transacted more than 5,000 in total.
WITH CustomerTransactionStatistics AS (
						SELECT
							c.CustomerID,c.Name,c.Country,
							ROUND(SUM(t.Amount),2) as TotalTransactionAmount,
							SUM(CASE WHEN t.TransactionType='Creit' THEN t.Amount ELSE 0 END) AS TotalCredits,
							SUM(CASE WHEN t.TransactionType='Debit' THEN t.Amount ELSE 0 END) AS TotalDebits
						FROM  Customers c
						JOIN Accounts a ON c.CustomerID =a.CustomerID 
						JOIN Transactions t ON t.AccountID =a.AccountID 
						GROUP BY c.CustomerID,c.Name,c.Country )
SELECT
	CustomerID,Name,Country,TotalTransactionAmount,TotalCredits,TotalDebits
FROM CustomerTransactionStatistics WHERE TotalTransactionAmount>5000
ORDER BY TotalTransactionAmount DESC;

--4) Subquery Filtering
--Find customers who made at least one transaction greater than 4,000.
SELECT
	c.CustomerID,c.Name,c.Country
FROM Customers c
WHERE EXISTS (
	SELECT 1
		FROM Accounts a
		JOIN Transactions t ON a.AccountID =t.AccountID 
		WHERE a.CustomerID =c.CustomerID 
		AND t.Amount >4000)
ORDER BY c.CustomerID;

--Alternative Using Subquery
SELECT
    c.CustomerID,c.Name,c.Country,c.JoinDate
FROM Customers c
WHERE c.CustomerID IN (
    SELECT DISTINCT a.CustomerID
    FROM Accounts a
    JOIN Transactions t ON a.AccountID = t.AccountID
    WHERE t.Amount > 4000)
ORDER BY c.CustomerID;

--5) Window Function (LAG)
--For each account, calculate the number of days between consecutive transactions.
WITH TransactionIntervals AS (
    SELECT
        t.TransactionID,t.AccountID,a.CustomerID,c.Name AS CustomerName,
        t.Amount,t.TransactionType,t.TransactionDate,t.Channel,
        LAG(t.TransactionDate) OVER (PARTITION BY t.AccountID ORDER BY t.TransactionDate) AS PreviousTransactionDate,
        DATEDIFF(day, LAG(t.TransactionDate) OVER (PARTITION BY t.AccountID ORDER BY t.TransactionDate), t.TransactionDate) AS DaysBetweenTransactions
    FROM Transactions t
    JOIN Accounts a ON t.AccountID = a.AccountID
    JOIN Customers c ON a.CustomerID = c.CustomerID)
SELECT
    AccountID,CustomerID,CustomerName,TransactionID,
    Amount,TransactionType,TransactionDate,PreviousTransactionDate,DaysBetweenTransactions,
    CASE 
        WHEN DaysBetweenTransactions IS NULL THEN 'First Transaction'
        WHEN DaysBetweenTransactions = 0 THEN 'Same Day'
        WHEN DaysBetweenTransactions <= 7 THEN 'Within Week'
        WHEN DaysBetweenTransactions <= 30 THEN 'Within Month'
        ELSE 'Over Month'
    END AS TransactionIntervalCategory
FROM TransactionIntervals
ORDER BY AccountID, TransactionDate;

--6) Ranking
--Rank customers based on total credited amount (highest first).
SELECT
    c.CustomerID,c.Name,c.Country,
    SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) AS TotalCreditedAmount,
    RANK() OVER (ORDER BY SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) DESC) AS CreditAmountRank
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY c.CustomerID, c.Name, c.Country
ORDER BY CreditAmountRank;

--7) Nested CTE + Analytics
--Using nested CTEs, calculate each country’s total transaction volume and find which customer contributed the most in that country.
WITH CountryTransactionTotals AS (
    SELECT
        c.Country,
        SUM(t.Amount) AS TotalCountryVolume,
        COUNT(t.TransactionID) AS TotalTransactionCount
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID
    JOIN Transactions t ON a.AccountID = t.AccountID
    GROUP BY c.Country
),
CustomerContributions AS (
    SELECT
        c.Country,c.CustomerID,c.Name AS CustomerName,
        SUM(t.Amount) AS CustomerTotalAmount,
        COUNT(t.TransactionID) AS CustomerTransactionCount
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID
    JOIN Transactions t ON a.AccountID = t.AccountID
    GROUP BY c.Country, c.CustomerID, c.Name
),
RankedCustomers AS (
    SELECT
        cc.Country,cc.CustomerID,cc.CustomerName,cc.CustomerTotalAmount,cc.CustomerTransactionCount,
        RANK() OVER (PARTITION BY cc.Country ORDER BY cc.CustomerTotalAmount DESC) AS CustomerRank
    FROM CustomerContributions cc
)
SELECT
    ct.Country,ct.TotalCountryVolume,ct.TotalTransactionCount,
    rc.CustomerID AS TopCustomerID,rc.CustomerName AS TopCustomerName,
    rc.CustomerTotalAmount AS TopCustomerContribution,
    rc.CustomerTransactionCount AS TopCustomerTransactionCount,
    ROUND((rc.CustomerTotalAmount * 100.0 / ct.TotalCountryVolume), 2) AS TopCustomerPercentage
FROM CountryTransactionTotals ct
JOIN RankedCustomers rc ON ct.Country = rc.Country
WHERE rc.CustomerRank = 1
ORDER BY ct.TotalCountryVolume DESC;

--8) Correlated Subquery
--Find customers whose balance is above their country’s average balance.
SELECT
    c.CustomerID,c.Name,c.Country,a.AccountType,a.Balance,
    (SELECT AVG(a2.Balance) 
     FROM Accounts a2 
     JOIN Customers c2 ON a2.CustomerID = c2.CustomerID 
     WHERE c2.Country = c.Country) AS CountryAverageBalance
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
WHERE a.Balance > (
    SELECT AVG(a2.Balance)
    FROM Accounts a2
    JOIN Customers c2 ON a2.CustomerID = c2.CustomerID
    WHERE c2.Country = c.Country
)
ORDER BY c.Country, a.Balance DESC;

--9) JOIN + Date Logic
--List all loan holders who had an active loan before their first recorded transaction.
WITH CustomerFirstTransactions AS (
    SELECT
        a.CustomerID,
        MIN(t.TransactionDate) AS FirstTransactionDate
    FROM Accounts a
    JOIN Transactions t ON a.AccountID = t.AccountID
    GROUP BY a.CustomerID
),
CustomerFirstLoans AS (
    SELECT
        CustomerID,
        MIN(StartDate) AS FirstLoanDate
    FROM Loans
    GROUP BY CustomerID
)
SELECT
    c.CustomerID,c.Name,c.Country,
    cft.FirstTransactionDate,cfl.FirstLoanDate,
    l.LoanType,l.LoanAmount,
    DATEDIFF(day, cfl.FirstLoanDate, cft.FirstTransactionDate) AS DaysLoanBeforeTransaction
FROM Customers c
JOIN CustomerFirstTransactions cft ON c.CustomerID = cft.CustomerID
JOIN CustomerFirstLoans cfl ON c.CustomerID = cfl.CustomerID
JOIN Loans l ON c.CustomerID = l.CustomerID AND l.StartDate = cfl.FirstLoanDate
WHERE cfl.FirstLoanDate < cft.FirstTransactionDate
ORDER BY DaysLoanBeforeTransaction DESC;

--10) Real-World Finance Query (Advanced)
--Identify customers whose total debit percentage (debit / total transactions * 100) exceeds 40%.
SELECT
    c.CustomerID,c.Name,c.Country,
    COUNT(t.TransactionID) AS TotalTransactions,
    SUM(CASE WHEN t.TransactionType = 'Debit' THEN t.Amount ELSE 0 END) AS TotalDebitAmount,
    SUM(CASE WHEN t.TransactionType = 'Credit' THEN t.Amount ELSE 0 END) AS TotalCreditAmount,
    SUM(t.Amount) AS TotalTransactionAmount,
    ROUND(
        (SUM(CASE WHEN t.TransactionType = 'Debit' THEN t.Amount ELSE 0 END) * 100.0 / NULLIF(SUM(t.Amount), 0)), 2) AS DebitPercentage
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY c.CustomerID, c.Name, c.Country
HAVING (SUM(CASE WHEN t.TransactionType = 'Debit' THEN t.Amount ELSE 0 END) * 100.0 / NULLIF(SUM(t.Amount), 0)) > 40
ORDER BY DebitPercentage DESC;

--11) Bonus Challenge (Complex Analytical Logic)
--Find the top loyal customer — defined as the one who has made the most consistent monthly transactions 
--(one or more per month for maximum consecutive months)
WITH MonthlyTransactions AS (
    SELECT
        c.CustomerID,c.Name,c.Country,
        FORMAT(t.TransactionDate, 'yyyy-MM') AS TransactionMonth,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(FORMAT(t.TransactionDate, 'yyyy-MM-01') AS DATE)), 0) AS MonthStart,
        COUNT(t.TransactionID) AS MonthlyTransactionCount
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID
    JOIN Transactions t ON a.AccountID = t.AccountID
    GROUP BY c.CustomerID, c.Name, c.Country, 
             FORMAT(t.TransactionDate, 'yyyy-MM'),
             DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(FORMAT(t.TransactionDate, 'yyyy-MM-01') AS DATE)), 0)
),
ConsecutiveMonths AS (
    -- Identify consecutive months using window functions
    SELECT
        CustomerID,Name,Country,
        MonthStart,TransactionMonth,
        MonthlyTransactionCount,
        LAG(MonthStart) OVER (PARTITION BY CustomerID ORDER BY MonthStart) AS PreviousMonth,
        DATEDIFF(MONTH, 
                 LAG(MonthStart) OVER (PARTITION BY CustomerID ORDER BY MonthStart), 
                 MonthStart) AS MonthGap
    FROM MonthlyTransactions
),
ConsecutiveGroups AS (
    -- Create groups of consecutive months
    SELECT
        CustomerID,Name,Country,
        MonthStart,TransactionMonth,MonthlyTransactionCount,
        SUM(CASE WHEN MonthGap = 1 THEN 0 ELSE 1 END) 
            OVER (PARTITION BY CustomerID ORDER BY MonthStart) AS ConsecutiveGroup
    FROM ConsecutiveMonths
),
ConsecutiveStreaks AS (
    -- Calculate streak length for each consecutive group
    SELECT
        CustomerID,Name,Country,ConsecutiveGroup,
        MIN(TransactionMonth) AS StreakStart,
        MAX(TransactionMonth) AS StreakEnd,
        COUNT(*) AS ConsecutiveMonths,
        SUM(MonthlyTransactionCount) AS TotalTransactionsInStreak,
        AVG(MonthlyTransactionCount) AS AvgMonthlyTransactions
    FROM ConsecutiveGroups
    GROUP BY CustomerID, Name, Country, ConsecutiveGroup
),
RankedStreaks AS (
    SELECT
        CustomerID,Name,Country,
        StreakStart,StreakEnd,ConsecutiveMonths,
        TotalTransactionsInStreak,AvgMonthlyTransactions,
        ROW_NUMBER() OVER (ORDER BY ConsecutiveMonths DESC, TotalTransactionsInStreak DESC) AS OverallRank,
        RANK() OVER (ORDER BY ConsecutiveMonths DESC) AS StreakRank,
        DENSE_RANK() OVER (ORDER BY ConsecutiveMonths DESC) AS StreakDenseRank
    FROM ConsecutiveStreaks
)
-- Final result: Top loyal customers
SELECT
    CustomerID,Name,Country,
    StreakStart,StreakEnd,
    ConsecutiveMonths,TotalTransactionsInStreak,
    ROUND(AvgMonthlyTransactions, 2) AS AvgMonthlyTransactions,
    CASE 
        WHEN ConsecutiveMonths >= 24 THEN 'Platinum Loyal'
        WHEN ConsecutiveMonths >= 12 THEN 'Gold Loyal' 
        WHEN ConsecutiveMonths >= 6 THEN 'Silver Loyal'
        ELSE 'Bronze Loyal'
    END AS LoyaltyTier
FROM RankedStreaks
WHERE OverallRank = 1  -- Top loyal customer
ORDER BY ConsecutiveMonths DESC, TotalTransactionsInStreak DESC;

