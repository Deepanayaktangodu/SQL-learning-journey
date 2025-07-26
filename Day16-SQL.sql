Create table Customers (
						CustomerID int primary key,
						Name varchar (50) not null,
						Age int not null  check (Age>0 AND Age <120),
						Country varchar (50) not null
						);

Create table Accounts (
						AccountID int primary key,
						CustomerID int not null,
						AccountType varchar (25) not null,
						Balance decimal (10,2) not null check (Balance >=0),
						Status VARCHAR(10) DEFAULT 'Active' CHECK (Status IN ('Active', 'Inactive', 'Closed')),
						foreign key (CustomerID) references Customers(CustomerID) on delete cascade
						);

Create table Transactions (
							TransactionID int primary key,							
							AccountID int not null,
							Amount decimal (10,2) not null check (Amount>0),
							TransactionType Varchar (50) not null CHECK (TransactionType IN ('Deposit','Withdrawal')),
							TransactionDate Date not null DEFAULT GETDATE() check (TransactionDate<=GETdate()),
							foreign key (AccountID) references Accounts (AccountID) on delete cascade
							);

Create index Idx_Accounts_CustomerID on Accounts(CustomerID);
Create index Idx_Transactions_AccountID on Transactions(AccountID);

INSERT INTO Customers (CustomerID, Name, Age, Country) VALUES
(1, 'Alice', 30, 'USA'),
(2, 'Bob', 45, 'UK'),
(3, 'Chitra', 28, 'India'),
(4, 'Diego', 35, 'Brazil'),
(5, 'Eva', 40, 'Germany');

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance) VALUES
(101, 1, 'Savings', 5000.00),
(102, 1, 'Checking', 1200.00),
(103, 2, 'Savings', 8000.00),
(104, 3, 'Checking', 1500.00),
(105, 4, 'Savings', 700.00),
(106, 5, 'Savings', 9600.00);

INSERT INTO Transactions (TransactionID, AccountID, Amount, TransactionType, TransactionDate) VALUES
(1001, 101, 1000.00, 'Deposit', '2024-06-01'),
(1002, 102, 200.00, 'Withdrawal', '2024-06-02'),
(1003, 103, 3000.00, 'Deposit', '2024-06-03'),
(1004, 104, 500.00, 'Withdrawal', '2024-06-05'),
(1005, 105, 150.00, 'Deposit', '2024-06-07'),
(1006, 106, 800.00, 'Deposit', '2024-06-09'),
(1007, 101, 400.00, 'Withdrawal', '2024-06-10');

Select * from Customers 
Select * from Accounts 
Select * from Transactions 

--1) List all customers along with their account types and balances.
SELECT
    c.CustomerID,c.Name AS 'Customer Name',
    ISNULL(a.AccountType, 'No Account') AS 'Account Type',
    ISNULL(a.Balance, 0.00) AS 'Balance'
FROM
    Customers c
LEFT JOIN
    Accounts a ON c.CustomerID = a.CustomerID
ORDER BY
    c.Name, a.AccountType;

--2) Show total number of accounts per account type.
SELECT
	COUNT (AccountID) as [Number of Accounts], AccountType
from
	Accounts 
Group by
	 AccountType
Order by
	[Number of Accounts] Desc;

--3) Calculate the total deposit amount per customer.
Select
	c.CustomerID,c.Name as 'Customer Name',
	COALESCE (SUM (t.Amount),0) as [Total Deposit Amount]
from
	Customers c
left join
	Accounts a
on c.CustomerID =a.CustomerID 
left join
	Transactions t
on a.AccountID =t.AccountID AND t.TransactionType = 'Deposit'
Group by 
	c.CustomerID,c.Name
Order by
	[Total Deposit Amount] Desc;

--4) Find the top 3 customers with the highest total withdrawal amount.
SELECT TOP 3
    c.CustomerID,c.Name AS 'Customer Name',
    COALESCE(SUM(t.Amount), 0) AS 'Total Withdrawal Amount'
FROM
    Customers c
LEFT JOIN
    Accounts a ON c.CustomerID = a.CustomerID 
LEFT JOIN
    Transactions t ON a.AccountID = t.AccountID 
    AND t.TransactionType = 'Withdrawal' 
GROUP BY
    c.CustomerID, c.Name
ORDER BY
    [Total Withdrawal Amount] DESC;

--5) Display customer names with the highest account balance.
SELECT TOP 1 WITH TIES
    c.Name AS 'Customer Name',
    a.Balance AS 'Highest Account Balance'
FROM
    Customers c
JOIN
    Accounts a ON c.CustomerID = a.CustomerID
ORDER BY
    a.Balance DESC;

--6) Show the average transaction amount per transaction type.
Select
	TransactionType,
	Round(AVG(Amount),2) as [AVG Transaction Amount]
from
	Transactions t
Group by
	TransactionType
Order by
	[AVG Transaction Amount] Desc;

--7) List all transactions that happened in the first week of June 2024.
SELECT * FROM Transactions
WHERE
	TransactionDate BETWEEN '2024-06-01' AND '2024-06-07 23:59:59.999'
ORDER BY 
	TransactionDate;

--8) Show customers who made no transactions.
Select
	c.CustomerID, c.Name as 'Customer Name'
from
	Customers c
left join
	Accounts a
on c.CustomerID =a.CustomerID 
left join
	Transactions t
on a.AccountID =t.AccountID 
WHERE
	t.TransactionID is null
Group by
	c.CustomerID, c.Name;

--9) For each customer, calculate net transaction amount (deposit - withdrawal).
SELECT
    c.CustomerID, c.Name AS 'Customer Name',
    SUM(CASE WHEN t.TransactionType = 'Deposit' THEN t.Amount ELSE -t.Amount END) AS 'Net Transaction Amount'
FROM
    Customers c
JOIN
    Accounts a ON c.CustomerID = a.CustomerID
JOIN
    Transactions t ON a.AccountID = t.AccountID
GROUP BY
    c.CustomerID, c.Name
ORDER BY
    'Net Transaction Amount' DESC;

--10) For each country, show the total balance held by customers.
SELECT
    c.Country, COALESCE(SUM(a.Balance), 0) AS 'Total Balance'
FROM
    Customers c
LEFT JOIN
    Accounts a ON c.CustomerID = a.CustomerID
GROUP BY
    c.Country
ORDER BY
    [Total Balance] DESC;

--Bonus Challenge
--Identify customers who have more than 1 account and have made deposits totaling over 1000.
With CustomerDeposits as(
			Select
				c.CustomerID, c.Name as 'Customer Name',
				Count (Distinct a.AccountID) as 'AccountCount',
				SUM(CASE WHEN t.TransactionType = 'Deposit' THEN t.Amount ELSE 0 END) AS 'TotalDeposits'
			from
				Customers c
			Join
				Accounts a
			on c.CustomerID =a.CustomerID 
			left join
				Transactions t
			on a.AccountID =t.AccountID 
			Group by
				c.CustomerID, c.Name)
			Select
				CustomerID, [Customer Name],AccountCount,TotalDeposits
			FROM
				CustomerDeposits
			WHERE
				AccountCount > 1
				AND TotalDeposits > 1000
			ORDER BY
				TotalDeposits DESC;
   