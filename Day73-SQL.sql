Create Table Drivers (
						DriverID INT PRIMARY KEY,
						Name VARCHAR(75) NOT NULL CHECK(LEN(Name)>=2),
						City VARCHAR(30) NOT NULL CHECK(LEN(City)>=2),
						JoinDate DATE NOT NULL CHECK(JoinDate<=GETDATE()),
						VehicleType VARCHAR(20) NOT NULL CHECK(VehicleType IN ('Bike','Car')),
						Rating DECIMAL(2,1) NOT NULL CHECK(Rating BETWEEN 1 AND 5)
					);


Create Table Orders (
						OrderID INT PRIMARY KEY,
						CustomerName VARCHAR(75) NOT NULL CHECK(LEN(CustomerName)>=2),
						City VARCHAR(30) NOT NULL CHECK(LEN(City)>=2),
						OrderDate DATE NOT NULL DEFAULT GETDATE(),
						OrderValue DECIMAL(8,2) NOT NULL CHECK(OrderValue>0)
					);


Create Table Deliveries (
							DeliveryID INT PRIMARY KEY,
							OrderID INT NOT NULL,
							DriverID INT NOT NULL,
							DispatchTime DATETIME NOT NULL,
							DeliveryTime DATETIME NOT NULL,
							DistanceKM DECIMAL(4,1) NOT NULL CHECK(DistanceKM>0),
							Status VARCHAR(20) NOT NULL DEFAULT 'Delivered',
							FOREIGN KEY(OrderID) REFERENCES Orders(OrderID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY(DriverID) REFERENCES Drivers(DriverID) ON UPDATE CASCADE ON DELETE CASCADE
						);


Create Table Feedback (
						FeedBackID INT PRIMARY KEY,
						DeliveryID INT NOT NULL,
						Rating INT NOT NULL CHECK(Rating BETWEEN 1 AND 5),
						Comment VARCHAR(100) NOT NULL,
						FeedBackDate Date NOT NULL DEFAULT GETDATE(),
						FOREIGN KEY(DeliveryID) REFERENCES Deliveries(DeliveryID) ON UPDATE CASCADE ON DELETE CASCADE
					);


Create Index Idx_Drivers_Name_City ON Drivers(Name,City);
Create Index Idx_Deliveries_OrderID ON Deliveries(OrderID);
Create Index Idx_Deliveries_DriverID ON Deliveries(DriverID);
Create Index Idx_Feedback_DeliverID ON Feedback(DeliveryID);
Create Index Idx_Orders_City ON Orders(City);
Create Index Idx_Orders_OrderDate ON Orders(OrderDate);
Create Index Idx_Drivers_Rating ON Drivers(Rating);
Create Index Idx_Drivers_JoinDate ON Drivers(JoinDate);
Create Index Idx_Deliveries_Time ON Deliveries(DispatchTime, DeliveryTime);

INSERT INTO Drivers (DriverID, Name, City, JoinDate, VehicleType, Rating) VALUES
(1, 'Rajesh Kumar', 'Bengaluru', '2021-01-10', 'Bike', 4.6),
(2, 'Aisha Khan', 'Delhi', '2020-11-15', 'Car', 4.4),
(3, 'Maria Lopez', 'Mumbai', '2019-12-20', 'Bike', 4.7),
(4, 'Rohan Mehta', 'Chennai', '2021-06-25', 'Bike', 4.2),
(5, 'Ahmed Ali', 'Hyderabad', '2021-08-30', 'Car', 4.8);

INSERT INTO Orders (OrderID, CustomerName, City, OrderDate, OrderValue) VALUES
(101, 'Priya Nair', 'Bengaluru', '2022-08-01', 1200),
(102, 'David Lee', 'Delhi', '2022-08-03', 2500),
(103, 'Fatima Noor', 'Mumbai', '2022-08-05', 1800),
(104, 'Maria Garcia', 'Chennai', '2022-08-06', 900),
(105, 'Arjun Sharma', 'Hyderabad', '2022-08-08', 3000),
(106, 'Priya Nair', 'Bengaluru', '2022-08-10', 1500),
(107, 'Rohan Verma', 'Delhi', '2022-08-12', 2300),
(108, 'Aisha Khan', 'Chennai', '2022-08-13', 1700),
(109, 'David Lee', 'Hyderabad', '2022-08-15', 2200),
(110, 'Maria Garcia', 'Mumbai', '2022-08-16', 2600);

INSERT INTO Deliveries (DeliveryID, OrderID, DriverID, DispatchTime, DeliveryTime, DistanceKM, Status) VALUES
(201, 101, 1, '2022-08-01 10:00', '2022-08-01 10:45', 8.2, 'Delivered'),
(202, 102, 2, '2022-08-03 11:30', '2022-08-03 12:15', 6.4, 'Delivered'),
(203, 103, 3, '2022-08-05 09:45', '2022-08-05 10:25', 7.1, 'Delivered'),
(204, 104, 4, '2022-08-06 14:00', '2022-08-06 15:05', 10.2, 'Delivered'),
(205, 105, 5, '2022-08-08 13:10', '2022-08-08 14:30', 15.6, 'Delivered'),
(206, 106, 1, '2022-08-10 12:00', '2022-08-10 12:45', 9.0, 'Delivered'),
(207, 107, 2, '2022-08-12 16:00', '2022-08-12 16:55', 8.4, 'Delivered'),
(208, 108, 4, '2022-08-13 11:15', '2022-08-13 12:40', 12.5, 'Delivered'),
(209, 109, 5, '2022-08-15 10:45', '2022-08-15 11:30', 7.8, 'Delivered'),
(210, 110, 3, '2022-08-16 09:00', '2022-08-16 10:20', 13.1, 'Delivered');

INSERT INTO Feedback (FeedBackID, DeliveryID, Rating, Comment, FeedBackDate) VALUES
(301, 201, 5, 'Fast & safe', '2022-08-01'),
(302, 202, 4, 'On time', '2022-08-03'),
(303, 203, 5, 'Great communication', '2022-08-05'),
(304, 204, 3, 'Slightly delayed', '2022-08-06'),
(305, 205, 5, 'Very professional', '2022-08-08'),
(306, 206, 4, 'Satisfactory', '2022-08-10'),
(307, 207, 4, 'Polite driver', '2022-08-12'),
(308, 208, 3, 'Took longer route', '2022-08-13'),
(309, 209, 5, 'Excellent service', '2022-08-15'),
(310, 210, 5, 'Very punctual', '2022-08-16');

SELECT * FROM Drivers;
SELECT * FROM Orders;
SELECT * FROM Deliveries;
SELECT * FROM Feedback;

--1) JOIN Practice
--Show each delivery with driver name, city, and customer name.
SELECT
	l.DeliveryID,r.Name AS DriverName,r.City,o.CustomerName
