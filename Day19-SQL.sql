Create table Patients(
						PatientID int primary key,
						Name varchar(30) not null,
						Gender varchar(20) not null CHECK (Gender IN ('Male', 'Female', 'Other')),
						Age int not null Check (Age>0),
						City varchar(50) not null
						);

Create table Doctors(
						DoctorID int primary key,
						Name varchar(50) not null,
						Specialization varchar(50) not null,
						Experience int not null check (Experience >=0)
					);

Create table Appointments (
							AppointmentID int primary key,
							PatientID int not null,
							DoctorID int not null,
							AppointmentDate date not null default getdate(),
							Fees decimal (6,2) not null check (Fees>0),
							foreign key (PatientID) references Patients(PatientID) on update cascade,
							foreign key (DoctorID) references Doctors(DoctorID) on update cascade,
							Constraint UQ_Appointments unique(PatientID,DoctorID,AppointmentDate)
							);

Create table Treatments (
							TreatmentID int primary key,
							AppointmentID int not null,
							Diagnosis varchar(75) not null,
							PrescribedMedication varchar (100) not null,
							foreign key (AppointmentID) references Appointments(AppointmentID) on delete cascade on update cascade,
						);

Create Index Idx_Appointments_PatientID on Appointments(PatientID);
Create Index Idx_Appointments_DoctorID on Appointments(DoctorID);
Create Index Idx_Treatments_AppointmentID on Treatments(AppointmentID);

INSERT INTO Patients VALUES
(1, 'Anita', 'Female', 30, 'Delhi'),
(2, 'Ravi', 'Male', 45, 'Mumbai'),
(3, 'Sara', 'Female', 29, 'Bangalore'),
(4, 'Arjun', 'Male', 60, 'Hyderabad'),
(5, 'Meena', 'Female', 35, 'Chennai');

INSERT INTO Doctors VALUES
(101, 'Dr. Sen', 'Cardiology', 15),
(102, 'Dr. Iyer', 'Neurology', 20),
(103, 'Dr. Gupta', 'Orthopedics', 10),
(104, 'Dr. Das', 'Dermatology', 8);

INSERT INTO Appointments VALUES
(1001, 1, 101, '2024-06-01', 500),
(1002, 2, 102, '2024-06-03', 600),
(1003, 3, 101, '2024-06-04', 500),
(1004, 4, 103, '2024-06-05', 450),
(1005, 5, 104, '2024-06-07', 400),
(1006, 1, 104, '2024-06-08', 400),
(1007, 2, 103, '2024-06-09', 450);

INSERT INTO Treatments VALUES
(201, 1001, 'High BP', 'Amlodipine'),
(202, 1002, 'Migraine', 'Sumatriptan'),
(203, 1003, ' Arrhythmia ', 'Beta Blockers'),
(204, 1004, 'Fracture', 'Calcium Supplements'),
(205, 1005, 'Eczema', 'Topical Steroids'),
(206, 1006, 'Allergy', 'Antihistamines');

Select * from Patients 
Select * from Doctors 
Select * from Appointments 
Select * from Treatments 

--1) List all patients and the number of appointments they have taken.
SELECT
    p.PatientID,p.Name AS 'Patient Name',
    COUNT(a.AppointmentID) AS 'Number of Appointments'
FROM 
    Patients p
LEFT JOIN 
    Appointments a ON p.PatientID = a.PatientID
GROUP BY
    p.PatientID, p.Name
ORDER BY
    'Number of Appointments' DESC;

--2) Show total fees collected by each doctor.
Select
	d.DoctorID,d.Name as 'Doctors Name',
	Coalesce (Sum(a.Fees),0) as [Total Fees]
from
	Doctors d
left join
	Appointments a on d.DoctorID =a.DoctorID 
Group by
	d.DoctorID,d.Name
Order by
	[Total Fees] Desc;

