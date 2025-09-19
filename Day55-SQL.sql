CREATE TABLE Departments (
							DeptID INT PRIMARY KEY,
							DeptName VARCHAR(50) UNIQUE NOT NULL CHECK(LEN(DeptName)>=2),
							Location VARCHAR(50) UNIQUE NOT NULL CHECK(LEN(Location)>=2)
						);

CREATE TABLE Employees (
							EmpID INT PRIMARY KEY,
							Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
							Gender CHAR(1) NOT NULL CHECK (Gender in ('M','F')),
							HireDate DATE NOT NULL DEFAULT GETDATE(),
							DeptID INT NOT NULL,
							Salary DECIMAL(10,2) NOT NULL CHECK(Salary>0),
							ManagerID INT NULL,
							FOREIGN KEY (ManagerID) REFERENCES Employees(EmpID),
							FOREIGN KEY (DeptID) REFERENCES Departments(DeptID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

CREATE TABLE Performance (
							PerfID INT PRIMARY KEY,
							EmpID INT NOT NULL ,
							Year INT NOT NULL ,
							Rating INT NOT NULL CHECK(Rating BETWEEN 1 AND 5),
							UNIQUE(EmpID,Year),
							FOREIGN KEY (EmpID) REFERENCES Employees(EmpID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

CREATE TABLE Attendance (
							AttID INT PRIMARY KEY,
							EmpID INT NOT NULL ,
							Month VARCHAR(10) NOT NULL,
							DaysPresent INT NOT NULL ,
							UNIQUE(EmpID,Month),
							FOREIGN KEY (EmpID) REFERENCES Employees(EmpID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

Create Index Idx_Departments_DeptName on Departments(DeptName);
Create Index Idx_Departments_Location on Departments(Location);
Create Index Idx_Employees_Name on Employees(Name);
Create Index Idx_Employees_HireDate on Employees(HireDate);
Create Index Idx_Employees_Salary on Employees(Salary);
Create Index Idx_Employees_DeptID on Employees(DeptID);
Create Index Idx_Employees_ManagerID on Employees(EmpID);
Create Index Idx_Performance_Year on Performance(Year);
Create Index Idx_Performance_Rating on Performance(Rating);
Create Index Idx_Performance_EmpID on Performance(EmpID);
Create Index Idx_Attendance_Month on Attendance(Month);
Create Index Idx_Attendance_DaysPresent on Attendance(DaysPresent);
Create Index Idx_Attendance_EmpID on Attendance(EmpID);

INSERT INTO Departments VALUES
(1, 'IT', 'New York'),
(2, 'HR', 'London'),
(3, 'Finance', 'Berlin'),
(4, 'Sales', 'Mumbai');

INSERT INTO Employees VALUES
(101, 'Alice', 'F', '2018-01-15', 1, 85000, NULL),
(102, 'Bob', 'M', '2019-03-22', 1, 60000, 101),
(103, 'Charlie', 'M', '2020-07-19', 2, 50000, NULL),
(104, 'David', 'M', '2017-11-11', 3, 95000, NULL),
(105, 'Eva', 'F', '2021-05-01', 4, 45000, 104),
(106, 'Frank', 'M', '2020-02-20', 1, 70000, 101),
(107, 'Grace', 'F', '2022-06-30', 2, 52000, 103);

INSERT INTO Performance VALUES
(1, 101, 2021, 5),
(2, 102, 2021, 4),
(3, 103, 2021, 3),
(4, 104, 2021, 5),
(5, 105, 2021, 2),
(6, 106, 2021, 4),
(7, 107, 2021, 3),
(8, 101, 2022, 4),
(9, 102, 2022, 3),
(10, 103, 2022, 5),
(11, 104, 2022, 5),
(12, 105, 2022, 4),
(13, 106, 2022, 2),
(14, 107, 2022, 3);

INSERT INTO Attendance VALUES
(1, 101, 'Jan', 20),
(2, 102, 'Jan', 18),
(3, 103, 'Jan', 22),
(4, 104, 'Jan', 21),
(5, 105, 'Jan', 15),
(6, 106, 'Jan', 19),
(7, 107, 'Jan', 23);

Select * from Departments;
Select * from Employees ;
Select * from Performance ;
Select * from Attendance ;

--1) Find the highest-paid employee in each department.
WITH RankedEmployees AS (
  SELECT
    e.Name,e.Salary,d.DeptName,
    ROW_NUMBER() OVER(PARTITION BY d.DeptName ORDER BY e.Salary DESC) AS rn
  FROM Employees e
  JOIN Departments d ON e.DeptID = d.DeptID
)
SELECT
  Name,Salary,DeptName
FROM RankedEmployees
WHERE rn = 1;

--2)List employees who have never received a performance rating of 4 or 5.
SELECT
  e.EmpID,e.Name as 'Employee Name'
FROM Employees e
LEFT JOIN Performance p ON e.EmpID = p.EmpID AND p.Rating IN (4, 5)
WHERE
  p.Rating IS NULL;

--3) Calculate the average salary by department and compare it with the company average.
SELECT
	d.DeptName,
	ROUND(AVG(e.Salary),2) as [Department Average Salary],
	(SELECT AVG(Salary) FROM Employees ) as [Company Average Salary]
FROM Employees e
JOIN Departments d ON e.DeptID =d.DeptID 
GROUP BY d.DeptName;

--4) Show the top 3 employees with the highest average performance rating (use AVG + RANK()).
WITH EmployeeAverageRating AS (
  SELECT
    e.EmpID,e.Name,
    AVG(p.Rating) AS AverageRating
  FROM Employees e
  JOIN Performance p ON e.EmpID = p.EmpID
  GROUP BY e.EmpID, e.Name
),
RankedEmployees AS (
  SELECT
    EmpID,Name,AverageRating,
    RANK() OVER(ORDER BY AverageRating DESC) AS RatingRank
  FROM EmployeeAverageRating
)
SELECT
  EmpID,Name, AverageRating
FROM RankedEmployees
WHERE RatingRank <= 3;
	
--5) Identify employees who are managers and count how many employees report to them.
SELECT
  m.Name AS ManagerName,
  COUNT(e.EmpID) AS NumberOfDirectReports
FROM Employees e
JOIN Employees m ON e.ManagerID = m.EmpID
GROUP BY m.Name
ORDER BY NumberOfDirectReports DESC;

--6) Find employees who have worked for the company for more than 3 years (use DATEDIFF/EXTRACT).
SELECT
	EmpID,Name as 'Employee Name',HireDate,
	DATEDIFF(DAY,HireDate,GETDATE()) as [Total Tenure in Days],
	DATEDIFF(YEAR,HireDate,GETDATE()) as [Total Tenure Years]
