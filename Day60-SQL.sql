CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						City VARCHAR(50) NOT NULL CHECK(LEN(City)>=2),
						Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
						JoinDate DATE NOT NULL  DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
						);


CREATE TABLE Sellers (
						SellerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2) ,
						Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
						Rating DECIMAL(3,2) NOT NULL CHECK(Rating>=0)
					);


CREATE TABLE Products (
						ProductID INT PRIMARY KEY,
						Name VARCHAR(100) UNIQUE NOT NULL CHECK(LEN(Name)>=2),
						Category VARCHAR(50) NOT NULL CHECK(LEN(Category)>=2),
						Price DECIMAL(10,2) NOT NULL CHECK(Price>0),
						SellerID INT NOT NULL,
						FOREIGN KEY (SellerID) REFERENCES Sellers(SellerID) ON UPDATE CASCADE ON DELETE CASCADE
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE NOT NULL DEFAULT GETDATE(),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Cancelled')),
						UNIQUE(CustomerID,OrderID),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE
					);

CREATE TABLE OrderDetails (
							OrderDetailID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ProductID INT NOT NULL,
							Quantity INT NOT NULL CHECK(Quantity>0),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE CASCADE
						);

CREATE TABLE Payments (
						PaymentID INT PRIMARY KEY,
						OrderID INT NOT NULL,
						PaymentDate DATE NOT NULL DEFAULT GETDATE() CHECK(PaymentDate<=GETDATE()),
						PaymentMethod VARCHAR(20) NOT NULL CHECK(PaymentMethod in ('Credit Card','PayPal','NetBanking')),
						Amount DECIMAL(10,2) NOT NULL CHECK(Amount>0),
						UNIQUE(PaymentID,OrderID),
						FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE
					);

CREATE TABLE Reviews (
						ReviewID INT PRIMARY KEY,
						ProductID INT NOT NULL,
						CustomerID INT NOT NULL,
						Rating INT  NOT NULL CHECK(Rating BETWEEN 1 AND 5),
						Comment VARCHAR(255) NOT NULL,
						ReviewDate DATE DEFAULT GETDATE(),
						UNIQUE(ProductID,CustomerID,Rating),
						FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON UPDATE CASCADE ON DELETE CASCADE,
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE
					);

Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_City on Customers(City);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Customers_JoinDate on Customers(JoinDate);
Create Index Idx_Sellers_Name on Sellers(Name);
Create Index Idx_Sellers_Country on Sellers(Country);
Create Index Idx_Sellers_Rating on Sellers(Rating);
Create Index Idx_Products_Name on Products(Name);
Create Index Idx_Products_Category on Products(Category);
Create Index Idx_Products_Price on Products(Price);
Create Index Idx_Products_SellerID on Products(SellerID);
Create Index Idx_Orders_OrderDate on Orders(OrderDate);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_OrderDetails_Quantity on OrderDetails(Quantity);
Create Index Idx_OrderDetails_OrderID on OrderDetails(OrderID);
Create Index Idx_OrderDetails_ProductID on OrderDetails(ProductID);
Create Index Idx_Payments_PaymentDate on Payments(PaymentDate);
Create Index Idx_Payments_PaymentMethod on Payments(PaymentMethod);
Create Index Idx_Payments_Amount on Payments(Amount);
Create Index Idx_Payments_OrderID on Payments(OrderID);
Create Index Idx_Reviews_Rating on Reviews(Rating);
Create Index Idx_Reviews_ProductID on Reviews(ProductID);
Create Index Idx_Reviews_CustomerID on Reviews(CustomerID);
CREATE INDEX Idx_Products_Category_Price ON Products(Category, Price);
CREATE INDEX Idx_Products_Seller_Category ON Products(SellerID, Category);
CREATE INDEX Idx_Orders_Date_Status ON Orders(OrderDate, Status);
CREATE INDEX Idx_Orders_Customer_Date ON Orders(CustomerID, OrderDate);
CREATE INDEX Idx_OrderDetails_Order_Product ON OrderDetails(OrderID, ProductID);

INSERT INTO Customers VALUES
(1, 'Alice', 'New York', 'USA', '2020-01-15'),
(2, 'Bob', 'London', 'UK', '2019-03-22'),
(3, 'Charlie', 'Delhi', 'India', '2021-07-19'),
(4, 'David', 'Toronto', 'Canada', '2022-11-11'),
(5, 'Eva', 'Berlin', 'Germany', '2018-05-01');

