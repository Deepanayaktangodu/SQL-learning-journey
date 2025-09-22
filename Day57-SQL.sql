CREATE TABLE Customers (
							CustomerID INT PRIMARY KEY,
							Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
							Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
							JoinDate DATE NOT NULL DEFAULT GETDATE()
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderDate DATE NOT NULL,
						TotalAmount DECIMAL(10,2)  NOT NULL CHECK(TotalAmount>=0),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Cancelled')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE
					);

CREATE TABLE Shipments (
							ShipmentID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							ShippedDate DATE NOT NULL,
							ExpectedDelivery DATE NOT NULL ,
							ActualDelivery DATE NULL,
							CHECK (ExpectedDelivery > ShippedDate),
							FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE
						);

CREATE TABLE Feedback (
						FeedbackID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						OrderID INT NOT NULL,
						Rating INT NOT NULL CHECK(Rating BETWEEN 1 AND 5),
						Comment VARCHAR(255) NOT NULL,
						UNIQUE (CustomerID, OrderID),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE NO ACTION ON DELETE NO ACTION,
						FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE NO ACTION ON DELETE NO ACTION
						);


Create Index Idx_Customers_Name on Customers(Name);
Create Index Idx_Customers_Country on Customers(Country);
Create Index Idx_Orders_Status on Orders(Status);
Create Index Idx_Orders_TotalAmount on Orders(TotalAmount);
Create Index Idx_Orders_CustomerID on Orders(CustomerID);
Create Index Idx_Shipments_OrderID on Shipments(OrderID);
Create Index Idx_Feedback_CustomerID on Feedback(CustomerID);
Create Index Idx_Feedback_OrderID on Feedback(OrderID);
CREATE INDEX Idx_Orders_CustomerID_Status ON Orders(CustomerID, Status);
CREATE INDEX Idx_Orders_OrderDate_Status ON Orders(OrderDate, Status);
CREATE INDEX Idx_Shipments_Dates ON Shipments(ShippedDate, ExpectedDelivery, ActualDelivery);

INSERT INTO Customers VALUES
(1, 'Alice', 'USA', '2020-01-15'),
(2, 'Bob', 'India', '2019-05-10'),
(3, 'Charlie', 'UK', '2021-03-25'),
(4, 'David', 'Canada', '2022-07-18'),
(5, 'Eva', 'Germany', '2020-12-01');

INSERT INTO Orders VALUES
(101, 1, '2022-01-10', 200.00, 'Completed'),
(102, 2, '2022-02-15', 150.00, 'Completed'),
(103, 3, '2022-03-05', 400.00, 'Cancelled'),
(104, 4, '2022-04-20', 120.00, 'Completed'),
(105, 5, '2022-05-25', 300.00, 'Completed'),
(106, 1, '2022-06-15', 250.00, 'Completed');

INSERT INTO Shipments VALUES
(201, 101, '2022-01-12', '2022-01-17', '2022-01-16'),
(202, 102, '2022-02-17', '2022-02-22', '2022-02-25'),
(203, 103, '2022-03-07', '2022-03-12', NULL),
(204, 104, '2022-04-22', '2022-04-27', '2022-04-26'),
(205, 105, '2022-05-27', '2022-06-01', '2022-06-03'),
(206, 106, '2022-06-17', '2022-06-22', '2022-06-20');

INSERT INTO Feedback VALUES
(301, 1, 101, 5, 'Fast delivery, very satisfied'),
(302, 2, 102, 3, 'Late delivery'),
(303, 4, 104, 4, 'Good service'),
(304, 5, 105, 2, 'Very late delivery'),
(305, 1, 106, 5, 'Excellent experience');

SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM Shipments;
SELECT * FROM Feedback;

--1) Find the average delivery delay (days difference between ActualDelivery and ExpectedDelivery).
SELECT
    ShipmentID,ExpectedDelivery,ActualDelivery,
    DATEDIFF(DAY, ExpectedDelivery, ActualDelivery) as DeliveryDelayDays