FROM Employees
Group by EmpID,Name,HireDate 
HAVING 	DATEDIFF(YEAR,HireDate,GETDATE())>3
Order by [Total Tenure Years] DESC;

--Alternative
SELECT
  EmpID,Name,HireDate,
  DATEDIFF(yy, HireDate, GETDATE()) AS TenureInYears
FROM Employees
WHERE DATEDIFF(yy, HireDate, GETDATE()) > 3;

--7) Show the correlation between attendance and performance by finding employees with DaysPresent > 20 and Rating >= 4.
SELECT
  e.EmpID,e.Name AS 'Employee Name',d.DeptName,
  a.DaysPresent,p.Rating
FROM Employees e
JOIN Departments d ON e.DeptID = d.DeptID
JOIN Attendance a ON a.EmpID = e.EmpID
JOIN Performance p ON p.EmpID = a.EmpID
WHERE a.DaysPresent > 20 AND p.Rating >= 4;

--8) Calculate the year-over-year performance change for each employee (use LAG/LEAD).
SELECT
  EmpID,Name,Year,Rating,
  LAG(Rating, 1, 0) OVER (PARTITION BY EmpID ORDER BY Year) AS PreviousYearRating,
  (Rating - LAG(Rating, 1, 0) OVER (PARTITION BY EmpID ORDER BY Year)) AS YOY_Change
FROM (
  SELECT
    e.EmpID,e.Name,p.Year,p.Rating
  FROM Employees e
  JOIN Performance p ON e.EmpID = p.EmpID
) AS EmployeePerformance
ORDER BY EmpID, Year;

--9) Find departments where the average salary is above the overall average salary.
WITH DepartmentAverage AS (
    SELECT
        DeptID,AVG(Salary) AS AvgDeptSalary
    FROM Employees
    GROUP BY DeptID
),
CompanyAverage AS (
    SELECT
        AVG(Salary) AS AvgCompanySalary
    FROM Employees
)
SELECT
    d.DeptName,da.AvgDeptSalary
FROM DepartmentAverage da
JOIN Departments d ON da.DeptID = d.DeptID
WHERE da.AvgDeptSalary > (SELECT AvgCompanySalary FROM CompanyAverage);

--10) Identify employees who changed from low performance (<3) in 2021 to high performance (>=4) in 2022 (performance improvement).
SELECT
  e.Name,e.EmpID,
  p_2021.Rating AS Rating_2021,
  p_2022.Rating AS Rating_2022
FROM
  Employees e
JOIN
  Performance p_2021 ON e.EmpID = p_2021.EmpID AND p_2021.Year = 2021
JOIN
  Performance p_2022 ON e.EmpID = p_2022.EmpID AND p_2022.Year = 2022
WHERE
  p_2021.Rating < 3
  AND p_2022.Rating >= 4;		
  
--Bonus (Advanced):
--Find the attrition risk employees – employees with:
--Low performance (rating ≤ 2 in last year), AND
--Low attendance (< 18 days average), AND Salary below company median.
WITH EmployeeMetrics AS (
  SELECT
    e.EmpID,e.Name,
    p.Rating,a.DaysPresent,e.Salary,
    NTILE(2) OVER (ORDER BY e.Salary) AS SalaryQuartile
  FROM Employees e
  LEFT JOIN Performance p ON e.EmpID = p.EmpID AND p.Year = 2022
  LEFT JOIN Attendance a ON e.EmpID = a.EmpID
)
SELECT
  EmpID,Name,
  Rating AS "Last Year's Rating",
  DaysPresent,Salary
FROM EmployeeMetrics
WHERE
  Rating <= 2
  AND DaysPresent < 18 AND SalaryQuartile = 1;