INSERT INTO Sellers VALUES
(101, 'TechWorld', 'USA', 4.6),
(102, 'FashionHub', 'UK', 4.1),
(103, 'GadgetMart', 'India', 4.4),
(104, 'HomeStore', 'Canada', 3.9),
(105, 'BookZone', 'Germany', 4.8);

INSERT INTO Products VALUES
(201, 'Laptop', 'Electronics', 1200.00, 101),
(202, 'T-Shirt', 'Fashion', 25.00, 102),
(203, 'Smartphone', 'Electronics', 800.00, 103),
(204, 'Sofa', 'Home', 500.00, 104),
(205, 'Novel', 'Books', 15.00, 105);

INSERT INTO Orders VALUES
(301, 1, '2022-01-10', 'Completed'),
(302, 2, '2022-01-15', 'Completed'),
(303, 3, '2022-02-05', 'Cancelled'),
(304, 4, '2022-02-10', 'Completed'),
(305, 5, '2022-03-12', 'Completed'),
(306, 1, '2022-04-01', 'Completed'),
(307, 3, '2022-04-15', 'Completed'),
(308, 2, '2022-05-01', 'Completed'),
(309, 4, '2022-05-10', 'Completed'),
(310, 5, '2022-06-01', 'Completed');

INSERT INTO OrderDetails VALUES
(401, 301, 201, 1),
(402, 302, 202, 3),
(403, 303, 203, 1),
(404, 304, 204, 2),
(405, 305, 205, 4),
(406, 306, 201, 1),
(407, 307, 203, 2),
(408, 308, 202, 2),
(409, 309, 204, 1),
(410, 310, 205, 5);

INSERT INTO Payments VALUES
(501, 301, '2022-01-10', 'Credit Card', 1200.00),
(502, 302, '2022-01-15', 'PayPal', 75.00),
(503, 304, '2022-02-10', 'Credit Card', 1000.00),
(504, 305, '2022-03-12', 'NetBanking', 60.00),
(505, 306, '2022-04-01', 'Credit Card', 1200.00),
(506, 307, '2022-04-15', 'Credit Card', 1600.00),
(507, 308, '2022-05-01', 'PayPal', 50.00),
(508, 309, '2022-05-10', 'NetBanking', 500.00),
(509, 310, '2022-06-01', 'Credit Card', 75.00);

INSERT INTO Reviews VALUES
(601, 201, 1, 5, 'Excellent laptop', '2022-01-12'),
(602, 202, 2, 4, 'Nice quality T-shirt', '2022-01-16'),
(603, 203, 3, 2, 'Bad experience', '2022-02-06'),
(604, 204, 4, 5, 'Comfortable sofa', '2022-02-12'),
(605, 205, 5, 3, 'Average book', '2022-03-15'),
(606, 201, 1, 4, 'Good value', '2022-04-03'),
(607, 203, 3, 5, 'Improved service', '2022-04-16'),
(608, 202, 2, 5, 'Loved it', '2022-05-03'),
(609, 204, 4, 3, 'Delayed delivery', '2022-05-12'),
(610, 205, 5, 4, 'Great read', '2022-06-03');

SELECT * FROM Customers;
SELECT * FROM Sellers;
SELECT* FROM Products;
SELECT* FROM Orders;
SELECT* FROM OrderDetails;
SELECT* FROM Payments;
SELECT * FROM Reviews;

--Questions
--1) Find the top 3 customers by total spending.
SELECT TOP 3
    c.CustomerID,c.Name,c.City,c.Country,
    COUNT(DISTINCT o.OrderID) as [Order Count],
    ROUND(SUM(od.Quantity * pr.Price), 2) as [Total Spending]
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products pr ON od.ProductID = pr.ProductID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name, c.City, c.Country
ORDER BY [Total Spending] DESC;

--2) Calculate the total revenue by country.
SELECT
	c.Country,
	ROUND(SUM(p.Price*od.Quantity),2) as [Total Revenue]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
JOIN OrderDetails od ON o.OrderID=od.OrderID 
JOIN Products p ON p.ProductID =od.ProductID 
WHERE o.Status ='Completed'
GROUP BY c.Country 
ORDER BY [Total Revenue] DESC;

--3) Find the top-selling category by revenue.
SELECT TOP 1
	p.Category,
	ROUND(SUM(p.Price*od.Quantity),2) as [Total Revenue]
