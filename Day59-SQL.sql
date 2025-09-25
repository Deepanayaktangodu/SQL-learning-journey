CREATE TABLE Customers (
						CustomerID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						City VARCHAR(50) NOT NULL CHECK(LEN(City)>=2),
						JoinDate DATE NOT NULL CHECK(JoinDate<=GETDATE())
						);

CREATE TABLE Restaurants (
							RestaurantID INT PRIMARY KEY,
							Name VARCHAR(100) NOT NULL,
							City VARCHAR(50) NOT NULL CHECK(LEN(City)>=2),
							Cuisine VARCHAR(50) NOT NULL CHECK(LEN(Cuisine)>=2) ,
							Rating DECIMAL(3,2) NULL Check(Rating>=0),
							UNIQUE (Name, City)
						);

CREATE TABLE Orders (
						OrderID INT PRIMARY KEY,
						CustomerID INT NOT NULL,
						RestaurantID INT NOT NULL,
						OrderDate DATE NOT NULL DEFAULT GETDATE() CHECK (OrderDate <= GETDATE()),
						Amount DECIMAL(10,2) NOT NULL CHECK(Amount>0),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Cancelled')),
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON UPDATE CASCADE ON DELETE CASCADE,
						FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

CREATE TABLE Delivery (
						DeliveryID INT PRIMARY KEY,
						OrderID INT NOT NULL,
						DeliveryDate DATE NOT NULL DEFAULT GETDATE(),
						DeliveryTimeMins INT NULL CHECK(DeliveryTimeMins>=0),
						DeliveryStatus VARCHAR(20) NOT NULL CHECK(DeliveryStatus in ('Delivered','Not Delivered')),
						FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE
					);

CREATE TABLE Ratings (
						RatingID INT PRIMARY KEY,
						OrderID INT NOT NULL UNIQUE,
						CustomerID INT NOT NULL,
						RestaurantID INT NOT NULL,
						Rating INT NOT NULL CHECK(Rating BETWEEN 1 AND 5),
						FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE NO ACTION,
						FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
						FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID)
					);

Create Index Idx_Customers_Name ON Customers(Name);
Create Index Idx_Customers_City ON Customers(City);
Create Index Idx_Customers_JoinDate ON Customers(JoinDate);
Create Index Idx_Restaurants_Name ON Restaurants(Name);
Create Index Idx_Restaurants_City ON Restaurants(City);
Create Index Idx_Restaurants_Cuisine ON Restaurants(Cuisine);
Create Index Idx_Restaurants_Rating ON Restaurants(Rating);
Create Index Idx_Orders_OrederDate ON Orders(OrderDate);
Create Index Idx_Orders_Amount ON Orders(Amount);
Create Index Idx_Orders_Status ON Orders(Status);
Create Index Idx_Orders_CustomerID ON Orders(CustomerID);
Create Index Idx_Orders_RestaurantID ON  Orders(RestaurantID);
Create Index Idx_Delivery_DeliveryDate ON Delivery(DeliveryDate);
Create Index Idx_Delivery_DeliveryTimeMins ON Delivery(DeliveryTimeMins);
Create Index Idx_Delivery_DeliveryStatus ON Delivery(DeliveryStatus);
Create Index Idx_Delivery_OrderID ON Delivery(OrderID);
Create Index Idx_Ratings_Rating ON Ratings(Rating);
Create Index Idx_Ratings_OrderID ON Ratings(OrderID);
Create Index Idx_Ratings_CustomerID ON Ratings(CustomerID);
Create Index Idx_Ratings_RestaurantID ON Ratings(RestaurantID);
CREATE INDEX Idx_Restaurants_City_Cuisine_Rating ON Restaurants(City, Cuisine, Rating);
CREATE INDEX Idx_Orders_CustomerID_OrderDate ON Orders(CustomerID, OrderDate);
CREATE INDEX Idx_Orders_RestaurantID_OrderDate ON Orders(RestaurantID, OrderDate);

INSERT INTO Customers VALUES
(1, 'Alice', 'New York', '2021-01-15'),
(2, 'Bob', 'London', '2020-06-10'),
(3, 'Charlie', 'Delhi', '2019-03-25'),
(4, 'David', 'Toronto', '2022-07-18'),
(5, 'Eva', 'Berlin', '2020-12-01');

