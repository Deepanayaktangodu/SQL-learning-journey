CREATE TABLE Passengers (
							PassengerID INT PRIMARY KEY,
							Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
							Country VARCHAR(50) NOT NULL CHECK(LEN(Country)>=2),
							JoinDate DATE NOT NULL DEFAULT GETDATE() CHECK(JoinDate<=GETDATE())
						);

CREATE TABLE Flights (
						FlightID INT PRIMARY KEY,
						Airline VARCHAR(50) NOT NULL CHECK(LEN(AirLine)>=2),
						Source VARCHAR(50) NOT NULL CHECK(LEN(Source)>=2),
						Destination VARCHAR(50) NOT NULL CHECK(LEN(Destination)>=2),
						FlightDate DATE NOT NULL DEFAULT GETDATE() CHECK(FlightDate<=GETDATE()),
						Capacity INT NOT NULL CHECK(Capacity>0),
						UNIQUE(Airline,Source,Destination,FlightDate)
					);

CREATE TABLE Bookings (
						BookingID INT PRIMARY KEY,
						PassengerID INT NOT NULL,
						FlightID INT NOT NULL,
						BookingDate DATE NOT NULL,
						SeatClass VARCHAR(20) NOT NULL CHECK(SeatClass in ('Economy','Business')),
						Price DECIMAL(10,2) NOT NULL CHECK(Price>0),
						Status VARCHAR(20) NOT NULL CHECK(Status in ('Confirmed','Cancelled')),
						UNIQUE(PassengerID,FlightID),
						FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID) ON UPDATE CASCADE ON DELETE NO ACTION,
						FOREIGN KEY (FlightID) REFERENCES Flights(FlightID) ON UPDATE CASCADE ON DELETE NO ACTION
					);

CREATE TABLE CheckIns (
						CheckInID INT PRIMARY KEY,
						BookingID INT NOT NULL,
						CheckInDate DATE NOT NULL,
						BaggageCount INT NOT NULL CHECK(BaggageCount>=0),
						UNIQUE(BookingID,CheckInDate),
						FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

CREATE TABLE FlightPerformance (
									FlightID INT,
									OnTimeRate DECIMAL(4,2) NOT NULL,
									DelayMinutesAvg INT NOT NULL CHECK(DelayMinutesAvg>=0),
									CancellationRate DECIMAL(4,2) NOT NULL,
									FOREIGN KEY (FlightID) REFERENCES Flights(FlightID) ON UPDATE CASCADE ON DELETE NO ACTION
								);

Create Index Idx_Passengers_Name ON Passengers(Name);
Create Index Idx_Passengers_Country ON Passengers(Country);
Create Index Idx_Passengers_JoinDate ON Passengers(JoinDate);
Create Index Idx_Flights_Airline ON Flights(Airline);
Create Index Idx_Flights_Source ON Flights(Source);
Create Index Idx_Flights_Destination ON Flights(Destination);
Create Index Idx_Flights_FlightDate ON Flights(FlightDate);
Create Index Idx_Flights_Capacity ON Flights(Capacity);
Create Index Idx_Bookings_PassengerID ON Bookings(PassengerID);
Create Index Idx_Bookings_FlightID ON Bookings(FlightID);
Create Index Idx_Bookings_BookingDate ON Bookings(BookingDate);
Create Index Idx_Bookings_SeatClass ON Bookings(SeatClass);
Create Index Idx_Bookings_Price ON Bookings(Price);
Create Index Idx_Bookings_Status ON Bookings(Status);
Create Index Idx_CheckIns_BookingID ON CheckIns(BookingID);
Create Index Idx_CheckIns_CheckInDate ON CheckIns(CheckInDate);
Create Index Idx_CheckIns_BaggageCount ON CheckIns(BaggageCount);
Create Index Idx_FlightPerformence_OnTimeRate ON FlightPerformance(OnTimeRate);
Create Index Idx_FlightPerformence_DelayMinutesAvg ON FlightPerformance(DelayMinutesAvg);
Create Index Idx_FlightPerformence_CancellationRate ON FlightPerformance(CancellationRate);
Create Index Idx_FlightPerformence_FlightID ON FlightPerformance(FlightID);

INSERT INTO Passengers VALUES
(1, 'Alice', 'USA', '2020-01-15'),
(2, 'Bob', 'UK', '2019-03-22'),
(3, 'Charlie', 'India', '2021-07-19'),
(4, 'David', 'Canada', '2022-11-11'),
(5, 'Eva', 'Germany', '2018-05-01');

INSERT INTO Flights VALUES
(101, 'AirUSA', 'New York', 'London', '2022-01-10', 200),
(102, 'EuroFly', 'London', 'Berlin', '2022-01-15', 180),
(103, 'IndAir', 'Delhi', 'Toronto', '2022-02-05', 220),
(104, 'CanJet', 'Toronto', 'New York', '2022-02-10', 150),
(105, 'SkyHigh', 'Berlin', 'Delhi', '2022-03-12', 210);

INSERT INTO Bookings VALUES
(201, 1, 101, '2022-01-05', 'Economy', 500.00, 'Confirmed'),
(202, 2, 102, '2022-01-10', 'Business', 1200.00, 'Confirmed'),
(203, 3, 103, '2022-01-25', 'Economy', 700.00, 'Cancelled'),
(204, 4, 104, '2022-02-01', 'Economy', 450.00, 'Confirmed'),
(205, 5, 105, '2022-03-01', 'Business', 1500.00, 'Confirmed'),
(206, 1, 101, '2022-01-07', 'Business', 1400.00, 'Confirmed');

ALTER TABLE Bookings DROP CONSTRAINT UQ__Bookings__7038BED9612EF364;

INSERT INTO CheckIns VALUES
(301, 201, '2022-01-10', 2),
(302, 202, '2022-01-15', 1),
(303, 204, '2022-02-10', 0),
(304, 205, '2022-03-12', 3),
(305, 206, '2022-01-10', 1);

INSERT INTO FlightPerformance VALUES
(101, 0.92, 15, 0.01),
(102, 0.85, 40, 0.03),
(103, 0.78, 60, 0.05),
(104, 0.95, 10, 0.01),
(105, 0.88, 30, 0.02);

SELECT * FROM Passengers;
SELECT * FROM Flights;
SELECT * FROM Bookings;
SELECT * FROM CheckIns;
SELECT * FROM FlightPerformance;

--1) Find the top 3 passengers by total spend across all bookings.
SELECT TOP 3
    p.PassengerID,p.Name, p.Country,
    ROUND(SUM(b.Price), 2) AS [Total Spend],
    COUNT(b.BookingID) AS [Unique Bookings]