FROM Products p
JOIN OrderDetails od ON p.ProductID =od.ProductID 
JOIN Orders o On O.OrderID =OD.OrderID AND o.Status ='Completed'
GROUP BY P.Category 
ORDER BY [Total Revenue] DESC;

--4) List customers who have ordered from more than 2 different sellers.
SELECT
	c.CustomerID,c.Name,c.City,c.Country,
	COUNT(DISTINCT o.OrderID) as [Order Count],
	COUNT(DISTINCT p.SellerID) as [Unique Sellers]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID AND o.Status ='Completed'
JOIN OrderDetails od ON od.OrderID =o.OrderID 
JOIN Products p ON p.ProductID =od.ProductID 
GROUP BY c.CustomerID,c.Name,c.City,c.Country 
HAVING COUNT(DISTINCT p.SellerID)>2
ORDER BY [Unique Sellers] DESC;

--5) Identify sellers with average rating ≥ 4.5 and more than 2 products sold.
SELECT
    s.SellerID,s.Name as SellerName,s.Country,
    ROUND(AVG(r.Rating), 2) as [Average Customer Rating],
    COUNT(DISTINCT r.ReviewID) as [Number of Reviews],
    SUM(od.Quantity) as [Total Products Sold],
    COUNT(DISTINCT p.ProductID) as [Unique Products Listed]
FROM Sellers s
JOIN Products p ON s.SellerID = p.SellerID 
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID AND o.Status = 'Completed'
JOIN Reviews r ON p.ProductID = r.ProductID  -- Join with Reviews for actual ratings
GROUP BY s.SellerID, s.Name, s.Country
HAVING AVG(r.Rating) >= 4.5 AND SUM(od.Quantity) > 2
ORDER BY [Average Customer Rating] DESC, [Total Products Sold] DESC;

--6) Calculate the monthly revenue trend for the marketplace.
SELECT
    YEAR(o.OrderDate) as [Year],
    MONTH(o.OrderDate) as [Month],
    DATENAME(MONTH, o.OrderDate) as [Month Name],
    ROUND(SUM(p.Price * od.Quantity), 2) as [Total Revenue],
    COUNT(DISTINCT o.OrderID) as [Total Orders],
    COUNT(DISTINCT c.CustomerID) as [Unique Customers],
    ROUND(SUM(p.Price * od.Quantity) / COUNT(DISTINCT o.OrderID), 2) as [Average Order Value]
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.Status = 'Completed'
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
ORDER BY [Year], [Month];

--7) Find products that were ordered but never reviewed.
SELECT DISTINCT
    p.ProductID,p.Name as ProductName,p.Category,
    COUNT(DISTINCT o.OrderID) as TimesOrdered
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID AND o.Status = 'Completed'
LEFT JOIN Reviews r ON p.ProductID = r.ProductID
WHERE r.ReviewID IS NULL
GROUP BY p.ProductID, p.Name, p.Category
ORDER BY TimesOrdered DESC;

--8) Show the most loyal customer per seller (highest number of completed orders).
WITH CustomerLoyalty AS (
    SELECT
        s.SellerID,s.Name as SellerName,
        c.CustomerID,c.Name as CustomerName,c.Country as CustomerCountry,
        COUNT(DISTINCT o.OrderID) as TotalOrders,
        ROUND(SUM(p.Price * od.Quantity), 2) as TotalSpending,
        ROW_NUMBER() OVER (PARTITION BY s.SellerID ORDER BY COUNT(DISTINCT o.OrderID) DESC) as LoyaltyRank
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID AND o.Status = 'Completed'
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Sellers s ON p.SellerID = s.SellerID
    GROUP BY s.SellerID, s.Name, c.CustomerID, c.Name, c.Country
)
SELECT
    SellerID,SellerName,
    CustomerID,CustomerName,CustomerCountry,
    TotalOrders,TotalSpending
FROM CustomerLoyalty
WHERE LoyaltyRank = 1
ORDER BY TotalOrders DESC, TotalSpending DESC;

--9) Identify orders where payment amount does not match product * quantity.
SELECT
	o.OrderID,o.OrderDate,
	SUM(pa.Amount) as [Payment Amount],
	SUM(pr.Price*od.Quantity) as [Total Revenue]