--3) Find the doctor with the highest average consultation fee.
Select top 1
	d.DoctorID,d.Name as 'Doctor Name',
	ROUND(AVG(a.Fees),2) as [AVG Consultation Fees]
from
	Doctors d
inner join
	Appointments a on d.DoctorID =a.DoctorID  
Group by 
	d.DoctorID,d.Name
Order by
	[AVG Consultation Fees] Desc;

--4) Display names of patients who have consulted more than one doctor.
Select
	p.PatientID,p.Name as 'Patient Name',
	Count(Distinct a.DoctorID) as [Doctors Consulted]
from
	Patients p
join 
	Appointments a on p.PatientID =a.PatientID 
Group by
	p.PatientID,p.Name
Having
	Count(Distinct a.DoctorID)>=2
Order by
	[Doctors Consulted] Desc;

--5) Show patients who have not undergone any treatment yet.
SELECT
    p.PatientID, p.Name AS 'Patient Name'
FROM
    Patients p
LEFT JOIN
    Appointments a ON p.PatientID = a.PatientID
LEFT JOIN
    Treatments t ON t.AppointmentID = a.AppointmentID
WHERE
    a.AppointmentID IS NULL OR t.TreatmentID IS NULL;

--6) List the top 2 cities with the most patients.
SELECT TOP 2
    p.City,
    COUNT(p.PatientID) AS 'Number of Patients'
FROM
    Patients p
GROUP BY
    p.City
ORDER BY
    'Number of Patients' DESC;

--7) Display doctor-wise count of different diagnoses they handled.
Select
	d.DoctorID,d.Name as 'Doctors Name',
	Count (Distinct t.Diagnosis) as [Diagnosis Handled]
from
	Doctors d
join
	Appointments a
on d.DoctorID =a.DoctorID 
join
	Treatments t
on a.AppointmentID =t.AppointmentID 
Group by
	d.DoctorID,d.Name
Order by
	[Diagnosis Handled] Desc;

--8) Find patients who have consulted a doctor specialized in 'Cardiology'. 
SELECT
    p.PatientID,p.Name AS 'Patient Name',
    COUNT(a.AppointmentID) AS 'Cardiology Consultations'
FROM
    Patients p
JOIN
    Appointments a ON p.PatientID = a.PatientID
JOIN
    Doctors d ON a.DoctorID = d.DoctorID
WHERE
    d.Specialization = 'Cardiology'
GROUP BY
    p.PatientID, p.Name
ORDER BY
    'Cardiology Consultations' DESC;

--9) Identify doctors who treated at least 2 patients over age 40.
SELECT
    d.DoctorID,d.Name AS 'Doctor Name',
    COUNT(DISTINCT p.PatientID) AS 'Patients Over 40 Treated'
FROM
    Doctors d
JOIN
    Appointments a ON d.DoctorID = a.DoctorID
JOIN
    Patients p ON a.PatientID = p.PatientID
WHERE
    p.Age > 40
GROUP BY
    d.DoctorID, d.Name
HAVING
    COUNT(DISTINCT p.PatientID) >= 2
ORDER BY
    'Patients Over 40 Treated' DESC;

--10) List patients who consulted doctors with more than 10 years experience.
SELECT DISTINCT
    p.PatientID,p.Name AS 'Patient Name',
    d.Name AS 'Doctor Name',d.Experience AS 'Doctor Experience'
FROM
    Patients p
JOIN
    Appointments a ON p.PatientID = a.PatientID
JOIN
    Doctors d ON d.DoctorID = a.DoctorID
WHERE
    d.Experience > 10
ORDER BY
    p.Name;

-- Bonus Challenge:
--Find doctors who have never been consulted by any patient.
SELECT
    d.DoctorID, d.Name AS 'Doctor Name',d.Specialization
FROM
    Doctors d
LEFT JOIN
    Appointments a ON d.DoctorID = a.DoctorID
WHERE
    a.AppointmentID IS NULL;