FROM Drivers r
JOIN Deliveries l ON r.DriverID =l.DriverID 
JOIN Orders o ON o.OrderID =l.OrderID 
ORDER BY l.DeliveryID;

--2) Date & Time Function
--Calculate delivery duration in minutes for each order.
SELECT 
    d.DeliveryID,o.OrderID,o.CustomerName,
    dr.Name AS DriverName,d.DispatchTime,d.DeliveryTime,
    DATEDIFF(MINUTE, d.DispatchTime, d.DeliveryTime) AS DeliveryDurationMinutes
FROM Deliveries d
JOIN Orders o ON d.OrderID = o.OrderID
JOIN Drivers dr ON d.DriverID = dr.DriverID
ORDER BY d.DeliveryID;
	
--3) CTE + Aggregation
--Using a CTE, compute total distance delivered and total delivery time (in hours) for each driver.
WITH DeliveryStatistics AS (
    SELECT
        r.DriverID,r.Name AS DriverName,
        ROUND(SUM(l.DistanceKM), 2) AS TotalDistanceDelivered,
        ROUND(SUM(DATEDIFF(MINUTE, l.DispatchTime, l.DeliveryTime)) / 60.0, 2) AS TotalDeliveryHours
    FROM Drivers r
    JOIN Deliveries l ON r.DriverID = l.DriverID
    GROUP BY r.DriverID, r.Name)