FROM Products pr
JOIN OrderDetails od ON pr.ProductID =od.ProductID 
JOIN Orders o ON o.OrderID =od.OrderID  AND o.Status ='Completed'
JOIN Payments pa ON pa.OrderID =o.OrderID 
GROUP BY o.OrderID,o.OrderDate
HAVING SUM(pa.Amount) <> SUM(pr.Price*od.Quantity)
ORDER BY o.OrderID;

--10) Calculate year-over-year growth in completed orders.
WITH MonthlyMetrics AS (
    SELECT
        YEAR(o.OrderDate) as OrderYear,
        MONTH(o.OrderDate) as OrderMonth,
        DATENAME(MONTH, o.OrderDate) as MonthName,
        COUNT(DISTINCT o.OrderID) as CompletedOrders,
        LAG(COUNT(DISTINCT o.OrderID), 12) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)) as PreviousYearOrders
    FROM Orders o
    WHERE o.Status = 'Completed'
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
)
SELECT
    OrderYear,OrderMonth,MonthName,CompletedOrders,PreviousYearOrders,
    CASE 
        WHEN PreviousYearOrders IS NULL THEN NULL ELSE CompletedOrders - PreviousYearOrders END as OrderGrowth,
    CASE 
        WHEN PreviousYearOrders IS NULL THEN NULL
        WHEN PreviousYearOrders = 0 THEN NULL
        ELSE ROUND((CompletedOrders - PreviousYearOrders) * 100.0 / PreviousYearOrders, 2) END as GrowthPercentage
FROM MonthlyMetrics
WHERE OrderYear >= (SELECT MIN(YEAR(OrderDate)) FROM Orders WHERE Status = 'Completed') + 1
ORDER BY OrderYear, OrderMonth;

--11) Find the highest-rated product per category.
WITH ProductRatings AS (
    SELECT
        p.Category,p.ProductID,p.Name as ProductName,p.Price,
        ROUND(AVG(CAST(r.Rating AS DECIMAL(3,2))), 2) as AverageRating,
        COUNT(r.ReviewID) as ReviewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Category ORDER BY AVG(CAST(r.Rating AS DECIMAL(3,2))) DESC) as RankInCategory
    FROM Products p
    JOIN Reviews r ON p.ProductID = r.ProductID
    GROUP BY p.Category, p.ProductID, p.Name, p.Price
    HAVING COUNT(r.ReviewID) >= 1  -- Include products with at least 1 review
)
SELECT
    Category,ProductID,ProductName,Price,AverageRating,ReviewCount
FROM ProductRatings
WHERE RankInCategory = 1
ORDER BY Category, AverageRating DESC;

--12) Using RANK(), rank sellers by total revenue generated.
WITH SellersRevenue AS (
    SELECT
        s.SellerID,s.Name,s.Country,
        COUNT(DISTINCT o.OrderID) as [Total Orders],
        ROUND(SUM(p.Price * od.Quantity), 2) as [Total Revenue Generated],
        RANK() OVER (ORDER BY SUM(p.Price * od.Quantity) DESC) as RevenueRank
    FROM Sellers s
    JOIN Products p ON s.SellerID = p.SellerID 
    JOIN OrderDetails od ON p.ProductID = od.ProductID 
    JOIN Orders o ON o.OrderID = od.OrderID 
    WHERE o.Status = 'Completed'
    GROUP BY s.SellerID, s.Name, s.Country
)
SELECT
    SellerID,Name,Country,
    [Total Orders],[Total Revenue Generated],RevenueRank
FROM SellersRevenue 
ORDER BY RevenueRank; 

--13) Identify customers with consecutive purchases within 30 days.
WITH CustomerOrderSequences AS (
    SELECT
        c.CustomerID,c.Name as CustomerName,c.Country,
        o.OrderID,o.OrderDate,
        LAG(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) as PreviousOrderDate,
        DATEDIFF(day, LAG(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), o.OrderDate) as DaysBetweenOrders
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.Status = 'Completed'
)
SELECT
    CustomerID,CustomerName,Country,
    OrderID,OrderDate,
    PreviousOrderDate,DaysBetweenOrders
FROM CustomerOrderSequences
WHERE DaysBetweenOrders <= 30
ORDER BY CustomerID, OrderDate;