INSERT INTO Restaurants VALUES
(101, 'Pizza Palace', 'New York', 'Italian', 4.5),
(102, 'Curry House', 'London', 'Indian', 4.2),
(103, 'Noodle Bar', 'Delhi', 'Chinese', 4.0),
(104, 'Burger Hub', 'Toronto', 'American', 3.8),
(105, 'Sushi Spot', 'Berlin', 'Japanese', 4.7);

INSERT INTO Orders VALUES
(201, 1, 101, '2022-01-10', 50.00, 'Completed'),
(202, 2, 102, '2022-01-15', 30.00, 'Completed'),
(203, 3, 103, '2022-02-05', 25.00, 'Cancelled'),
(204, 4, 104, '2022-02-10', 45.00, 'Completed'),
(205, 5, 105, '2022-03-12', 60.00, 'Completed'),
(206, 1, 101, '2022-04-01', 70.00, 'Completed'),
(207, 3, 103, '2022-04-15', 35.00, 'Completed'),
(208, 2, 102, '2022-05-01', 40.00, 'Completed'),
(209, 4, 104, '2022-05-10', 55.00, 'Completed'),
(210, 5, 105, '2022-06-01', 65.00, 'Completed');

INSERT INTO Delivery VALUES
(301, 201, '2022-01-10', 35, 'Delivered'),
(302, 202, '2022-01-15', 40, 'Delivered'),
(303, 203, '2022-02-05', NULL, 'Not Delivered'),
(304, 204, '2022-02-10', 50, 'Delivered'),
(305, 205, '2022-03-12', 30, 'Delivered'),
(306, 206, '2022-04-01', 60, 'Delivered'),
(307, 207, '2022-04-15', 55, 'Delivered'),
(308, 208, '2022-05-01', 45, 'Delivered'),
(309, 209, '2022-05-10', 50, 'Delivered'),
(310, 210, '2022-06-01', 40, 'Delivered');

INSERT INTO Ratings VALUES
(401, 201, 1, 101, 5),
(402, 202, 2, 102, 4),
(403, 204, 4, 104, 3),
(404, 205, 5, 105, 5),
(405, 206, 1, 101, 4),
(406, 207, 3, 103, 4),
(407, 208, 2, 102, 5),
(408, 209, 4, 104, 3),
(409, 210, 5, 105, 5);

SELECT * FROM Customers; 
SELECT * FROM Restaurants;
SELECT * FROM Orders;
SELECT * FROM Delivery;
SELECT * FROM Ratings; 

--1) Find the top 3 restaurants by revenue.
SELECT TOP 3
	r.RestaurantID,r.Name,r.City,r.Rating,
	COUNT(o.OrderID) as [Total Orders],
	ROUND(SUM(o.Amount),2) as [Total Revenue]	
FROM Restaurants r
JOIN Orders o ON r.RestaurantID =o.RestaurantID AND o.Status ='Completed'
GROUP BY r.RestaurantID,r.Name,r.City,r.Rating 
ORDER BY [Total Revenue] DESC;

--2) Identify customers who have ordered from more than 1 cuisine type.
SELECT
	c.CustomerID,c.Name,c.City,
	COUNT(DISTINCT r.Cuisine) as [Unique Cuisine Count],
	STRING_AGG(r.Cuisine,',') as [Cuisine Name],
	COUNT(o.OrderID) as [Total Orders]
FROM Customers c
JOIN Orders o ON c.CustomerID =o.CustomerID 
JOIN Restaurants r ON o.RestaurantID =r.RestaurantID 
GROUP BY c.CustomerID,c.Name,c.City 
HAVING COUNT(DISTINCT r.Cuisine)>1
ORDER BY [Unique Cuisine Count] DESC;

--3) Calculate the average delivery time by city and rank them.
SELECT
    r.City,
    ROUND(AVG(d.DeliveryTimeMins), 2) AS [Average Delivery Time],
    RANK() OVER (ORDER BY AVG(d.DeliveryTimeMins) ASC) AS FastestRank,  -- Rank by speed (fastest first)
    DENSE_RANK() OVER (ORDER BY AVG(d.DeliveryTimeMins) DESC) AS SlowestRank  -- Rank by slowness