SELECT
    DriverID,DriverName,TotalDistanceDelivered,TotalDeliveryHours
FROM DeliveryStatistics 
ORDER BY TotalDeliveryHours DESC;

--4) Window Function (RANK)
--Rank drivers based on total delivery volume (sum of OrderValue).
SELECT
	r.DriverID,r.Name AS DriverName, 
	ROUND(SUM(o.OrderValue),2) AS TotalDeliveryVolume,
	RANK() OVER (ORDER BY SUM(o.OrderValue) DESC) AS DriverRank
FROM Drivers r
JOIN Deliveries l ON r.DriverID =l.DriverID 
JOIN Orders o ON o.OrderID =l.OrderID 
WHERE l.Status ='Delivered'
GROUP BY r.DriverID,r.Name
ORDER BY DriverRank;

--5) CASE + Conditional Analysis
--Classify drivers as:“Fast” average delivery < 50 minutes,“Moderate”  50–70 minutes, “Slow” >70 minutes
SELECT
    r.DriverID,r.Name,r.VehicleType,
    COUNT(l.DeliveryID) AS TotalDeliveries,
    ROUND(AVG(DATEDIFF(MINUTE, l.DispatchTime, l.DeliveryTime)), 2) AS AvgDeliveryMinutes,
    ROUND(MIN(DATEDIFF(MINUTE, l.DispatchTime, l.DeliveryTime)), 2) AS FastestDelivery,
    ROUND(MAX(DATEDIFF(MINUTE, l.DispatchTime, l.DeliveryTime)), 2) AS SlowestDelivery,
    CASE 
        WHEN AVG(DATEDIFF(MINUTE, l.DispatchTime, l.DeliveryTime)) < 50 THEN 'Fast'
        WHEN AVG(DATEDIFF(MINUTE, l.DispatchTime, l.DeliveryTime)) BETWEEN 50 AND 70 THEN 'Moderate'
        ELSE 'Slow'
    END AS DriverClassification
FROM Drivers r
JOIN Deliveries l ON r.DriverID = l.DriverID
GROUP BY r.DriverID, r.Name, r.VehicleType
ORDER BY AvgDeliveryMinutes;

--6) Correlated Subquery
--Find drivers whose average delivery rating is above the overall system average rating.
SELECT
    r.DriverID,r.Name,
    ROUND(AVG(f.Rating), 2) AS AverageFeedbackRating
FROM Drivers r
JOIN Deliveries d ON r.DriverID = d.DriverID
JOIN Feedback f ON d.DeliveryID = f.DeliveryID
GROUP BY r.DriverID, r.Name
HAVING AVG(f.Rating) > (
    SELECT AVG(Rating) 
    FROM Feedback
)
ORDER BY AverageFeedbackRating DESC;

