CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50)NOT NULL CHECK(LEN(Name)>=2),
						Email VARCHAR(100) NOT NULL CHECK(Email like ('%@%.com')),
						Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
						JoinDate DATE NOT NULL CHECK(JoinDate<=GETDATE())
						);

CREATE TABLE Products (
						ProductID INT PRIMARY KEY,
						ProductName VARCHAR(100) NOT NULL UNIQUE CHECK(LEN(ProductName)>=2),
						Category VARCHAR(50) NOT NULL CHECK(LEN(Category)>=2),
						Price DECIMAL(10,2) NOT NULL  CHECK(Price>0)
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE DEFAULT GETDATE() NOT NULL,
						TotalAmount DECIMAL(10,2) NOT NULL CHECK(TotalAmount>=0),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Cancelled')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK(Quantity>0),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE NO ACTION,
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE NO ACTION
							);

CREATE TABLE Payments (
						PaymentID INT PRIMARY KEY,
						OrderID INT NOT NULL,
						PaymentDate DATE DEFAULT GETDATE(),
						Amount DECIMAL(10,2) CHECK(Amount>=0),
						PaymentMethod VARCHAR(20) NOT NULL,
						FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Email on Customers(Email);
Create Index Idx_Customers_Country on Customers(Country);
CREATE INDEX Idx_Customers_JoinDate ON Customers(JoinDate);
CREATE UNIQUE INDEX Idx_Customers_Email_Unique ON Customers(Email) WHERE Email IS NOT NULL;
Create Index Idx_Products_ProductName on Products(ProductName);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_Products_Price on Products(Price);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_Orders_TotalAmount on Orders(TotalAmount);
CREATE INDEX Idx_Orders_OrderDate ON Orders(OrderDate);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create Index Idx_Payments_Amount on Payments(Amount);
CREATE INDEX Idx_Payments_PaymentDate ON Payments(PaymentDate);
Create Index Idx_Payments_OrderID on Payments(OrderID);

INSERT INTO Customers VALUES
(1, 'Alice', 'alice@example.com', 'USA', '2021-01-15'),
(2, 'Bob', 'bob@example.com', 'India', '2021-03-20'),
(3, 'Charlie', 'charlie@example.com', 'UK', '2021-05-12'),
(4, 'David', 'david@example.com', 'USA', '2021-08-02'),
(5, 'Eva', 'eva@example.com', 'Germany', '2021-09-25');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 1200.00),
(102, 'Smartphone', 'Electronics', 800.00),
(103, 'Headphones', 'Accessories', 150.00),
(104, 'Desk Chair', 'Furniture', 250.00),
(105, 'Notebook', 'Stationery', 5.00);

INSERT INTO Orders VALUES
(1001, 1, '2021-02-01', 2000.00, 'Completed'),
(1002, 2, '2021-03-25', 800.00, 'Completed'),
(1003, 3, '2021-06-15', 155.00, 'Cancelled'),
(1004, 1, '2021-09-10', 1205.00, 'Completed'),
(1005, 4, '2021-11-20', 250.00, 'Completed');

INSERT INTO OrderDetails VALUES
(1, 1001, 101, 1),
(2, 1001, 103, 2),
(3, 1002, 102, 1),
(4, 1003, 105, 10),
(5, 1004, 101, 1),
(6, 1004, 104, 1),
(7, 1005, 104, 1);

INSERT INTO Payments VALUES
(1, 1001, '2021-02-02', 2000.00, 'Credit Card'),
(2, 1002, '2021-03-26', 800.00, 'UPI'),
(3, 1004, '2021-09-12', 1205.00, 'PayPal'),
(4, 1005, '2021-11-22', 250.00, 'Credit Card');

Select * from Customers 
Select * from Products 
Select * from Orders 
Select * from OrderDetails 
Select * from Payments 

--1) Retrieve top 3 customers by total spending (use SUM + ORDER BY + LIMIT/TOP).
-- Retrieve top 3 customers by total spending
SELECT TOP 3
    c.CustomerID,c.Name AS "Customer Name",c.Country,
    ROUND(SUM(o.TotalAmount), 2) AS "Total Spending",
    COUNT(o.OrderID) AS "Total Orders"
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID 
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name, c.Country 
ORDER BY "Total Spending" DESC;

--2) Find customers who have never placed an order (use LEFT JOIN / NOT EXISTS).
Select 
	c.CustomerID,c.Name AS "Customer Name",c.Country
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID =o.CustomerID 
WHERE O.OrderID IS NULL;

--3) Calculate the average order value per customer (use AVG + GROUP BY).
SELECT
	c.CustomerID,c.Name AS "Customer Name",c.Country,
	COUNT(o.OrderID) as [Total Orders],
	ROUND(AVG(o.TotalAmount),2) as [Average Order Value]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
WHERE o.Status='Completed'
GROUP BY c.CustomerID,c.Name,c.Country
ORDER BY [Average Order Value] DESC;