--14) Show the average delivery time per country (assume Delivery table exists, join with Orders).
SELECT
    c.Country,
    COUNT(o.OrderID) as TotalOrders,
    ROUND(AVG(CAST(DATEDIFF(day, o.OrderDate, p.PaymentDate) AS FLOAT)), 2) as AvgOrderToPaymentDays,
    ROUND(AVG(CAST(DATEDIFF(day, p.PaymentDate, GETDATE()) AS FLOAT)), 2) as AvgDaysSincePayment
FROM Orders o
JOIN Payments p ON o.OrderID = p.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.Status = 'Completed'
GROUP BY c.Country
ORDER BY AvgOrderToPaymentDays ASC;

--15) Find products returned/cancelled most often.
SELECT
    p.ProductID,p.Name as ProductName,p.Category,p.Price,
    COUNT(DISTINCT CASE WHEN o.Status = 'Cancelled' THEN o.OrderID END) as CancelledOrders,
    COUNT(DISTINCT o.OrderID) as TotalOrders,
    ROUND(COUNT(DISTINCT CASE WHEN o.Status = 'Cancelled' THEN o.OrderID END) * 100.0 / 
          COUNT(DISTINCT o.OrderID), 2) as CancellationRate
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID 
JOIN Orders o ON o.OrderID = od.OrderID
WHERE o.Status IN ('Cancelled', 'Completed')  -- Include both to calculate rate
GROUP BY p.ProductID, p.Name, p.Category, p.Price
HAVING COUNT(DISTINCT CASE WHEN o.Status = 'Cancelled' THEN o.OrderID END) > 0
ORDER BY CancelledOrders DESC, CancellationRate DESC;

--16) Calculate the running total of revenue per customer using a window function.
SELECT
    c.CustomerID, c.Name as CustomerName,c.Country,o.OrderID,o.OrderDate,
    ROUND(SUM(p.Price * od.Quantity), 2) as OrderRevenue,
    ROUND(SUM(SUM(p.Price * od.Quantity)) 
	OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) as RunningTotalRevenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name, c.Country, o.OrderID, o.OrderDate
ORDER BY c.CustomerID, o.OrderDate, o.OrderID;

--17) Identify customers who have spent above the overall average spending.
WITH CustomerSpending AS (
    SELECT
        c.CustomerID,c.Name as CustomerName,c.Country,c.JoinDate,
        COUNT(DISTINCT o.OrderID) as TotalOrders,
        ROUND(SUM(p.Price * od.Quantity), 2) as TotalSpent
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.Country, c.JoinDate
),
OverallAverage AS (
    SELECT AVG(TotalSpent) as AvgSpending
    FROM CustomerSpending
)
SELECT
    cs.CustomerID,cs.CustomerName,cs.Country,cs.JoinDate,cs.TotalOrders,cs.TotalSpent,
    oa.AvgSpending as OverallAverageSpending,
    ROUND((cs.TotalSpent - oa.AvgSpending), 2) as AboveAverageBy,
    ROUND((cs.TotalSpent - oa.AvgSpending) * 100.0 / oa.AvgSpending, 2) as PercentageAboveAverage
FROM CustomerSpending cs
CROSS JOIN OverallAverage oa
WHERE cs.TotalSpent > oa.AvgSpending
ORDER BY cs.TotalSpent DESC;

--18) Detect at-risk sellers: Avg rating < 4, AND At least 1 order cancelled.
SELECT
    s.SellerID,s.Name as SellerName,s.Country,s.Rating as PlatformRating,
    ROUND(AVG(r.Rating), 2) as AvgCustomerRating,
    COUNT(DISTINCT CASE WHEN o.Status = 'Cancelled' THEN o.OrderID END) as CancelledOrderCount,
    COUNT(DISTINCT o.OrderID) as TotalOrders,
    ROUND(COUNT(DISTINCT CASE WHEN o.Status = 'Cancelled' THEN o.OrderID END) * 100.0 / 
          COUNT(DISTINCT o.OrderID), 2) as CancellationRate
FROM Sellers s
JOIN Products p ON s.SellerID = p.SellerID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Reviews r ON p.ProductID = r.ProductID  -- Reviews for seller's products
WHERE o.Status IN ('Completed', 'Cancelled')  -- Include both to calculate rate
GROUP BY s.SellerID, s.Name, s.Country, s.Rating
HAVING AVG(r.Rating) < 4 
   AND COUNT(DISTINCT CASE WHEN o.Status = 'Cancelled' THEN o.OrderID END) >= 1