FROM Shipments 
WHERE ActualDelivery IS NOT NULL
ORDER BY DeliveryDelayDays DESC;

--2) Identify the top 3 customers by total spending.
SELECT TOP 3
	c.CustomerID,c.Name,c.Country,
	SUM(o.TotalAmount) as [Total Spending]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
WHERE O.Status ='Completed'
GROUP BY c.CustomerID,c.Name,c.Country 
ORDER BY [Total Spending] DESC;

--3) Calculate the percentage of late deliveries per country.
WITH DeliveryStats AS (
			SELECT
				c.Country,
				COUNT(*) as TotalDeliveries,
				SUM(CASE WHEN s.ActualDelivery>s.ExpectedDelivery THEN 1 ELSE 0 END) AS LateDeliveries
			FROM Customers c
			JOIN Orders o ON c.CustomerID =o.CustomerID 
			JOIN Shipments s ON s.OrderID  =o.OrderID 
			WHERE s.ActualDelivery  IS NOT NULL AND o.Status ='Completed'
			GROUP BY c.Country)
SELECT
	Country,TotalDeliveries,LateDeliveries,
	ROUND(CAST(LateDeliveries AS decimal)/NULLIF(TotalDeliveries,0)*100,2) AS LateDeliveryPercentage
FROM DeliveryStats 
ORDER BY LateDeliveryPercentage DESC;

--4) List orders where the shipment was never delivered (ActualDelivery IS NULL).
SELECT
    o.OrderID,o.OrderDate,o.TotalAmount,o.Status,
    s.ShipmentID,s.ShippedDate,s.ExpectedDelivery
FROM Orders o
LEFT JOIN Shipments s ON o.OrderID = s.OrderID 
WHERE s.ActualDelivery IS NULL
AND s.ShipmentID IS NOT NULL; 

--5) Find customers who have given more than 1 feedback.
SELECT
	c.CustomerID,c.Name,c.Country,
	COUNT(DISTINCT f.FeedBackID) as [Feedback Count]
FROM Customers c
JOIN Feedback f ON c.CustomerID =f.CustomerID 
GROUP BY c.CustomerID,c.Name,c.Country 
HAVING COUNT(DISTINCT f.FeedBackID)>1
ORDER BY [Feedback Count] DESC;

--6) Using a window function, calculate the running total of spend per customer.
SELECT
	c.CustomerID,c.Name,c.Country,
	o.OrderID,o.OrderDate,o.TotalAmount,
	SUM(o.TotalAmount) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate,o.OrderID) AS RunningTotal
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
WHERE o.Status ='Completed'
ORDER BY c.CustomerID, o.OrderDate, o.OrderID;

--7) Identify the most frequent delivery delay (mode in days) across all shipments.
WITH DelayCounts AS (
    SELECT
        DATEDIFF(DAY, ExpectedDelivery, ActualDelivery) as DeliveryDelayDays,
        COUNT(*) as Frequency
    FROM Shipments 
    WHERE ActualDelivery IS NOT NULL
    GROUP BY DATEDIFF(DAY, ExpectedDelivery, ActualDelivery)
)
SELECT TOP 1
    DeliveryDelayDays,Frequency
FROM DelayCounts
ORDER BY Frequency DESC, DeliveryDelayDays DESC;

--8) Find the correlation between rating and delivery delays (average delay by rating).
SELECT
    f.Rating,
    COUNT(f.FeedbackID) as NumberOfFeedbacks,
    AVG(CAST(DATEDIFF(DAY, s.ExpectedDelivery, s.ActualDelivery) AS DECIMAL(10,2))) as AverageDelayDays,
    MIN(DATEDIFF(DAY, s.ExpectedDelivery, s.ActualDelivery)) as MinDelayDays,
    MAX(DATEDIFF(DAY, s.ExpectedDelivery, s.ActualDelivery)) as MaxDelayDays
