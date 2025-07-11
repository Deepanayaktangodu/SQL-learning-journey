CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						CustomerName VARCHAR(100) NOT NULL,
						City VARCHAR(100),
						JoinDate DATE NOT NULL CHECK (JoinDate <= CAST(GETDATE() AS DATE))
						);

CREATE TABLE Orders (
					OrderID INT PRIMARY KEY,
					CustomerID INT NOT NULL,
					Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
					OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE) CHECK (OrderDate <= CAST(GETDATE() AS DATE)),
					FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
					);

Insert into Customers (CustomerID ,CustomerName, City, JoinDate)
Values
		(1, 'Priya Sharma', 'Delhi', '2020-01-15'),
		(2, 'Rahul Jain', 'Mumbai', '2019-11-03'),
		(3, 'Aarti Desai', 'Ahmedabad', '2021-06-25'),
		(4, 'Ravi Kumar', 'Bengaluru', '2020-07-19'),
		(5, 'Sneha Agarwal', 'Hyderabad', '2019-02-10');

Insert into Orders (OrderID, CustomerID, Amount, OrderDate)
Values
		(101, 1, 1500, '2022-03-10'),
		(102, 2, 3000, '2022-04-12'),
		(103, 3, 750, '2022-05-15'),
		(104, 2, 1200, '2022-06-18'),
		(105, 5, 4000, '2021-07-20'),
		(106, 1, 2500, '2021-08-15'),
		(107, 4, 1800, '2022-02-11');

Select * from Customers 
Select * from Orders 

-- 1) List all customers with their city and join date.

Select * from Customers ;

-- 2) Show total order amount per customer.

Select
	c.CustomerName, sum (o.Amount) as [Total Amount]
from
	Customers c
Join
	Orders o
on
c.CustomerID =o.CustomerID
Group by
	c.CustomerName;

-- 3) Which customers have placed more than 1 order? (Use HAVING clause)

SELECT
	c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM
	Customers c
JOIN 
	Orders o 
ON 
c.CustomerID = o.CustomerID
GROUP BY
	c.CustomerName
HAVING
	COUNT(o.OrderID) > 1;

-- 4) List customers who joined in or after 2020.

Select
	CustomerName, JoinDate
from
	Customers 
where
	JoinDate >='2020-01-01';

--5) Classify each order as 'High' if amount > 2000, else 'Low'.(Use CASE WHEN).
	
SELECT
	OrderID, Amount,
    CASE 
        WHEN Amount > 2000 THEN 'High'
        ELSE 'Low'
    END AS OrderClassification
FROM 
	Orders;

-- 6) Show month-wise total orders (by amount).(Extract month from OrderDate)

SELECT 
    MONTH(OrderDate) AS Month,
    SUM(Amount) AS TotalAmount
FROM
    Orders
GROUP BY 
    MONTH(OrderDate)
ORDER BY
    Month;

-- 7) Which customers haven’t placed any order? (LEFT JOIN + NULL).

SELECT
	c.CustomerName
FROM 
	Customers c
LEFT JOIN 
	Orders o 
ON
c.CustomerID = o.CustomerID
WHERE 
	o.OrderID IS NULL;

-- 8) Find average order amount for customers who joined before 2020.

SELECT
	AVG(o.Amount) AS AverageOrderAmount
FROM 
	Orders o
JOIN 
	Customers c ON o.CustomerID = c.CustomerID
WHERE
	c.JoinDate < '2020-01-01';

--9) List customer names and the number of days since their first order.

SELECT 
    c.CustomerName,
    MIN(o.OrderDate) AS FirstOrderDate,
    DATEDIFF(DAY, MIN(o.OrderDate), GETDATE()) AS DaysSinceFirstOrder
FROM 
    Customers c
JOIN 
    Orders o ON c.CustomerID = o.CustomerID
GROUP BY
    c.CustomerName;

-- Bonus Challenge
--Write a query to rank customers by total spending (highest to lowest) using RANK() or DENSE_RANK().

SELECT 
    c.CustomerName,SUM(o.Amount) AS TotalSpending,
	DENSE_RANK() OVER (ORDER BY SUM(o.Amount) DESC) AS SpendingRank
FROM 
	Customers c
JOIN 
	Orders o ON c.CustomerID = o.CustomerID
GROUP BY
	c.CustomerName
ORDER BY 
	TotalSpending DESC;