ORDER BY AvgCustomerRating ASC, CancellationRate DESC;

--19) Find the median rating per product (hint: use window functions).
SELECT
    p.ProductID,p.Name as ProductName,p.Category,p.Price,
    COUNT(r.ReviewID) as ReviewCount,
    ROUND(AVG(CAST(r.Rating AS FLOAT)), 2) as AverageRating,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.Rating) OVER (PARTITION BY p.ProductID) as MedianRating
FROM Products p
LEFT JOIN Reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.Name, p.Category, p.Price, r.Rating
HAVING COUNT(r.ReviewID) >= 1  -- Only products with reviews
ORDER BY MedianRating DESC, ReviewCount DESC;

--20) List all customers who never left a review despite having completed orders.
SELECT
    c.CustomerID,c.Name as CustomerName,c.Country,c.JoinDate,
    COUNT(DISTINCT o.OrderID) as CompletedOrders,
    ROUND(SUM(p.Price * od.Quantity), 2) as TotalSpent,
    MAX(o.OrderDate) as LastOrderDate
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.Status = 'Completed'
    AND c.CustomerID NOT IN (
        SELECT DISTINCT CustomerID FROM Reviews)
GROUP BY c.CustomerID, c.Name, c.Country, c.JoinDate
ORDER BY TotalSpent DESC, CompletedOrders DESC;


--Bonus (Optimization Discussion):
--21) How would you optimize queries for:
--Top customers by spending
--Detecting fraud (payment mismatch)
--Running totals (indexes, partitioning, covering indexes)

--1) Top Customers by Spending Optimization
--Original Query:
SELECT TOP 10 c.CustomerID, c.Name, SUM(p.Price * od.Quantity) as TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.Name
ORDER BY TotalSpent DESC;

--Optimization Strategies:

--A. Indexing Strategy:
-- Critical indexes for performance
CREATE INDEX IX_Orders_CustomerStatusDate ON Orders(CustomerID, Status, OrderDate);
CREATE INDEX IX_OrderDetails_OrderProductQty ON OrderDetails(OrderID, ProductID, Quantity);
CREATE INDEX IX_Products_ProductPrice ON Products(ProductID, Price);
CREATE INDEX IX_Customers_CustomerIDName ON Customers(CustomerID, Name);

-- Covering index for the specific query
CREATE INDEX IX_Orders_Completed_Covering ON Orders(CustomerID, OrderID) 
INCLUDE (Status) WHERE Status = 'Completed';

--B. Materialized View for Frequent Queries:
-- Pre-aggregated customer spending summary
CREATE TABLE CustomerSpendingSummary (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    TotalSpent DECIMAL(15,2),
    LastOrderDate DATE,
    OrderCount INT,
    LastUpdated DATETIME DEFAULT GETDATE()
);

-- Refresh strategy (daily/hourly)
CREATE PROCEDURE RefreshCustomerSpending
AS
BEGIN
    MERGE CustomerSpendingSummary AS target
    USING (
        SELECT c.CustomerID, c.Name, 
               SUM(p.Price * od.Quantity) as TotalSpent,
               MAX(o.OrderDate) as LastOrderDate,
               COUNT(DISTINCT o.OrderID) as OrderCount
        FROM Customers c
        JOIN Orders o ON c.CustomerID = o.CustomerID
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        JOIN Products p ON od.ProductID = p.ProductID
        WHERE o.Status = 'Completed'
        GROUP BY c.CustomerID, c.Name
    ) AS source
    ON target.CustomerID = source.CustomerID
    WHEN MATCHED THEN
        UPDATE SET TotalSpent = source.TotalSpent,
                   LastOrderDate = source.LastOrderDate,
                   OrderCount = source.OrderCount,
                   LastUpdated = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (CustomerID, CustomerName, TotalSpent, LastOrderDate, OrderCount)
        VALUES (source.CustomerID, source.CustomerName, source.TotalSpent, 
                source.LastOrderDate, source.OrderCount);
END;

--C. Optimized Query with Hints:
SELECT TOP 10 
    CustomerID, CustomerName, TotalSpent
FROM CustomerSpendingSummary WITH (READUNCOMMITTED)
ORDER BY TotalSpent DESC;

