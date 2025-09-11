Create table Passengers (
							PassengerID Int Primary Key,
							Name Varchar(30) Not Null Check(Len(Name)>=2),
							Country Varchar(30) Not Null Check(Len(Country)>=2),
							JoinDate Date Default GetDate(),
							LoyaltyTier Varchar(50) Not Null Check(LoyaltyTier in  ('Gold','Silver','Bronze'))
						);

Create table Flights (
						FlightID Int Primary Key,
						FlightNumber Varchar(30) Not Null,
						Origin Varchar(10) Not Null,
						Destination Varchar(10) Not Null,
						FlightDate Date default GetDate() Not Null,
						Distance BigInt Not Null Check(Distance>0),
						CONSTRAINT CHK_Flights_Origin_Destination CHECK (Origin <> Destination),
						CONSTRAINT UQ_Flights_UniqueJourney UNIQUE (FlightNumber, Origin, Destination, FlightDate) 
					);

Create table Bookings(
						BookingID Int Primary key,
						PassengerID Int Not Null,
						FlightID Int Not null,
						BookingDate Date Default GetDate() Not Null,
						Status Varchar(20) Not Null Check(Status in ('Confirmed','Cancelled')),
						Price Decimal(8,2) Null Check (Price>=0),
						Foreign Key(PassengerID) references Passengers(PassengerID) on update cascade on delete no action,
						Foreign Key(FlightID) references Flights(FlightID) on update cascade on delete no action
					);

Create Index Idx_Passengers_Name on Passengers(Name);
Create Index Idx_Passengers_Country on Passengers(Country);
Create Index Idx_Flights_FlightNumber on Flights(FlightNumber);
Create Index Idx_Flights_Origin on Flights(Origin);
Create Index Idx_Flights_Destination on Flights(Destination);
Create Index Idx_Bookings_Status on Bookings(Status);
Create Index Idx_Bookings_PassengerID on Bookings(PassengerID);
Create Index Idx_Bookings_FlightID on Bookings(FlightID);

INSERT INTO Passengers (PassengerID, Name, Country, JoinDate, LoyaltyTier) VALUES
(1, 'Alice', 'USA', '2021-01-01', 'Gold'),
(2, 'Bob', 'India', '2021-03-10', 'Silver'),
(3, 'Charlie', 'UK', '2022-02-20', 'Bronze'),
(4, 'David', 'Canada', '2022-06-15', 'Silver'),
(5, 'Emma', 'India', '2023-01-05', 'Gold');

INSERT INTO Flights (FlightID, FlightNumber, Origin, Destination, FlightDate, Distance) VALUES
(101, 'AI101', 'DEL', 'NYC', '2023-01-10', 7300),
(102, 'AI102', 'NYC', 'DEL', '2023-01-15', 7300),
(103, 'AI201', 'LON', 'TOR', '2023-02-01', 5600),
(104, 'AI301', 'DEL', 'LON', '2023-02-20', 6700),
(105, 'AI401', 'TOR', 'DEL', '2023-03-01', 7200);

INSERT INTO Bookings (BookingID, PassengerID, FlightID, BookingDate, Status, Price) VALUES
(1, 1, 101, '2023-01-05', 'Confirmed', 1200),
(2, 2, 101, '2023-01-07', 'Cancelled', 0),
(3, 3, 103, '2023-01-25', 'Confirmed', 900),
(4, 4, 104, '2023-02-15', 'Confirmed', 1100),
(5, 5, 105, '2023-02-25', 'Confirmed', 1500),
(6, 1, 102, '2023-01-12', 'Confirmed', 1250),
(7, 2, 104, '2023-02-18', 'Confirmed', 1050),
(8, 3, 105, '2023-02-28', 'Cancelled', 0),
(9, 5, 101, '2023-01-09', 'Confirmed', 1300),
(10, 4, 103, '2023-01-30', 'Confirmed', 950);

Select * from Passengers 
Select * from Flights 
Select * from Bookings 

--1) Revenue by Route
--Calculate total confirmed revenue per Origin-Destination pair.
-- 1) Revenue by Route
-- Calculate total confirmed revenue per Origin-Destination pair.
SELECT
    f.Origin,f.Destination,
    ROUND(SUM(b.Price), 2) AS [Total Revenue],
    COUNT(b.BookingID) AS [Number of Confirmed Bookings]
