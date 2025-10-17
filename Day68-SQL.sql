Create Table Patients(
						PatientID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Gender VARCHAR(1) NOT NULL CHECK(Gender in ('M','F')),
						Age INT NOT NULL CHECK(Age>0),
						City VARCHAR(30) NOT NULL CHECK(LEN(City)>=2),
						RegistrationDate DATE NOT NULL DEFAULT GETDATE()
					);

Create Table Doctors(
						DoctorID INT PRIMARY KEY,
						Name VARCHAR(30) NOT NULL CHECK(LEN(Name)>=2),
						Specialization VARCHAR(30) NOT NULL CHECK(LEN(SpecializatioN)>=2),
						Experience INT NOT NULL CHECK(Experience>0),
						City VARCHAR(30) NOT NULL CHECK(LEN(City)>=2)
						);

Create Table Appointments (
							AppointmentID INT PRIMARY KEY,
							PatientID INT NOT NULL,
							DoctorID INT NOT NULL,
							AppointmentDate DATE NOT NULL DEFAULT GETDATE(),
							Diagnosis VARCHAR(100) NOT NULL,
							FollowUp VARCHAR(5) NOT NULL CHECK(FollowUp in ('Yes','No')),
							Status VARCHAR(20) NOT NULL CHECK(Status in ('Completed','Cancelled')),
							UNIQUE(PatientID,DoctorID,AppointmentDate),
							FOREIGN KEY(PatientID) REFERENCES Patients(PatientID) ON UPDATE CASCADE ON DELETE CASCADE,
							FOREIGN KEY(DoctorID) REFERENCES Doctors(DoctorID) ON UPDATE CASCADE ON DELETE CASCADE
						);

Create Table Bills (
						BillID INT PRIMARY KEY,
						AppointmentID INT NOT NULL,
						Amount DECIMAL(10,2) NOT NULL CHECK(Amount>0),
						PaymentMode VARCHAR(30) NOT NULL CHECK(PaymentMode in ('Card','UPI','Wallet')),
						BillDate DATE NOT NULL DEFAULT GETDATE(),
						FOREIGN KEY(AppointmentID) REFERENCES Appointments(AppointmentID) ON UPDATE CASCADE ON DELETE CASCADE
					);

CREATE INDEX Idx_Patients_Name_Age_Gender_City ON Patients(Name,Age,Gender,City);
CREATE INDEX Idx_Patients_RegistrationDate ON Patients(RegistrationDate);
CREATE INDEX Idx_Doctors_Name_Specialization_Experience_City ON Doctors(Name, Specialization, Experience, City);
CREATE INDEX Idx_Appointments_PatientID ON Appointments(PatientID);
CREATE INDEX Idx_Appointments_DoctorID ON Appointments(DoctorID);
CREATE INDEX Idx_AppointmentID ON Bills(AppointmentID);
CREATE INDEX Idx_Amount_PaymentMode ON Bills(Amount,PaymentMode);
CREATE INDEX Idx_Bills_BillDate ON Bills(BillDate);
CREATE INDEX Idx_Bills_AppointmentID ON Bills(AppointmentID);

INSERT INTO Patients (PatientID, Name, Gender, Age, City, RegistrationDate) VALUES
(1, 'Priya Nair', 'F', 28, 'Bengaluru', '2021-01-05'),
(2, 'Rohan Mehta', 'M', 35, 'Delhi', '2021-03-10'),
(3, 'Fatima Noor', 'F', 40, 'Dubai', '2020-09-15'),
(4, 'David Lee', 'M', 50, 'New York', '2022-01-20'),
(5, 'Maria Garcia', 'F', 31, 'Madrid', '2021-06-11');

INSERT INTO Doctors (DoctorID, Name, Specialization, Experience, City) VALUES
(101, 'Dr. Sharma', 'Cardiologist', 15, 'Delhi'),
(102, 'Dr. Khan', 'Neurologist', 10, 'Dubai'),
(103, 'Dr. Patel', 'Orthopedic', 8, 'Bengaluru'),
(104, 'Dr. Watson', 'General', 20, 'New York'),
(105, 'Dr. Lopez', 'Dermatologist', 12, 'Madrid');