--2. Fraud Detection (Payment Mismatch) Optimization
--Original Query:
SELECT o.OrderID, SUM(pa.Amount) as Paid, SUM(p.Price * od.Quantity) as Expected
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Payments pa ON o.OrderID = pa.OrderID
WHERE o.Status = 'Completed'
GROUP BY o.OrderID
HAVING SUM(pa.Amount) != SUM(p.Price * od.Quantity);

--Optimization Strategies:

--A. Specialized Indexes:
-- Composite indexes for join performance
CREATE INDEX IX_Orders_Status_OrderID ON Orders(Status, OrderID);
CREATE INDEX IX_OrderDetails_OrderID_ProductID_Qty ON OrderDetails(OrderID, ProductID, Quantity);
CREATE INDEX IX_Payments_OrderID_Amount ON Payments(OrderID, Amount);
CREATE INDEX IX_Products_ProductID_Price ON Products(ProductID, Price);

-- Filtered index for completed orders only
CREATE INDEX IX_Orders_Completed_Filtered ON Orders(OrderID) 
WHERE Status = 'Completed';

--B. Pre-calculated Order Totals:
-- Add computed column to Orders table
ALTER TABLE Orders ADD CalculatedTotal AS (
    SELECT COALESCE(SUM(p.Price * od.Quantity), 0)
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE od.OrderID = Orders.OrderID
);

-- Add index on computed column
CREATE INDEX IX_Orders_CalculatedTotal ON Orders(CalculatedTotal) 
WHERE Status = 'Completed';

--C. Optimized Fraud Detection Query:
-- Batch processing for large datasets
WITH OrderTotals AS (
    SELECT 
        o.OrderID,
        SUM(p.Price * od.Quantity) as ExpectedAmount,
        (SELECT SUM(Amount) FROM Payments WHERE OrderID = o.OrderID) as PaidAmount
    FROM Orders o WITH (INDEX(IX_Orders_Completed_Filtered))
    JOIN OrderDetails od WITH (FORCESEEK) ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.Status = 'Completed'
        AND o.OrderDate >= DATEADD(DAY, -30, GETDATE()) -- Recent orders only
    GROUP BY o.OrderID
)
SELECT OrderID, ExpectedAmount, PaidAmount, ABS(ExpectedAmount - PaidAmount) as Difference
FROM OrderTotals
WHERE ABS(ExpectedAmount - PaidAmount) > 0.01  -- Tolerance for rounding
OPTION (RECOMPILE); -- Fresh execution plan for parameter-sensitive query

--D. Real-time Fraud Monitoring:
-- Trigger-based fraud detection (for immediate alerts)
CREATE TRIGGER trg_FraudDetection ON Payments AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT i.OrderID, 
           'Payment mismatch detected: ' + 
           CAST(inserted.Amount AS VARCHAR) + ' vs ' + 
           CAST(o.CalculatedTotal AS VARCHAR) as AlertMessage
    FROM inserted
    JOIN Orders o ON inserted.OrderID = o.OrderID
    WHERE ABS(inserted.Amount - o.CalculatedTotal) > 0.01
      AND o.Status = 'Completed';
END;

--3. Running Totals Optimization
--Original Query:
SELECT CustomerID, OrderDate, OrderAmount,
       SUM(OrderAmount) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as RunningTotal
FROM Orders;

--Optimization Strategies:

--A. Indexing for Window Functions:
-- Critical for window function performance
CREATE INDEX IX_Orders_CustomerID_OrderDate_Amount 
ON Orders(CustomerID, OrderDate) INCLUDE (TotalAmount);

-- Partition-friendly indexing
CREATE INDEX IX_Orders_OrderDate_CustomerID 
ON Orders(OrderDate, CustomerID) INCLUDE (TotalAmount);

--B. Batch Processing for Large Datasets:
-- Process in chunks to avoid memory pressure
DECLARE @PageSize INT = 10000, @PageNumber INT = 0;

WHILE (1 = 1)
BEGIN
    WITH PaginatedOrders AS (
        SELECT CustomerID, OrderDate, TotalAmount,
               ROW_NUMBER() OVER (ORDER BY CustomerID, OrderDate) as RowNum
        FROM Orders
        WHERE OrderDate >= '2023-01-01'
    ),
    RunningTotals AS (
        SELECT CustomerID, OrderDate, TotalAmount,
               SUM(TotalAmount) OVER (
                   PARTITION BY CustomerID 
                   ORDER BY OrderDate 
                   ROWS UNBOUNDED PRECEDING
               ) as RunningTotal
        FROM PaginatedOrders
        WHERE RowNum BETWEEN (@PageNumber * @PageSize) + 1 
                         AND (@PageNumber + 1) * @PageSize
    )
    SELECT * FROM RunningTotals
    OPTION (MAXDOP 4); -- Limit parallelism
    
    IF @@ROWCOUNT < @PageSize BREAK;
    SET @PageNumber += 1;