FROM Flights f
LEFT JOIN Bookings b ON f.FlightID = b.FlightID AND b.Status = 'Confirmed' 
GROUP BY f.Origin, f.Destination
ORDER BY [Total Revenue] DESC;

--2) Top Passengers by Spend
--List the top 3 passengers with the highest total confirmed spend.
SELECT TOP 3
	p.PassengerID,p.Name as 'Passenger Name',p.Country,
	ROUND(SUM(b.Price),2) as [Total Spend]
from Passengers p
join Bookings b on p.PassengerID =b.PassengerID  AND b.Status = 'Confirmed'
GROUP BY p.PassengerID,p.Name,p.Country 
ORDER BY [Total Spend] DESC;

--3) Cancellation Rate
--Find the percentage of cancelled bookings per route.
SELECT
    f.Origin,f.Destination,
    COUNT(b.BookingID) as [Total Bookings],
    SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) as [Cancelled Bookings],
    ROUND(SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(b.BookingID), 0), 2) as [Cancellation Rate (%)]
FROM Flights f
LEFT JOIN Bookings b ON f.FlightID = b.FlightID
GROUP BY f.Origin, f.Destination
ORDER BY [Cancellation Rate (%)] DESC;

--4) Average Ticket Price by Loyalty Tier
--Compute the average confirmed ticket price for each loyalty tier.
SELECT
	p.LoyaltyTier,
	ROUND(AVG(b.Price),2) as [Avg Fair]
from Passengers p
join Bookings b on p.PassengerID =b.PassengerID  AND b.Status ='Confirmed'
group by p.LoyaltyTier 
order by [Avg Fair] DESC;

--5) Monthly Revenue Trends
--Show monthly confirmed revenue and compare with previous month using LAG.
SELECT
    YEAR(b.BookingDate) as [Year],
    MONTH(b.BookingDate) as [Month Number],
    DATENAME(MONTH, b.BookingDate) as [Month Name],
    ROUND(SUM(b.Price), 2) as [Monthly Revenue],
    LAG(ROUND(SUM(b.Price), 2)) OVER (ORDER BY YEAR(b.BookingDate), MONTH(b.BookingDate)) as [Previous Month Revenue],
    ROUND(SUM(b.Price) - LAG(SUM(b.Price)) OVER (ORDER BY YEAR(b.BookingDate), MONTH(b.BookingDate)), 2) as [Revenue Change],
    ROUND(
        (SUM(b.Price) - LAG(SUM(b.Price)) OVER (ORDER BY YEAR(b.BookingDate), MONTH(b.BookingDate))) * 100.0 / 
        NULLIF(LAG(SUM(b.Price)) OVER (ORDER BY YEAR(b.BookingDate), MONTH(b.BookingDate)), 0), 
    2) as [Percentage Change (%)]
FROM Bookings b
WHERE b.Status = 'Confirmed'
GROUP BY YEAR(b.BookingDate), MONTH(b.BookingDate), DATENAME(MONTH, b.BookingDate)
ORDER BY [Year], [Month Number];

--6) Passenger Flight Count
--Find passengers who booked more than 2 confirmed flights.
SELECT
	p.PassengerID,p.Name as 'Passenger Name',p.Country,
	COUNT(DISTINCT b.BookingID) as [Flight Booking Count]
from Passengers p
join Bookings b on p.PassengerID =b.PassengerID AND b.Status ='Confirmed'
group by p.PassengerID,p.Name,p.Country 
having COUNT(DISTINCT b.BookingID)>2
order by [Flight Booking Count] Desc;

--7) Most Frequent Route
--Rank routes by number of confirmed bookings.
SELECT
    f.Origin,f.Destination,
    AVG(f.Distance) as [Avg Distance], -- Or MIN/MAX if distance varies per route
    COUNT(b.BookingID) as [Total Bookings],
    RANK() OVER (ORDER BY COUNT(b.BookingID) DESC) as RouteRank
FROM Flights f
JOIN Bookings b ON f.FlightID = b.FlightID AND b.Status = 'Confirmed'
GROUP BY f.Origin, f.Destination
ORDER BY RouteRank ASC;