FROM Feedback f
JOIN Orders o ON f.OrderID = o.OrderID
JOIN Shipments s ON o.OrderID = s.OrderID
WHERE s.ActualDelivery IS NOT NULL AND o.Status = 'Completed'
GROUP BY f.Rating
ORDER BY f.Rating;

--9) Show customers who placed consecutive orders within 30 days.
WITH OrderedOrders AS (
    SELECT
        o.CustomerID,c.Name,c.Country,
        o.OrderID,o.OrderDate,o.TotalAmount,
        LAG(o.OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) as PreviousOrderDate,
        DATEDIFF(DAY, LAG(o.OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate),o.OrderDate) as DaysSinceLastOrder
    FROM Orders o
    JOIN Customers c ON o.CustomerID = c.CustomerID
    WHERE o.Status = 'Completed'
)
SELECT
    CustomerID,Name,Country,
    OrderID,OrderDate,TotalAmount,
    PreviousOrderDate,DaysSinceLastOrder
FROM OrderedOrders
WHERE DaysSinceLastOrder <= 30
ORDER BY CustomerID, OrderDate;

--10) Find the order with the maximum delay and show customer details.	
SELECT TOP 1
    c.CustomerID,c.Name,c.Country,
    o.OrderID,o.OrderDate,o.TotalAmount,
    s.ExpectedDelivery,s.ActualDelivery,
    DATEDIFF(DAY, s.ExpectedDelivery, s.ActualDelivery) as MaximumDelay
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID 
JOIN Shipments s ON o.OrderID = s.OrderID 
WHERE o.Status = 'Completed'
AND s.ActualDelivery IS NOT NULL
ORDER BY DATEDIFF(DAY, s.ExpectedDelivery, s.ActualDelivery) DESC;

--11) Detect at-risk customers: Customers who had
--≥ 2 late deliveries, AND Average rating ≤ 3.
WITH CustomerMetrics AS (
    SELECT
        c.CustomerID,c.Name,c.Country,c.JoinDate,
        -- Late delivery metrics
        COUNT(CASE WHEN s.ActualDelivery > s.ExpectedDelivery THEN 1 END) as LateDeliveries,
        COUNT(s.ShipmentID) as TotalDeliveries,
        -- Rating metrics
        AVG(CAST(f.Rating AS DECIMAL(3,2))) as AverageRating,
        COUNT(f.FeedbackID) as TotalFeedbacks,
        -- Additional risk indicators
        MAX(DATEDIFF(DAY, s.ExpectedDelivery, s.ActualDelivery)) as MaxDelayDays,
        MIN(f.Rating) as MinRating
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID AND o.Status = 'Completed'
    LEFT JOIN Shipments s ON o.OrderID = s.OrderID AND s.ActualDelivery IS NOT NULL
    LEFT JOIN Feedback f ON o.OrderID = f.OrderID
    GROUP BY c.CustomerID, c.Name, c.Country, c.JoinDate
)
SELECT
    CustomerID,Name,Country,
    JoinDate,LateDeliveries,TotalDeliveries,
    CAST(LateDeliveries * 100.0 / NULLIF(TotalDeliveries, 0) AS DECIMAL(5,2)) as LateDeliveryPercentage,
    AverageRating,TotalFeedbacks,MaxDelayDays,
    CASE 
        WHEN LateDeliveries >= 2 AND AverageRating <= 3 THEN 'High Risk'
        WHEN LateDeliveries >= 2 AND AverageRating <= 4 THEN 'Medium Risk'
        WHEN LateDeliveries >= 1 AND AverageRating <= 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as RiskLevel
FROM CustomerMetrics
WHERE LateDeliveries >= 2 AND AverageRating <= 3
ORDER BY LateDeliveries DESC, AverageRating ASC;