--4) Show the most popular product category (highest sales by revenue).
-- Show the most popular product (highest sales by revenue)
SELECT TOP 1
    p.ProductID,p.ProductName,p.Category,
    COUNT(DISTINCT o.OrderID) AS "Number of Orders",
    SUM(od.Quantity) AS "Total Units Sold",
    ROUND(SUM(od.Quantity * p.Price), 2) AS "Total Revenue"
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID 
JOIN Orders o ON o.OrderID = od.OrderID 
WHERE o.Status = 'Completed'
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY "Total Revenue" DESC;

--5) Compare Completed vs Cancelled orders count using a CASE WHEN.
-- Compare Completed vs Cancelled orders count
SELECT
    COUNT(OrderID) AS "Total Orders",
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS "Completed Order Count",
    SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) AS "Cancelled Order Count",
    ROUND(SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(OrderID), 2) AS "Completed Percentage",
    ROUND(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(OrderID), 2) AS "Cancelled Percentage"
FROM Orders;

--6) For each month, calculate total revenue (use DATEPART / EXTRACT + GROUP BY).
SELECT
    YEAR(o.OrderDate) AS "Year",
    MONTH(o.OrderDate) AS "Month Number",
    DATENAME(MONTH, o.OrderDate) AS "Month Name",
    ROUND(SUM(od.Quantity * p.Price), 2) AS "Total Revenue",
    COUNT(DISTINCT o.OrderID) AS "Number of Orders"
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.Status = 'Completed'
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
ORDER BY "Year", "Month Number";

--7) Find customers who placed orders in more than one country (use JOIN + GROUP BY HAVING).
SELECT
	c.CustomerID,c.Name as 'Customer Name',c.Country,
	COUNT(DISTINCT o.OrderID) as [Order Count],
	COUNT(c.Country) as [Country Count]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
WHERE o.Status='Completed'
GROUP BY c.CustomerID,c.Name,c.Country
HAVING COUNT(c.Country)>1
ORDER BY [Country Count] DESC;

--Alternative Method
-- Find customers with orders in multiple statuses
SELECT
    c.CustomerID,c.Name AS 'Customer Name',c.Country,
    COUNT(DISTINCT o.OrderID) AS 'Order Count',
    COUNT(DISTINCT o.Status) AS 'Status Count',
    STRING_AGG(o.Status, ', ') AS 'Order Statuses'
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name, c.Country
HAVING COUNT(DISTINCT o.Status) > 1
ORDER BY 'Status Count' DESC;

--8) Use a Window Function (RANK) to list top products by revenue.
-- List top products by revenue using window function
SELECT
    p.ProductID,p.ProductName,p.Category,
    ROUND(SUM(od.Quantity * p.Price), 2) AS "Total Revenue",
    RANK() OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS RevenueRank
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID 
JOIN Orders o ON o.OrderID = od.OrderID 
WHERE o.Status = 'Completed'
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY RevenueRank ASC;

--9) Write a query to find repeat customers (customers with more than 1 completed order).
SELECT
	c.CustomerID,c.Name AS 'Customer Name',c.Country,
	COUNT(DISTINCT o.OrderID) as [Count Orders]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID
WHERE o.Status ='Completed'
GROUP BY c.CustomerID,c.Name,c.Country
HAVING COUNT(DISTINCT o.OrderID) >1
ORDER BY [Count Orders] DESC;

--10) Find the payment method contributing the highest revenue.
-- Find the payment method contributing the highest revenue
SELECT TOP 1
    PaymentMethod,
    ROUND(SUM(Amount), 2) AS "Total Revenue",
    COUNT(PaymentID) AS "Number of Payments",
    ROUND(SUM(Amount) / COUNT(PaymentID), 2) AS "Average Payment Amount"
FROM Payments
GROUP BY PaymentMethod
ORDER BY "Total Revenue" DESC;

--Bonus (Advanced):
--Compare performance of these two approaches for finding customers with no orders:
--NOT EXISTS
--LEFT JOIN ... IS NULL
SELECT
	c.CustomerID,c.Name AS 'Customer Name',c.Country
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID =o.CustomerID 
WHERE o.OrderID IS NULL;

SELECT 
	c.CustomerID,c.Name AS 'Customer Name',c.Country
FROM Customers C
WHERE NOT EXISTS (
			SELECT 1
			FROM Orders o
			WHERE o.CustomerID =c.CustomerID 
			);

--Performance Comparison:

--NOT EXISTS Advantages:
--Semantic Clarity: Clearly expresses the intent "find customers where no orders exist"
--Early Termination: Can stop searching as soon as it finds one matching order
--Optimizer Friendly: Many database optimizers can convert NOT EXISTS to efficient execution plans
--NULL Safety: Works correctly even if CustomerID contains NULL values

--LEFT JOIN Advantages:
--Familiar Syntax: More developers are comfortable with JOIN syntax
--Flexibility: Easier to extend if you need additional fields from the Orders table
--Visualization: Easier to understand the data flow for some developers