FROM Passengers p
JOIN Bookings b ON p.PassengerID = b.PassengerID
GROUP BY p.PassengerID, p.Name, p.Country
ORDER BY [Total Spend] DESC;

--2) Calculate the seat occupancy rate per flight (confirmed bookings ÷ capacity).
SELECT
    f.FlightID,f.Airline,f.FlightDate,
    COUNT(b.BookingID) AS [Confirmed Bookings],
    f.Capacity AS [Flight Capacity],
    ROUND(CAST(COUNT(b.BookingID) AS FLOAT) / f.Capacity, 2) AS [Seat Occupancy Rate]
FROM Flights f
JOIN Bookings b ON f.FlightID = b.FlightID
WHERE b.Status = 'Confirmed'
GROUP BY f.FlightID, f.Airline, f.FlightDate, f.Capacity
ORDER BY [Seat Occupancy Rate] DESC;

--3) Find the average ticket price per seat class (Economy vs Business).
SELECT
    SeatClass,
    ROUND(AVG(Price), 2) AS [Average Ticket Price]
FROM Bookings 
WHERE Status = 'Confirmed'
GROUP BY SeatClass 
ORDER BY [Average Ticket Price] DESC;

--4) Identify passengers who booked the same flight more than once.
SELECT
    PassengerID,FlightID,
    COUNT(BookingID) AS NumberOfBookings
FROM Bookings
GROUP BY PassengerID, FlightID
HAVING COUNT(BookingID) > 1;

--5) Calculate the total baggage count per passenger.
SELECT
    p.PassengerID,p.Name, p.Country,
    SUM(c.BaggageCount) AS [Total Baggage Count]
FROM Passengers p
JOIN Bookings b ON p.PassengerID = b.PassengerID 
JOIN CheckIns c ON c.BookingID = b.BookingID 
WHERE b.Status = 'Confirmed'
GROUP BY p.PassengerID, p.Name, p.Country
ORDER BY [Total Baggage Count] DESC;

--6) Show the on-time performance ranking of airlines (by average OnTimeRate).
WITH AirlinePerformance AS (
    SELECT
        f.Airline,
        ROUND(AVG(fp.OnTimeRate), 2) AS [Average OnTimeRate]
    FROM Flights f
    JOIN FlightPerformance fp ON f.FlightID = fp.FlightID
    GROUP BY f.Airline
)
SELECT
    Airline,[Average OnTimeRate],
    RANK() OVER (ORDER BY [Average OnTimeRate] DESC) AS PerformanceRank
FROM AirlinePerformance
ORDER BY PerformanceRank ASC;

--7) Find flights where the cancellation rate > 3%.
SELECT
    f.FlightID,f.Airline,
    COUNT(b.BookingID) as [Total Bookings],
    SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledBookings,
    ROUND(SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.00 / COUNT(b.BookingID), 2) as CancellationRate
FROM Flights f
JOIN Bookings b ON f.FlightID = b.FlightID 
GROUP BY f.FlightID, f.Airline 
HAVING ROUND(SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.00 / COUNT(b.BookingID), 2) > 3
ORDER BY CancellationRate DESC;