FROM Restaurants r 
JOIN Orders o ON r.RestaurantID = o.RestaurantID 
JOIN Delivery d ON d.OrderID = o.OrderID 
WHERE o.Status = 'Completed' 
    AND d.DeliveryStatus = 'Delivered' 
    AND d.DeliveryTimeMins IS NOT NULL 
GROUP BY r.City 
ORDER BY [Average Delivery Time] ASC;

--4) Find the most loyal customers (highest number of completed orders per restaurant).
WITH RestaurantLoyalty AS (
    SELECT
        r.RestaurantID,r.Name AS RestaurantName,r.City AS RestaurantCity,
        c.CustomerID,c.Name AS CustomerName,
        COUNT(o.OrderID) as TotalOrdersCompleted,
        SUM(o.Amount) as TotalAmountSpent,
        ROW_NUMBER() OVER (PARTITION BY r.RestaurantID ORDER BY COUNT(o.OrderID) DESC, SUM(o.Amount) DESC) AS LoyaltyRank
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID 
    JOIN Restaurants r ON r.RestaurantID = o.RestaurantID 
    WHERE o.Status = 'Completed'
    GROUP BY r.RestaurantID, r.Name, r.City, c.CustomerID, c.Name
)
SELECT
    RestaurantID,RestaurantName,RestaurantCity,
    CustomerID,CustomerName,
    TotalOrdersCompleted,TotalAmountSpent
FROM RestaurantLoyalty
WHERE LoyaltyRank = 1  -- Only show the most loyal customer per restaurant
ORDER BY TotalOrdersCompleted DESC, TotalAmountSpent DESC;

--5) Show restaurants with average customer rating ≥ 4.5 and more than 2 reviews.
SELECT
    r.RestaurantID,r.Name,r.City,
    ROUND(AVG(rt.Rating), 2) as [Average Rating],
    COUNT(rt.RatingID) as [Review Count]
FROM Restaurants r
JOIN Ratings rt ON r.RestaurantID = rt.RestaurantID 
GROUP BY r.RestaurantID, r.Name, r.City
HAVING AVG(rt.Rating) >= 4.5 
   AND COUNT(rt.RatingID) > 2  
ORDER BY [Average Rating] DESC, [Review Count] DESC;

--6) Calculate month-over-month revenue growth for the platform.
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.OrderDate) as [OrderYear],
        MONTH(o.OrderDate) as [OrderMonth],
        DATENAME(MONTH, o.OrderDate) as [MonthName],
        SUM(o.Amount) as [TotalRevenue],
        LAG(SUM(o.Amount)) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)) as [PreviousMonthRevenue]
    FROM Orders o
    WHERE o.Status = 'Completed'  -- Only count successful orders
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)
)
SELECT
    [OrderYear],[OrderMonth],[MonthName],
    ROUND([TotalRevenue], 2) as [TotalRevenue],
    ROUND([PreviousMonthRevenue], 2) as [PreviousMonthRevenue],
    ROUND([TotalRevenue] - [PreviousMonthRevenue], 2) as [RevenueGrowth],
    ROUND(([TotalRevenue] - [PreviousMonthRevenue]) / NULLIF([PreviousMonthRevenue], 0) * 100, 2) as [GrowthPercentage]
FROM MonthlyRevenue
ORDER BY [OrderYear], [OrderMonth];

--7) Find late deliveries: where DeliveryTimeMins > 45.
SELECT
	DeliveryID,OrderID,DeliveryDate,DeliveryTimeMins
FROM Delivery 
WHERE DeliveryTimeMins>45 AND DeliveryStatus='Delivered'
ORDER BY DeliveryID;

--8) Identify customers who have spent above average in their city.
WITH CitySpending AS (
    SELECT 
        c.City,
        AVG(o.Amount) AS AvgCitySpending
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.Status = 'Completed'
    GROUP BY c.City
),
CustomerSpending AS (
    SELECT
        c.CustomerID,c.Name AS CustomerName,c.City,c.JoinDate,
        SUM(o.Amount) AS TotalSpent,
        COUNT(o.OrderID) AS TotalOrders,
        cs.AvgCitySpending
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN CitySpending cs ON c.City = cs.City
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID, c.Name, c.City, c.JoinDate, cs.AvgCitySpending
)
SELECT
    CustomerID,CustomerName,City,JoinDate,
    ROUND(TotalSpent, 2) AS TotalSpent,
    TotalOrders,
    ROUND(AvgCitySpending, 2) AS CityAverageSpending,
    ROUND(TotalSpent - AvgCitySpending, 2) AS AboveAverageBy,
    ROUND((TotalSpent - AvgCitySpending) / AvgCitySpending * 100, 2) AS PercentageAboveAverage
