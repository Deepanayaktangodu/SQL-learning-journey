Create table Customers (
						CustomerID int Primary key,
						Name varchar(75) not null Check(len(Name)>=2),
						Age int not null Check(Age>0),
						City varchar(50) not null Check(len(City)>=2)
						);

Create table Accounts (
						AccountID int Primary key,
						CustomerID int not null,
						BranchID int not null,
						AccountType varchar(30) not null Check(AccountType in ('Savings','Current')),
						Balance decimal(10,2) not null Check(Balance>=0),
						foreign key(CustomerID) references Customers(CustomerID) on update cascade on delete no action
						);

Create table Transactions (
							TransactionID int Primary key,
							AccountID int not null,
							Amount decimal(10,2) not null Check(Amount>0),
							TransactionType varchar(50) not null Check(TransactionType in('Debit','Credit')),
							TransactionDate date not null default getdate() Check(TransactionDate<=getdate()),
							foreign key(AccountID) references Accounts(AccountID) on update cascade on delete no action
							);

Create table Branches (
						BranchID int Primary key,
						BranchName varchar(100) not null Check(len(BranchName)>=2),
						City varchar(50) not null Check(len(City)>=2)
						);

Create Index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create Index Idx_Transactions_AccountID on Transactions(AccountID);
Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_City on Customers(City);
Create Index Idx_Branches_BranchName on Branches(BranchName);

INSERT INTO Customers VALUES
(1, 'Rahul Shah', 32, 'Mumbai'),
(2, 'Neha Rao', 45, 'Delhi'),
(3, 'Arjun Mehta', 28, 'Bangalore'),
(4, 'Priya Iyer', 36, 'Chennai');

INSERT INTO Accounts (AccountID, CustomerID, BranchID, AccountType, Balance) VALUES
(101, 1, 11, 'Savings', 50000),
(102, 2, 12, 'Current', 120000),
(103, 3, 11, 'Savings', 30000),
(104, 4, 13, 'Current', 80000);

INSERT INTO Transactions (TransactionID, AccountID, Amount, TransactionType, TransactionDate) VALUES
(1001, 101, 2000, 'Debit', '2023-05-01'),
(1002, 101, 1500, 'Credit', '2023-05-02'),
(1003, 102, 50000, 'Debit', '2023-05-03'),
(1004, 103, 20000, 'Debit', '2023-05-04'),
(1005, 104, 10000, 'Credit', '2023-05-05'),
(1006, 101, 25000, 'Debit', '2023-05-06');

INSERT INTO Branches (BranchID, BranchName, City) VALUES
(11, 'Andheri', 'Mumbai'),
(12, 'Connaught', 'Delhi'),
(13, 'T Nagar', 'Chennai');

Select * from Customers 
Select * from Accounts 
Select *from Transactions 
Select * from Branches 

--1) Retrieve all customers along with their account type and balance.
Select
	c.CustomerID,c.Name as 'Customer Name',c.City,
	a.AccountID,a.AccountType,a.Balance
from Customers c
join Accounts a on c.CustomerID =a.CustomerID ;

--2) Find the top 2 highest balance accounts per branch using window functions.
WITH RankedAccounts AS (
    SELECT
        a.AccountID,b.BranchName,a.Balance,
        ROW_NUMBER() OVER (PARTITION BY b.BranchID ORDER BY a.Balance DESC) AS BalanceRank
    FROM Accounts a
    JOIN Branches b ON a.BranchID = b.BranchID)
SELECT
    BranchName,AccountID,Balance
FROM RankedAccounts
WHERE BalanceRank <= 2
ORDER BY BranchName, Balance DESC;

--3) Identify customers who made more than 2 transactions in May 2023.
SELECT
    c.CustomerID,c.Name AS 'Customer Name',c.City
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
WHERE t.TransactionDate >= '2023-05-01' AND t.TransactionDate < '2023-06-01'
GROUP BY c.CustomerID, c.Name, c.City
HAVING COUNT(t.TransactionID) > 2;

--4) Write a query to calculate the total debit and credit amount per account.
Select
	a.AccountID,
	SUM(Case when t.TransactionType='Debit' then t.Amount else 0 end) as TotalDebitAmount,
	SUM(Case when t.TransactionType='Credit' then t.Amount else 0 end) as TotalCredit
from Transactions t
join Accounts a on t.AccountID =a.AccountID 
Group by a.AccountID 
Order by a.AccountID ;