INSERT INTO Appointments (AppointmentID, PatientID, DoctorID, AppointmentDate, Diagnosis, FollowUp, Status) VALUES
(201, 1, 103, '2022-07-10', 'Knee Pain', 'Yes', 'Completed'),
(202, 2, 101, '2022-07-12', 'Chest Pain', 'No', 'Completed'),
(203, 3, 102, '2022-08-01', 'Migraine', 'Yes', 'Completed'),
(204, 4, 104, '2022-08-05', 'Fever', 'No', 'Cancelled'),
(205, 5, 105, '2022-08-08', 'Skin Allergy', 'Yes', 'Completed'),
(206, 1, 103, '2022-09-05', 'Fracture', 'No', 'Completed'),
(207, 2, 101, '2022-09-07', 'BP Checkup', 'No', 'Completed'),
(208, 3, 102, '2022-09-09', 'Migraine Follow', 'No', 'Completed'),
(209, 5, 105, '2022-09-15', 'Acne', 'Yes', 'Completed'),
(210, 4, 104, '2022-09-20', 'Cold & Cough', 'No', 'Completed');

INSERT INTO Bills (BillID, AppointmentID, Amount, PaymentMode, BillDate) VALUES
(301, 201, 1200, 'Card', '2022-07-10'),
(302, 202, 2000, 'UPI', '2022-07-12'),
(303, 203, 2500, 'Wallet', '2022-08-01'),
(304, 205, 1800, 'Card', '2022-08-08'),
(305, 206, 2200, 'Card', '2022-09-05'),
(306, 207, 1900, 'UPI', '2022-09-07'),
(307, 208, 2700, 'Card', '2022-09-09'),
(308, 209, 1600, 'Wallet', '2022-09-15'),
(309, 210, 900, 'Card', '2022-09-20');

SELECT * FROM Patients;
SELECT * FROM Doctors;
SELECT * FROM Appointments;
SELECT * FROM Bills;

--1) JOIN Practice
--Display patient name, doctor name, diagnosis, and bill amount for all completed appointments.
SELECT
	p.Name as PatientName,d.Name as DoctorName,a.Diagnosis,b.Amount
FROM Patients p
JOIN Appointments a ON p.PatientID =a.PatientID 
JOIN Doctors d ON d.DoctorID =a.DoctorID 
JOIN Bills b ON b.AppointmentID =a.AppointmentID 
WHERE a.Status ='Completed';

--2) CTE + Aggregation
--Using a CTE, find each doctor’s total billed amount and number of patients treated.
WITH DoctorTreatmentDetail AS(
				SELECT
					d.DoctorID,d.Name,d.Specialization,
					ROUND(SUM(b.Amount),2) AS TotalBilledAmount,
					COUNT(DISTINCT a.AppointmentID) AS TotalPatientsTreated
				FROM Doctors d
				JOIN Appointments a ON d.DoctorID =a.DoctorID 
				JOIN Bills b ON a.AppointmentID =b.AppointmentID AND a.Status ='Completed'
				GROUP BY d.DoctorID,d.Name,d.Specialization)
SELECT	DoctorID,Name,Specialization,TotalBilledAmount,TotalPatientsTreated
FROM DoctorTreatmentDetail 
ORDER BY TotalBilledAmount DESC;

--3) Window Function (RANK)
--Rank doctors by their total revenue earned from appointments.
WITH DoctorsRevenue AS(
			SELECT
				d.DoctorID,d.Name,d.Specialization,d.City,
				ROUND(SUM(b.Amount),2) AS TotalRevenueGenerated,
				COUNT(DISTINCT a.AppointmentID) AS TotalAppointments,
				RANK() OVER (ORDER BY SUM(b.Amount) DESC) AS RevenueRank
			FROM Doctors d
			JOIN Appointments a ON d.DoctorID =a.DoctorID AND a.Status ='Completed'
			JOIN Bills b ON b.AppointmentID =a.AppointmentID 
			GROUP BY d.DoctorID,d.Name,d.Specialization,d.City)
SELECT 
	DoctorID,Name,Specialization,City,TotalRevenueGenerated,TotalAppointments,RevenueRank
FROM DoctorsRevenue 
ORDER BY RevenueRank;

--4) Subquery + Filtering
--List patients who have visited more than one doctor.
SELECT
	p.PatientID,p.Name,
	COUNT(DISTINCT d.DoctorID) AS UniqueDrVisited
FROM Patients p
JOIN Appointments a ON p.PatientID =a.PatientID 
JOIN Doctors d ON d.DoctorID =a.DoctorID 
GROUP BY p.PatientID,p.Name 
HAVING COUNT(DISTINCT d.DoctorID)>1
ORDER BY UniqueDrVisited DESC;