FROM CustomerSpending
WHERE TotalSpent > AvgCitySpending
ORDER BY City, AboveAverageBy DESC;

--9) Using a window function, calculate the running total of spend per customer.
SELECT
    c.CustomerID,c.Name AS CustomerName,c.City,
    o.OrderID,o.OrderDate,o.Amount AS OrderAmount,
    SUM(o.Amount) OVER (
        PARTITION BY c.CustomerID 
        ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotalSpent,
    COUNT(o.OrderID) OVER (
        PARTITION BY c.CustomerID 
        ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningOrderCount
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Completed'
ORDER BY c.CustomerID, o.OrderDate, o.OrderID;

--10) Find orders where the rating is below the restaurant’s average rating (customer dissatisfaction)
SELECT 
    o.OrderID,o.OrderDate,o.Amount,
    c.CustomerID,c.Name AS CustomerName,c.City AS CustomerCity,r.RestaurantID,
    r.Name AS RestaurantName,r.City AS RestaurantCity,r.Cuisine,
    rt.Rating AS CustomerRating,
    restaurant_avg.AvgRestaurantRating,
    (restaurant_avg.AvgRestaurantRating - rt.Rating) AS RatingGap,
    CASE 
        WHEN rt.Rating <= 2 THEN 'Very Dissatisfied'
        WHEN rt.Rating = 3 THEN 'Neutral'
        ELSE 'Satisfied'
    END AS SatisfactionLevel
FROM Orders o
JOIN Ratings rt ON o.OrderID = rt.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Restaurants r ON o.RestaurantID = r.RestaurantID
JOIN (
    -- Calculate average rating for each restaurant
    SELECT 
        RestaurantID,
        ROUND(AVG(CAST(Rating AS DECIMAL(3,2))), 2) AS AvgRestaurantRating,
        COUNT(RatingID) AS TotalRatings
    FROM Ratings
    GROUP BY RestaurantID
    HAVING COUNT(RatingID) >= 3  -- Only consider restaurants with sufficient ratings
) restaurant_avg ON r.RestaurantID = restaurant_avg.RestaurantID
WHERE rt.Rating < restaurant_avg.AvgRestaurantRating
    AND o.Status = 'Completed'
ORDER BY RatingGap DESC, rt.Rating ASC;


--Bonus (Advanced Case Study):
--11) Detect at-risk restaurants:
--Average rating < 4, AND More than 20% of deliveries late.
SELECT
    r.RestaurantID,r.Name,r.City,r.Cuisine,
    ROUND(AVG(rt.Rating), 2) as [Average Rating],
    COUNT(DISTINCT o.OrderID) as [Total Orders],
    COUNT(DISTINCT CASE WHEN d.DeliveryTimeMins > 45 THEN o.OrderID END) as [Late Deliveries],
    ROUND(COUNT(DISTINCT CASE WHEN d.DeliveryTimeMins > 45 THEN o.OrderID END) * 100.0 / 
          COUNT(DISTINCT o.OrderID), 2) as [Late Delivery Percentage],
    CASE 
        WHEN AVG(rt.Rating) < 4.0 
             AND (COUNT(DISTINCT CASE WHEN d.DeliveryTimeMins > 45 THEN o.OrderID END) * 100.0 / 
                  COUNT(DISTINCT o.OrderID)) > 20 
        THEN 'At Risk'
        ELSE 'Not At Risk'
    END as [Risk Status]
FROM Restaurants r
LEFT JOIN Orders o ON r.RestaurantID = o.RestaurantID AND o.Status = 'Completed'
LEFT JOIN Ratings rt ON o.OrderID = rt.OrderID
LEFT JOIN Delivery d ON o.OrderID = d.OrderID AND d.DeliveryStatus = 'Delivered'
WHERE o.OrderID IS NOT NULL  -- Ensure restaurant has orders
GROUP BY r.RestaurantID, r.Name, r.City, r.Cuisine
HAVING COUNT(DISTINCT o.OrderID) >= 5  -- Only consider restaurants with sufficient orders
ORDER BY [Average Rating] ASC, [Late Delivery Percentage] DESC;