--7) Nested CTE + Performance
--Using nested CTEs, calculate each city’s total deliveries, average delivery time, and top-performing driver by rating.
WITH CityStats AS (
    SELECT 
        o.City,
        COUNT(d.DeliveryID) AS TotalDeliveries,
        ROUND(AVG(DATEDIFF(MINUTE, d.DispatchTime, d.DeliveryTime)), 2) AS AvgDeliveryMinutes,
        ROUND(AVG(f.Rating), 2) AS AvgCityRating
    FROM Orders o
    JOIN Deliveries d ON o.OrderID = d.OrderID
    LEFT JOIN Feedback f ON d.DeliveryID = f.DeliveryID
    GROUP BY o.City
),
DriverCityPerformance AS (
    SELECT 
        o.City,dr.DriverID,dr.Name AS DriverName,
        COUNT(d.DeliveryID) AS DriverDeliveries,
        ROUND(AVG(f.Rating), 2) AS AvgDriverRating,
        RANK() OVER (PARTITION BY o.City ORDER BY AVG(f.Rating) DESC, COUNT(d.DeliveryID) DESC) AS DriverRank
    FROM Orders o
    JOIN Deliveries d ON o.OrderID = d.OrderID
    JOIN Drivers dr ON d.DriverID = dr.DriverID
    LEFT JOIN Feedback f ON d.DeliveryID = f.DeliveryID
    GROUP BY o.City, dr.DriverID, dr.Name
),
TopDrivers AS (
    SELECT 
        City,DriverID,DriverName,DriverDeliveries,AvgDriverRating
    FROM DriverCityPerformance
    WHERE DriverRank = 1
)
SELECT 
    cs.City,cs.TotalDeliveries,cs.AvgDeliveryMinutes,cs.AvgCityRating,
    td.DriverName AS TopDriver,td.AvgDriverRating AS TopDriverRating,
    td.DriverDeliveries AS TopDriverDeliveries
FROM CityStats cs
JOIN TopDrivers td ON cs.City = td.City
ORDER BY cs.AvgCityRating DESC, cs.AvgDeliveryMinutes;

--8) Analytical Query (LAG)
--For each driver, find the number of days between consecutive deliveries.
WITH DriverDeliverySequence AS (
    SELECT
        d.DriverID,dr.Name AS DriverName,d.DeliveryID,d.DispatchTime,
        LAG(d.DispatchTime) OVER (PARTITION BY d.DriverID ORDER BY d.DispatchTime) AS PreviousDeliveryTime,
        ROW_NUMBER() OVER (PARTITION BY d.DriverID ORDER BY d.DispatchTime) AS DeliverySequence
    FROM Deliveries d
    JOIN Drivers dr ON d.DriverID = dr.DriverID)
SELECT
    DriverID,DriverName,DeliveryID,DispatchTime,PreviousDeliveryTime,DeliverySequence,
    CASE 
        WHEN PreviousDeliveryTime IS NOT NULL THEN
            DATEDIFF(DAY, PreviousDeliveryTime, DispatchTime)
        ELSE NULL
    END AS DaysBetweenDeliveries
FROM DriverDeliverySequence
ORDER BY DriverID, DispatchTime;

--9) Date-based Insight
--Identify the busiest delivery day (based on total order count) across all cities.
WITH DailyOrderStats AS (
    SELECT
        CAST(d.DispatchTime AS DATE) AS DeliveryDate,
        DATENAME(WEEKDAY, d.DispatchTime) AS DayOfWeek,
        COUNT(d.DeliveryID) AS TotalOrders,
        COUNT(DISTINCT o.City) AS CitiesCovered
    FROM Deliveries d
    JOIN Orders o ON d.OrderID = o.OrderID
    GROUP BY CAST(d.DispatchTime AS DATE), DATENAME(WEEKDAY, d.DispatchTime)
),
RankedDays AS (
    SELECT
        DeliveryDate,DayOfWeek,TotalOrders,CitiesCovered,
        RANK() OVER (ORDER BY TotalOrders DESC) AS BusinessRank
    FROM DailyOrderStats
)
SELECT
    DeliveryDate,DayOfWeek,TotalOrders,CitiesCovered
FROM RankedDays
WHERE BusinessRank = 1;

--10) Real-World KPI Query (Advanced)
--Compute Delivery Efficiency for each driver =(Total DistanceKM / Total DeliveryTimeHours) rounded to 2 decimals
SELECT
    dr.DriverID,dr.Name AS DriverName,dr.VehicleType,dr.City AS DriverCity,
    COUNT(dl.DeliveryID) AS TotalDeliveries,
    ROUND(SUM(dl.DistanceKM), 2) AS TotalDistanceKM,
    ROUND(SUM(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) / 60.0, 2) AS TotalDeliveryHours,
    ROUND(SUM(dl.DistanceKM) / NULLIF(SUM(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) / 60.0, 0), 2) AS DeliveryEfficiencyKMPH,
    ROUND(AVG(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)), 2) AS AvgDeliveryMinutes,
    ROUND(AVG(dl.DistanceKM), 2) AS AvgDistancePerDelivery