--5) Find accounts where the balance dropped below 10,000 at any point (simulate fraud detection).
WITH TransactionHistory AS (
    SELECT
        AccountID,TransactionDate,Amount,TransactionType,
        CASE
            WHEN TransactionType = 'Debit' THEN -Amount
            ELSE Amount
        END AS SignedAmount
    FROM Transactions),
RunningBalance AS (
    SELECT
        AccountID,TransactionDate,
        SUM(SignedAmount) OVER (
            PARTITION BY AccountID
            ORDER BY TransactionDate
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CurrentBalance
    FROM TransactionHistory)
SELECT DISTINCT AccountID
FROM RunningBalance
WHERE CurrentBalance < 10000;

--6) List customers who do not have any transactions.
Select
	c.CustomerID,c.Name as 'Customer Name'
from Customers c
left join Accounts a on a.CustomerID =c.CustomerID 
left join Transactions t on t.AccountID =a.AccountID
where t.TransactionID is null
group by c.CustomerID,c.Name
order by c.CustomerID ;

--7) Calculate the average transaction amount per branch.
Select
	b.BranchID,b.BranchName,
	ROUND(AVG(T.Amount),2) as [Average transaction amount]
from Branches b
join Accounts a on b.BranchID =a.BranchID 
join Transactions t on t.AccountID =a.AccountID 
Group by b.BranchID,b.BranchName
Order by [Average transaction amount] Desc;

--8) Use NTILE(4) to divide customers into quartiles based on their account balance.
Select
	c.CustomerID,c.Name as 'Customer Name',a.Balance,
	NTILE(4) Over (Order By a.Balance Desc) as Quartile
from Customers c
join Accounts a on c.CustomerID =a.CustomerID 
Order by Quartile , a.Balance Desc;

--9) Find customers who had consecutive high-value debits (>20,000) using LAG().
WITH DebitTransactions AS (
    SELECT
        AccountID,TransactionDate,Amount,
        LAG(Amount, 1) OVER (
            PARTITION BY AccountID
            ORDER BY TransactionDate
        ) AS PreviousAmount,
        LAG(TransactionType, 1) OVER (
            PARTITION BY AccountID
            ORDER BY TransactionDate
        ) AS PreviousTransactionType
    FROM Transactions
    WHERE
        TransactionType = 'Debit'
        AND Amount > 20000),
ConsecutiveHighValueDebits AS (
    SELECT DISTINCT AccountID
    FROM DebitTransactions
    WHERE
        PreviousAmount > 20000
        AND PreviousTransactionType = 'Debit')
SELECT DISTINCT
    c.CustomerID,c.Name AS 'Customer Name'
FROM Customers c
JOIN
    Accounts a ON c.CustomerID = a.CustomerID
JOIN
    ConsecutiveHighValueDebits ctv ON a.AccountID = ctv.AccountID;

--10) Calculate churn rate: % of customers with zero transactions in May 2023.
WITH TotalCustomers AS (
    SELECT
        COUNT(DISTINCT CustomerID) AS TotalCustomersCount
    FROM Customers),
CustomersWithTransactionsInMay AS (
    SELECT
        COUNT(DISTINCT a.CustomerID) AS CustomersWithTxnCount
    FROM Transactions t
    JOIN
        Accounts a ON t.AccountID = a.AccountID
    WHERE
        t.TransactionDate >= '2023-05-01'
        AND t.TransactionDate < '2023-06-01'),
CustomersWithZeroTransactions AS (
    SELECT
        (SELECT TotalCustomersCount FROM TotalCustomers) - (SELECT CustomersWithTxnCount FROM CustomersWithTransactionsInMay) AS ChurnedCustomersCount
)
SELECT
    CAST(CAST(ChurnedCustomersCount AS DECIMAL) * 100 / (SELECT TotalCustomersCount FROM TotalCustomers) AS DECIMAL(5, 2)) AS ChurnRate
FROM
    CustomersWithZeroTransactions;

--Bonus: 
--Optimize a query to count total transactions per branch. Compare COUNT(*) with COUNT(1) and discuss indexing impact.
SELECT
    b.BranchName,
    COUNT(t.TransactionID) AS TotalTransactions
FROM Branches b
JOIN Accounts a ON b.BranchID = a.BranchID
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY b.BranchName
ORDER BY TotalTransactions DESC;