--Efficient Method
SELECT
    PatientID,Name
FROM Patients
WHERE PatientID IN (
    SELECT
        a.PatientID
    FROM Appointments a
    GROUP BY a.PatientID
    HAVING COUNT(DISTINCT a.DoctorID) > 1
	);

--5)CASE + Conditional Aggregation
--Classify each doctor based on average billing amount:
--“High Revenue” (>2000),“Moderate Revenue” (1000–2000),“Low Revenue” (<1000)
SELECT
    d.DoctorID,d.Name,d.Specialization,
    ROUND(AVG(b.Amount), 2) AS AverageRevenue,
    CASE
        WHEN AVG(b.Amount) > 2000 THEN 'High Revenue'
        WHEN AVG(b.Amount) BETWEEN 1000 AND 2000 THEN 'Moderate Revenue'
        WHEN AVG(b.Amount) < 1000 THEN 'Low Revenue'
    END AS RevenueClass
FROM Doctors d
JOIN Appointments a ON d.DoctorID = a.DoctorID
JOIN Bills b ON a.AppointmentID = b.AppointmentID
WHERE a.Status = 'Completed'
GROUP BY d.DoctorID, d.Name, d.Specialization
ORDER BY AverageRevenue DESC;

--6) Correlated Subquery
--Find doctors who have an average bill higher than the overall hospital average.
SELECT
	d.DoctorID,d.Name,d.Specialization,
	ROUND(AVG(b.Amount),2) AS DoctorAverageBill
FROM Doctors d
JOIN Appointments a ON d.DoctorID =a.DoctorID 
JOIN Bills b ON a.AppointmentID =b.AppointmentID 
WHERE a.Status ='Completed'
GROUP BY d.DoctorID,d.Name,d.Specialization 
HAVING AVG(b.Amount) > (
    SELECT
        AVG(Amount)
    FROM Bills b_overall
    JOIN Appointments a_overall ON b_overall.AppointmentID = a_overall.AppointmentID
    WHERE a_overall.Status = 'Completed'
)
ORDER BY DoctorAverageBill DESC;

--7)Date Functions
--Find patients who visited again within 30 days of a previous appointment.
WITH PatientVisitHistory AS (
    SELECT
        PatientID,AppointmentDate,
        LAG(AppointmentDate, 1) OVER (PARTITION BY PatientID ORDER BY AppointmentDate) AS PreviousAppointmentDate
    FROM Appointments
    WHERE Status = 'Completed' -- Only consider completed appointments for visit history
),
ConsecutiveVisits AS (
    SELECT
        pvh.PatientID,
        p.Name AS PatientName,
        pvh.AppointmentDate AS CurrentVisitDate,
        pvh.PreviousAppointmentDate,
        DATEDIFF(day, pvh.PreviousAppointmentDate, pvh.AppointmentDate) AS DaysSincePreviousVisit
    FROM PatientVisitHistory pvh
    JOIN Patients p ON pvh.PatientID = p.PatientID
    WHERE pvh.PreviousAppointmentDate IS NOT NULL -- Exclude the first visit (where LAG returns NULL)
)
SELECT DISTINCT
    PatientID,PatientName
FROM ConsecutiveVisits
WHERE DaysSincePreviousVisit <= 30
ORDER BY PatientID;

--8) Nested CTE + Analytics
--Using nested CTEs, calculate each city’s total hospital revenue and find the top-performing doctor in each city.
WITH CityDoctorRevenue AS (
    -- CTE 1: Calculate Total Revenue per Doctor and City
    SELECT
        d.City,d.DoctorID,d.Name AS DoctorName,
        SUM(b.Amount) AS DoctorRevenue
    FROM Doctors d
    JOIN Appointments a ON d.DoctorID = a.DoctorID
    JOIN Bills b ON a.AppointmentID = b.AppointmentID
    WHERE a.Status = 'Completed'
    GROUP BY d.City, d.DoctorID, d.Name
),
RankedDoctorRevenue AS (
    -- CTE 2 (Nested): Rank Doctors within Each City
    SELECT
        City,DoctorID,DoctorName,DoctorRevenue,
        -- Use RANK partitioned by City to find the top doctor in each city
        RANK() OVER (PARTITION BY City ORDER BY DoctorRevenue DESC) AS CityRank
    FROM CityDoctorRevenue
)
-- Final Query: Find the overall city revenue and the Top Doctor (Rank = 1)
SELECT
    rdr.City,
    SUM(rdr.DoctorRevenue) OVER (PARTITION BY rdr.City) AS TotalCityRevenue,
    rdr.DoctorName AS TopDoctorInCity,
    rdr.DoctorRevenue AS TopDoctorRevenue