FROM Drivers dr
JOIN Deliveries dl ON dr.DriverID = dl.DriverID
GROUP BY dr.DriverID, dr.Name, dr.VehicleType, dr.City
ORDER BY DeliveryEfficiencyKMPH DESC;

--11) Bonus Challenge (Complex Analytical Logic)
--Identify the best-performing driver overall, considering both speed and quality:
--Formula = (Average FeedbackRating × DeliveryEfficiency) / AverageDeliveryTime.
WITH DriverMetrics AS (
    SELECT
        d.DriverID,dr.Name AS DriverName,dr.VehicleType,dr.City,dr.Rating AS DriverInternalRating,
        -- Delivery Metrics
        COUNT(dl.DeliveryID) AS TotalDeliveries,
        ROUND(SUM(dl.DistanceKM), 2) AS TotalDistanceKM,
        ROUND(SUM(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) / 60.0, 2) AS TotalDeliveryHours,
        
        -- Core Components for Performance Score
        ROUND(AVG(f.Rating), 2) AS AvgFeedbackRating,
        ROUND(SUM(dl.DistanceKM) / NULLIF(SUM(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) / 60.0, 0), 2) AS DeliveryEfficiencyKMPH,
        ROUND(AVG(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)), 2) AS AvgDeliveryMinutes,
        
        -- Performance Score Calculation
        ROUND(
            (AVG(f.Rating) * 
            (SUM(dl.DistanceKM) / NULLIF(SUM(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) / 60.0, 0))) /
            NULLIF(AVG(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)), 0),
            4
        ) AS PerformanceScore,
        
        -- Individual Component Rankings
        RANK() OVER (ORDER BY AVG(f.Rating) DESC) AS QualityRank,
        RANK() OVER (ORDER BY SUM(dl.DistanceKM) / NULLIF(SUM(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) / 60.0, 0) DESC) AS EfficiencyRank,
        RANK() OVER (ORDER BY AVG(DATEDIFF(MINUTE, dl.DispatchTime, dl.DeliveryTime)) ASC) AS SpeedRank
    FROM Drivers d
    JOIN Deliveries dl ON d.DriverID = dl.DriverID
    JOIN Drivers dr ON d.DriverID = dr.DriverID
    LEFT JOIN Feedback f ON dl.DeliveryID = f.DeliveryID
    GROUP BY d.DriverID, dr.Name, dr.VehicleType, dr.City, dr.Rating
),
RankedDrivers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY PerformanceScore DESC) AS OverallRank,
        ROUND(AVG(PerformanceScore) OVER (), 4) AS AveragePerformanceScore,
        CASE 
            WHEN PerformanceScore >= AVG(PerformanceScore) OVER () * 1.2 THEN 'Elite Performer'
            WHEN PerformanceScore >= AVG(PerformanceScore) OVER () THEN 'Above Average'
            ELSE 'Needs Improvement'
        END AS PerformanceTier
    FROM DriverMetrics
)
SELECT
    DriverID,DriverName,VehicleType,City,TotalDeliveries,
    AvgFeedbackRating,DeliveryEfficiencyKMPH,AvgDeliveryMinutes,
    PerformanceScore,OverallRank,PerformanceTier,
    QualityRank,EfficiencyRank, SpeedRank,
    CASE 
        WHEN QualityRank <= 2 AND EfficiencyRank <= 2 THEN 'Balanced High Performer'
        WHEN QualityRank <= 2 THEN 'Quality Specialist'
        WHEN EfficiencyRank <= 2 THEN 'Efficiency Specialist'
        WHEN SpeedRank <= 2 THEN 'Speed Specialist'
        ELSE 'Developing Performer'
    END AS StrengthProfile
FROM RankedDrivers
ORDER BY OverallRank;
