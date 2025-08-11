CREATE TABLE Departments (
							DeptID INT PRIMARY KEY,
							DeptName VARCHAR(50)
						);

CREATE TABLE Employees (
							EmpID INT PRIMARY KEY,
							EmpName VARCHAR(100),
							DeptID INT,
							Salary DECIMAL(10,2),
							JoinDate DATE,
							ManagerID INT NULL,
							FOREIGN KEY (DeptID) REFERENCES Departments(DeptID) 
						);

INSERT INTO Departments VALUES
(1, 'HR'), (2, 'Finance'), (3, 'IT'), (4, 'Marketing');

INSERT INTO Employees VALUES
(101, 'Amit', 1, 50000, '2020-01-15', NULL),
(102, 'Priya', 2, 65000, '2019-03-20', 101),
(103, 'Rahul', 3, 70000, '2021-06-10', 101),
(104, 'Sneha', 4, 55000, '2022-02-25', 102),
(105, 'Karan', 3, 72000, '2020-11-11', 103);

Select * from Departments 
Select * from Employees 

--1) List employees who have been with the company for more than 3 years.
SELECT 
	EmpName, JoinDate
FROM 
	Employees
WHERE 
	JoinDate <= DATEADD(YEAR, -3, GETDATE());

--2) Find the highest paid employee in each department (use window function).
With RankedEmployees as (
				Select
						e.EmpID,e.EmpName,d.DeptID,d.DeptName,e.Salary,
						Rank() over (Partition by d.DeptID order by e.Salary Desc) as rank
					from
							Employees e
					join
						Departments d
					on e.DeptID =d.DeptID )
Select 
	EmpID,EmpName,DeptID,DeptName,Salary
from
	RankedEmployees 
where
	rank=1;

--4) Find departments where the average salary is above the company average.
WITH DeptAverages AS (
    SELECT 
        d.DeptName,
        AVG(e.Salary) as AvgDeptSalary
    FROM Employees e
    JOIN Departments d ON e.DeptID = d.DeptID
    GROUP BY d.DeptID, d.DeptName
),
CompanyAverage AS (
    SELECT AVG(Salary) as AvgCompanySalary FROM Employees
)
SELECT DeptName, AvgDeptSalary
FROM DeptAverages, CompanyAverage
WHERE AvgDeptSalary > AvgCompanySalary;

--6) Find the employee who manages the highest number of people.
SELECT TOP 1 m.EmpName as ManagerName, COUNT(e.EmpID) as NumberOfReports
FROM Employees e
JOIN Employees m ON e.ManagerID = m.EmpID
GROUP BY m.EmpID, m.EmpName
ORDER BY NumberOfReports DESC;

--9) Retrieve employees who do not have a manager.
Select
	empID,EmpName
from
	Employees
where
	ManagerID is null;

--10) Calculate the running total of salaries ordered by joining date.
SELECT 
    EmpName,JoinDate,Salary,
    SUM(Salary) OVER (ORDER BY JoinDate) as RunningTotal
FROM Employees
ORDER BY JoinDate;

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    City VARCHAR(50)
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

INSERT INTO Customers VALUES
(1, 'Ravi', 'Delhi'),
(2, 'Simran', 'Mumbai'),
(3, 'John', 'Bangalore');

INSERT INTO Orders VALUES
(1001, 1, '2023-01-15', 2500),
(1002, 2, '2023-02-17', 1800),
(1003, 1, '2023-03-20', 3200),
(1004, 3, '2023-03-22', 1500);

Select*from Customers 
Select * from Orders 

--3) Show all customers who have placed more than one order.
SELECT
	c.CustomerName, COUNT(o.OrderID) as OrderCount
FROM 
	Customers c
JOIN 
	Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
	c.CustomerID, c.CustomerName
HAVING COUNT(o.OrderID) > 1;

-- 7) Display the month and total sales amount for the top 2 highest sales months.
SELECT TOP 2
    FORMAT(OrderDate, 'yyyy-MM') AS Month,
    SUM(TotalAmount) AS TotalSales
FROM Orders
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY TotalSales DESC;

CREATE TABLE Transactions (
    TxnID INT PRIMARY KEY,
    CustomerID INT,
    TxnDate DATE,
    TxnAmount DECIMAL(10,2),
    TxnType VARCHAR(20)
);

INSERT INTO Transactions VALUES
(1, 1, '2023-01-15', 500, 'Credit'),
(2, 1, '2023-02-01', 700, 'Debit'),
(3, 2, '2023-02-10', 1000, 'Credit'),
(4, 3, '2023-03-12', 1200, 'Debit');

Select * from Transactions 

--5) Identify customers who have both 'Credit' and 'Debit' transactions.
SELECT DISTINCT 
	c.CustomerName
FROM
	Customers c
WHERE c.CustomerID IN (
    SELECT CustomerID 
    FROM Transactions 
    WHERE TxnType = 'Credit'
) AND c.CustomerID IN (
    SELECT CustomerID 
    FROM Transactions 
    WHERE TxnType = 'Debit'
);

-- 8) Show customers who have placed orders but have no debit transactions.
SELECT DISTINCT 
	c.CustomerName
FROM 
	Customers c
JOIN 
	Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID NOT IN (
    SELECT CustomerID 
    FROM Transactions 
    WHERE TxnType = 'Debit'
);
	
--Bonus Challenge
-- Find customers whose total transaction amount is greater than their total order amount.
SELECT c.CustomerName
FROM Customers c
JOIN (
    SELECT CustomerID, SUM(TxnAmount) as TotalTransactions
    FROM Transactions
    GROUP BY CustomerID
) t ON c.CustomerID = t.CustomerID
JOIN (
    SELECT CustomerID, SUM(TotalAmount) as TotalOrders
    FROM Orders
    GROUP BY CustomerID
) o ON c.CustomerID = o.CustomerID
WHERE t.TotalTransactions > o.TotalOrders;