FROM RankedDoctorRevenue rdr
WHERE rdr.CityRank = 1
ORDER BY TotalCityRevenue DESC;

--9) Window Function (LAG)
--For each patient, calculate the number of days between consecutive appointments.
WITH PatientVisitDates AS (
    SELECT
        p.PatientID,p.Name,a.AppointmentDate,
        -- Use LAG to retrieve the AppointmentDate of the previous visit for the same patient
        LAG(a.AppointmentDate, 1) OVER (PARTITION BY p.PatientID ORDER BY a.AppointmentDate) AS PreviousAppointmentDate
    FROM Patients p
    JOIN Appointments a ON p.PatientID = a.PatientID
    WHERE a.Status = 'Completed' -- Focus on completed appointments
)
SELECT
    PatientID,Name,PreviousAppointmentDate,
    AppointmentDate AS CurrentAppointmentDate,
    -- Calculate the difference in days between the current and previous visit
    DATEDIFF(day, PreviousAppointmentDate, AppointmentDate) AS DaysSincePreviousVisit
FROM PatientVisitDates
-- Filter out the first appointment for each patient (where PreviousAppointmentDate is NULL)
WHERE PreviousAppointmentDate IS NOT NULL
ORDER BY PatientID, CurrentAppointmentDate;

--10) Real-World Hospital KPI Query (Advanced)
--Find the doctor with the highest repeat patient percentage (number of follow-up appointments ÷ total appointments * 100).
WITH DoctorKPI AS (
    SELECT
        d.DoctorID,d.Name AS DoctorName,
        SUM(CASE WHEN a.FollowUp = 'Yes' THEN 1 ELSE 0 END) AS FollowUpAppointments,
        COUNT(a.AppointmentID) AS TotalAppointments
    FROM Doctors d
    JOIN Appointments a ON d.DoctorID = a.DoctorID
    GROUP BY d.DoctorID, d.Name
),
DoctorPercentage AS (
    SELECT
        DoctorID,DoctorName,FollowUpAppointments,TotalAppointments,
        ROUND(CAST(FollowUpAppointments AS DECIMAL(10, 2)) * 100 / NULLIF(TotalAppointments, 0), 2) AS RepeatPatientPercentage,
        RANK() OVER (ORDER BY ROUND(CAST(FollowUpAppointments AS DECIMAL(10, 2)) * 100 / NULLIF(TotalAppointments, 0), 2) DESC) AS PercentageRank
    FROM DoctorKPI
)
SELECT
    DoctorID,DoctorName,FollowUpAppointments,TotalAppointments,RepeatPatientPercentage
FROM DoctorPercentage
WHERE PercentageRank = 1
ORDER BY RepeatPatientPercentage DESC;

--11) Bonus Challenge (Complex Analytical Logic)
--Identify the most profitable city, where the average bill per appointment multiplied by the number of appointments is the highest 
-- show city name, total revenue, and top contributing doctor.
WITH CityDoctorRevenue AS (
    SELECT
        d.City,d.Name AS DoctorName,
        SUM(b.Amount) AS DoctorRevenue
    FROM Doctors d
    JOIN Appointments a ON d.DoctorID = a.DoctorID
    JOIN Bills b ON a.AppointmentID = b.AppointmentID
    WHERE a.Status = 'Completed'
    GROUP BY d.City, d.Name
),
CityAnalysis AS (
    SELECT
        cdr.City,
        SUM(cdr.DoctorRevenue) AS TotalCityRevenue,
        cdr.DoctorName,cdr.DoctorRevenue,
        RANK() OVER (PARTITION BY cdr.City ORDER BY cdr.DoctorRevenue DESC) AS DoctorRank,
        RANK() OVER (ORDER BY SUM(cdr.DoctorRevenue) DESC) AS CityProfitRank
    FROM CityDoctorRevenue cdr
    GROUP BY cdr.City, cdr.DoctorName, cdr.DoctorRevenue
)
SELECT
    City,TotalCityRevenue,DoctorName AS TopContributingDoctor
FROM CityAnalysis
WHERE CityProfitRank = 1 AND DoctorRank = 1
ORDER BY TotalCityRevenue DESC;