--8) Window Function – Booking Timeline
--For each passenger, show bookings along with the previous flight taken (LAG).
SELECT
    p.PassengerID,p.Name as [Passenger Name],
    b.BookingID,b.BookingDate,
    f.FlightID,f.FlightNumber,f.Origin,f.Destination,f.FlightDate,
    b.Status,b.Price,
    LAG(f.FlightNumber) OVER (
        PARTITION BY p.PassengerID 
        ORDER BY b.BookingDate, b.BookingID
    ) as [Previous Flight Number],
    LAG(f.Origin) OVER (
        PARTITION BY p.PassengerID 
        ORDER BY b.BookingDate, b.BookingID
    ) as [Previous Origin],
    LAG(f.Destination) OVER (
        PARTITION BY p.PassengerID 
        ORDER BY b.BookingDate, b.BookingID
    ) as [Previous Destination],
    LAG(f.FlightDate) OVER (
        PARTITION BY p.PassengerID 
        ORDER BY b.BookingDate, b.BookingID
    ) as [Previous Flight Date]
FROM Passengers p
JOIN Bookings b ON p.PassengerID = b.PassengerID
JOIN Flights f ON b.FlightID = f.FlightID
ORDER BY p.PassengerID, b.BookingDate, b.BookingID;

--9) Distance Insights
--Calculate total miles flown per passenger (sum of distances from confirmed bookings).
SELECT
    p.PassengerID,p.Name as 'Passenger Name',p.Country,p.LoyaltyTier,
    COUNT(b.BookingID) as [Total Confirmed Flights],
    ROUND(SUM(f.Distance), 2) as [Total Miles Flown],
    ROUND(AVG(f.Distance), 2) as [Average Flight Distance],
    ROUND(SUM(f.Distance) / NULLIF(COUNT(b.BookingID), 0), 2) as [Miles per Flight]
FROM Passengers p
JOIN Bookings b ON p.PassengerID = b.PassengerID AND b.Status = 'Confirmed'
JOIN Flights f ON b.FlightID = f.FlightID
GROUP BY p.PassengerID, p.Name, p.Country, p.LoyaltyTier
ORDER BY [Total Miles Flown] DESC;

--10)Country-Wise Contribution
--Show revenue contribution from each passenger country and rank them.
Select
	p.Country,
	ROUND(SUM(b.Price),2) as [Total Revenue],
	COUNT(b.BookingID) as [Total Flights Booked],
	RANK() OVER (Order by SUM(b.Price) DESC) as RevenueRank
from Passengers p
join Bookings b on p.PassengerID =b.PassengerID 
group by p.Country 
order by RevenueRank ASC;

--Bonus Challenge (Advanced)
--11)Frequent Flyer Upgrade Eligibility
--A passenger is eligible for an upgrade if:
--They booked ≥ 2 flights in the last 90 days AND their average confirmed ticket price > $1000
--Write a query to flag such passengers.
-- 11) Frequent Flyer Upgrade Eligibility
WITH PassengerRecentActivity AS (
    SELECT
        p.PassengerID,p.Name AS [Passenger Name],p.LoyaltyTier,
        COUNT(b.BookingID) AS [Recent Flights],
        ROUND(AVG(b.Price), 2) AS [Average Ticket Price],
        MAX(b.BookingDate) AS [Last Booking Date]
    FROM Passengers p
    JOIN Bookings b ON p.PassengerID = b.PassengerID 
    WHERE b.Status = 'Confirmed'
      AND b.BookingDate >= DATEADD(DAY, -90, GETDATE()) -- Last 90 days
    GROUP BY p.PassengerID, p.Name, p.LoyaltyTier
    HAVING COUNT(b.BookingID) >= 2
)
SELECT
    PassengerID,[Passenger Name],LoyaltyTier,
    [Recent Flights],[Average Ticket Price],[Last Booking Date],
    CASE 
        WHEN [Average Ticket Price] > 1000 THEN 'Eligible for Upgrade'
        ELSE 'Not Eligible - Average Price Too Low'
    END AS [Upgrade Status]
FROM PassengerRecentActivity
WHERE [Average Ticket Price] > 1000
ORDER BY [Average Ticket Price] DESC, [Recent Flights] DESC;
						