--Alternative
WITH FlightCancellations AS (
    SELECT
        f.FlightID,f.Airline,
        COUNT(b.BookingID) as [Total Bookings],
        SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledBookings,
        ROUND(SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.00 / COUNT(b.BookingID), 2) as CancellationRate
    FROM Flights f
    JOIN Bookings b ON f.FlightID = b.FlightID 
    GROUP BY f.FlightID, f.Airline
)
SELECT *
FROM FlightCancellations
WHERE CancellationRate > 3
ORDER BY CancellationRate DESC;

--8) Using window functions, calculate the running spend per passenger ordered by booking date.
SELECT
	p.PassengerID,p.Name,p.Country,b.BookingDate,b.Price,
	SUM(b.Price) OVER (ORDER BY b.BookingDate) AS TotalRunningSpend
FROM Passengers p
JOIN Bookings b ON P.PassengerID =B.PassengerID 
WHERE B.Status ='Confirmed'
ORDER BY B.BookingID;

--9) Identify loyal passengers: those who flew more than 2 times with the same airline.
SELECT
    p.PassengerID,p.Name,p.Country,f.Airline,
    COUNT(DISTINCT b.FlightID) AS [Total Flights]
FROM Passengers p
JOIN Bookings b ON p.PassengerID = b.PassengerID
JOIN Flights f ON b.FlightID = f.FlightID
WHERE b.Status = 'Confirmed'  -- Only count completed flights
GROUP BY p.PassengerID, p.Name, p.Country, f.Airline
HAVING COUNT(DISTINCT b.FlightID) > 2
ORDER BY [Total Flights] DESC;

--10) Find the most profitable flight (highest total revenue from confirmed bookings).
SELECT TOP 1
	f.FlightID,f.AirLine,
	ROUND(SUM(b.Price),2) AS [Total Revenue]
FROM Flights f
JOIN Bookings b ON f.FlightID =b.FlightID 
WHERE b.Status ='Confirmed'
GROUP BY f.FlightID,f.Airline 
ORDER BY [Total Revenue] DESC;

--11) Detect at-risk passengers likely to churn:
--More than 1 cancelled booking, OR Took a flight with average delay > 45 mins, OR Only booked Economy but never Business.
WITH PassengerChurnIndicators AS (
    -- Multiple Cancellations
    SELECT 
        p.PassengerID,
        CASE WHEN COUNT(CASE WHEN b.Status = 'Cancelled' THEN 1 END) > 1 
             THEN 1 ELSE 0 END AS HasMultipleCancellations,
        
        -- Flights with Significant Delays
        CASE WHEN EXISTS (
            SELECT 1 
            FROM Bookings b2 
            JOIN Flights f ON b2.FlightID = f.FlightID 
            JOIN FlightPerformance fp ON f.FlightID = fp.FlightID
            WHERE b2.PassengerID = p.PassengerID 
            AND b2.Status = 'Confirmed'
            AND fp.DelayMinutesAvg > 45
        ) THEN 1 ELSE 0 END AS HasLongDelays,
        
        -- Only Economy, Never Business
        CASE WHEN EXISTS (
            SELECT 1 
            FROM Bookings b3 
            WHERE b3.PassengerID = p.PassengerID 
            AND b3.SeatClass = 'Economy'
        ) AND NOT EXISTS (
            SELECT 1 
            FROM Bookings b4 
            WHERE b4.PassengerID = p.PassengerID 
            AND b4.SeatClass = 'Business'
        ) THEN 1 ELSE 0 END AS OnlyEconomyNeverBusiness,
        
        -- Additional useful metrics
        COUNT(b.BookingID) AS TotalBookings,
        COUNT(CASE WHEN b.Status = 'Cancelled' THEN 1 END) AS CancelledCount,
        COUNT(CASE WHEN b.Status = 'Confirmed' THEN 1 END) AS ConfirmedCount
    FROM Passengers p
    LEFT JOIN Bookings b ON p.PassengerID = b.PassengerID
    GROUP BY p.PassengerID
)
SELECT 
    p.PassengerID,p.Name,p.Country,
    pci.HasMultipleCancellations,pci.HasLongDelays,pci.OnlyEconomyNeverBusiness,
    pci.TotalBookings,pci.CancelledCount,pci.ConfirmedCount,
    -- Overall churn risk score (0-3)
    (pci.HasMultipleCancellations + pci.HasLongDelays + pci.OnlyEconomyNeverBusiness) AS ChurnRiskScore,
    CASE 
        WHEN (pci.HasMultipleCancellations + pci.HasLongDelays + pci.OnlyEconomyNeverBusiness) >= 2 THEN 'High Risk'
        WHEN (pci.HasMultipleCancellations + pci.HasLongDelays + pci.OnlyEconomyNeverBusiness) = 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS ChurnRiskLevel
FROM Passengers p
JOIN PassengerChurnIndicators pci ON p.PassengerID = pci.PassengerID
WHERE pci.HasMultipleCancellations = 1 
   OR pci.HasLongDelays = 1 
   OR pci.OnlyEconomyNeverBusiness = 1
ORDER BY ChurnRiskScore DESC, pci.CancelledCount DESC;