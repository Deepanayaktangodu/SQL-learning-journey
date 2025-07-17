Create Table Customers (
						CustomerID int Primary key,
						CustomerName char (75)  not null,
						Country varchar (50) not null
						);

Create Table Orders (
					OrderID int Primary key,
					CustomerID int not null,
					OrderDate Date not null check (OrderDate<=GetDate()),
					TotalAmount decimal (10,2) not null check (TotalAmount>0),
					foreign key (CustomerID) references Customers (CustomerID)
					);

Create Table Payments (
						PaymentID int primary key,
						OrderID int not null,
						PaymentDate Date not null check (PaymentDate<=GetDate()),
						AmountPaid decimal (10,2) not null check (AmountPaid>0),
						foreign key (OrderID) references Orders (OrderID)
						);

CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_Payments_OrderID ON Payments(OrderID);

Insert into Customers (CustomerID,CustomerName,Country)
Values
	(1,'Ananya','India'),
	(2,'John','USA'),
	(3,'Mei','China'),
	(4,'Carlos','Mexico'),
	(5,'Fatima','UAE');

Insert into  Orders (OrderID,CustomerID,OrderDate,TotalAmount)
Values
	(101,1,'2023-05-10',500),
	(102,2,'2023-06-12',300),
	(103,1,'2023-06-14',150),
	(104,3,'2023-07-01',700),
	(105,5,'2023-07-02',200);

Insert into Payments (PaymentID,OrderID,PaymentDate,AmountPaid)
Values
	(201,101,'2023-05-11',500),
	(202,102,'2023-06-13',300),
	(203,103,'2023-06-15',150),
	(204,104,'2023-07-03',700);

Select * from Customers 
Select * from Orders 
Select * from Payments 

-- 1) List all customers along with their total number of orders.

Select
	c.CustomerName, Count (o.OrderID) as [Total Orders]
from
	Customers c
left join
	Orders o
on c.CustomerID =o.CustomerID 
Group by
	c.CustomerName 
Order by
	[Total Orders] Desc;

-- 2) Show total revenue (sum of TotalAmount) generated per country.

Select
	c.Country,  COALESCE(SUM(o.TotalAmount), 0) AS [Total Revenue]
from
	Customers c
left join
	Orders o
on c.CustomerID = o.CustomerID 
Group by
	c.Country 
Order by
	[Total revenue] Desc;

-- 3) Find customers who haven’t placed any orders.

SELECT
    c.CustomerID, c.CustomerName
FROM
    Customers c
LEFT JOIN
    Orders o ON c.CustomerID = o.CustomerID
WHERE
    o.OrderID IS NULL
ORDER BY
    c.CustomerName;

-- 4) List all orders with their corresponding payment status (Paid or Not Paid).

SELECT
    o.OrderID, o.CustomerID,o.OrderDate, o.TotalAmount,
    CASE
        WHEN p.PaymentID IS NOT NULL THEN 'Paid'
        ELSE 'Not Paid'
    END AS PaymentStatus
FROM
    Orders o
LEFT JOIN
    Payments p ON o.OrderID = p.OrderID
ORDER BY
    o.OrderDate DESC;

-- 5) Display total amount paid by each customer.

Select
	o.CustomerID,c.CustomerName, Coalesce(sum (p.AmountPaid),0) as [Total Amount Paid]
From
	Customers c
left join
	Orders O
on c.CustomerID =o.CustomerID 
left join
	Payments p 
on o.OrderID =p.OrderID 
Group by
	o.CustomerID,c.CustomerName
Order by
	[Total Amount Paid] Desc;

-- 6) Identify customers who made more than one payment.

Select
	o.CustomerID,c.CustomerName, count (p.PaymentID) as [Number of Payments]
from
	Customers c
join
	Orders o
on c.CustomerID =o.CustomerID 
join
	Payments p
on o.OrderID =p.OrderID 
Group by
	o.CustomerID,c.CustomerName
Having
	  COUNT(p.PaymentID) > 1
Order by
	[Number of Payments] Desc;


-- 7) Show orders where the full payment hasn’t been received.

SELECT 
    o.OrderID, o.CustomerID, o.TotalAmount AS [Order Amount],
    COALESCE(SUM(p.AmountPaid), 0) AS [Amount Paid],
    o.TotalAmount - COALESCE(SUM(p.AmountPaid), 0) AS [Balance Due]
FROM
    Orders o
LEFT JOIN
    Payments p ON o.OrderID = p.OrderID
GROUP BY
    o.OrderID, o.CustomerID, o.TotalAmount
HAVING
    COALESCE(SUM(p.AmountPaid), 0) < o.TotalAmount
    OR COUNT(p.PaymentID) = 0
ORDER BY
    [Balance Due] DESC;

-- 8) List customers who have placed orders in June 2023.

SELECT DISTINCT
    c.CustomerID, c.CustomerName, o.OrderDate
FROM
    Customers c
JOIN
    Orders o ON c.CustomerID = o.CustomerID
WHERE
    o.OrderDate BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY
    o.OrderDate;

-- 9) Rank customers by their total spending (TotalAmount from Orders).

Select
	c.CustomerID,c.CustomerName,sum(o.TotalAmount) as [Total Spending],
	Rank() over (Order by sum(o.TotalAmount) Desc) as [SpendingRank]
from
	Customers c
left join
	Orders o
on c.CustomerID =o.CustomerID 
Group by
	c.CustomerID,c.CustomerName
Order by
	[Total Spending] Desc;

--10) Calculate average order value per country.

SELECT
    c.Country,
    ROUND(COALESCE(AVG(o.TotalAmount), 0), 2) AS [Average Order Value],
    COALESCE(COUNT(o.OrderID), 0) AS [Number of Orders],
    COALESCE(SUM(o.TotalAmount), 0) AS [Total Revenue]
FROM
    Customers c
LEFT JOIN
    Orders o ON c.CustomerID = o.CustomerID
GROUP BY
    c.Country
ORDER BY
    [Average Order Value] DESC;

--
-- Bonus Challenge
--Write a query to find the top 2 spending customers from each country based on total order value.

WITH CustomerSpending AS (
    SELECT
        c.Country,c.CustomerID,c.CustomerName,
        SUM(o.TotalAmount) AS TotalSpent,
        ROW_NUMBER() OVER (PARTITION BY c.Country ORDER BY SUM(o.TotalAmount) DESC) AS RankInCountry
    FROM
        Customers c
    LEFT JOIN
        Orders o ON c.CustomerID = o.CustomerID
    GROUP BY
        c.Country, c.CustomerID, c.CustomerName
)
SELECT
    Country,CustomerID,CustomerName,TotalSpent
FROM
    CustomerSpending
WHERE
    RankInCountry <= 2
    AND TotalSpent IS NOT NULL
ORDER BY
    Country,
    TotalSpent DESC;