END;

--C. Materialized Running Totals:
-- Pre-calculated running totals table
CREATE TABLE CustomerRunningTotals (
    CustomerID INT,
    OrderDate DATE,
    OrderAmount DECIMAL(15,2),
    RunningTotal DECIMAL(15,2),
    PRIMARY KEY (CustomerID, OrderDate)
);

-- Incremental update procedure
CREATE PROCEDURE UpdateRunningTotals @CutoffDate DATE
AS
BEGIN
    WITH NewTotals AS (
        SELECT o.CustomerID, o.OrderDate, o.TotalAmount,
               o.TotalAmount + COALESCE(
                   (SELECT MAX(RunningTotal) 
                    FROM CustomerRunningTotals crt 
                    WHERE crt.CustomerID = o.CustomerID 
                      AND crt.OrderDate < o.OrderDate), 0
               ) as RunningTotal
        FROM Orders o
        WHERE o.OrderDate >= @CutoffDate
    )
    MERGE CustomerRunningTotals AS target
    USING NewTotals AS source
    ON target.CustomerID = source.CustomerID AND target.OrderDate = source.OrderDate
    WHEN MATCHED THEN UPDATE SET 
        OrderAmount = source.OrderAmount,
        RunningTotal = source.RunningTotal
    WHEN NOT MATCHED THEN INSERT 
        (CustomerID, OrderDate, OrderAmount, RunningTotal)
        VALUES (source.CustomerID, source.OrderDate, source.OrderAmount, source.RunningTotal);
END;

--D. Optimized Running Total Query:
-- Use APPROX_COUNT_DISTINCT for large datasets (SQL Server 2016+)
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as RunningTotal
FROM Orders WITH (INDEX(IX_Orders_CustomerID_OrderDate_Amount))
WHERE OrderDate >= DATEADD(MONTH, -12, GETDATE()) -- Limit data range
OPTION (
    MAXDOP 4,                      -- Control parallelism
    OPTIMIZE FOR (@CustomerID = 1) -- Parameter sniffing fix
);

--General Optimization Best Practices:
--1. Indexing Strategy:
-- Composite indexes for specific query patterns
CREATE INDEX IX_Covering_TopCustomers ON Orders(CustomerID, Status)
INCLUDE (OrderDate, TotalAmount);

-- Filtered indexes for common WHERE conditions
CREATE INDEX IX_Orders_RecentCompleted ON Orders(OrderDate)
INCLUDE (CustomerID, TotalAmount)
WHERE Status = 'Completed' AND OrderDate >= '2023-01-01';

-- Columnstore for analytical queries
CREATE CLUSTERED COLUMNSTORE INDEX CCI_OrderDetails 
ON OrderDetails;

--2. Query Hints and Options:
-- Use appropriate hints
SELECT * FROM Orders WITH (NOLOCK) WHERE Status = 'Completed';

-- Force specific join types
SELECT * FROM Orders o
INNER HASH JOIN OrderDetails od ON o.OrderID = od.OrderID;

-- Control memory grants
SELECT * FROM LargeTable
OPTION (MIN_GRANT_PERCENT = 10, MAX_GRANT_PERCENT = 50);

--3. Partitioning Strategy:
-- Partition by date for time-series data
CREATE PARTITION FUNCTION OrderDateRange (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2023-07-01', '2024-01-01');

CREATE PARTITION SCHEME OrderDateScheme
AS PARTITION OrderDateRange ALL TO ([PRIMARY]);

--4. Monitoring and Maintenance:
-- Regular index maintenance
ALTER INDEX ALL ON Orders REORGANIZE;

-- Update statistics with full scan
UPDATE STATISTICS Orders WITH FULLSCAN;

-- Monitor query performance
SELECT 
    qs.execution_count,
    qs.total_worker_time/qs.execution_count as avg_cpu_time,
    qs.total_elapsed_time/qs.execution_count as avg_duration,
    qs.total_logical_reads/qs.execution_count as avg_logical_reads
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%YourQueryPattern%';