Create Table Departments (
							DepartmentID INT PRIMARY KEY,
							DepartmentName VARCHAR(30) NOT NULL CHECK(DepartmentName IN ('HR','IT','Sales','Marketing')),
							Manager VARCHAR(30) NOT NULL,
							Location VARCHAR(30) NOT NULL
							);

Create Table Employees (
						EmpID INT PRIMARY KEY,
						Name VARCHAR(50) NOT NULL CHECK(LEN(Name)>=2),
						Gender VARCHAR(1) NOT NULL CHECK(Gender IN ('F','M')),
						Age INT NOT NULL CHECK(Age BETWEEN 18 AND 60),
						DepartmentID INT NOT NULL,
						HireDate DATE NOT NULL CHECK(HireDate<=GETDATE()),
						City VARCHAR(30) NOT NULL CHECK(LEN(City)>=2),
						FOREIGN KEY(DepartmentID) REFERENCES Departments(DepartmentID) ON UPDATE CASCADE ON DELETE NO ACTION
						);

Create Table Salaries(
						SalaryID INT PRIMARY KEY,
						EmpID INT NOT NULL,
						Month VARCHAR(10) NOT NULL,
						Year INT NOT NULL,
						BaseSalary DECIMAL(10,2) NOT NULL CHECK(BaseSalary>0),
						Bonus DECIMAL(8,2) NOT NULL CHECK (Bonus>=0),
						Deductions DECIMAL(8,2) NOT NULL CHECK(Deductions>=0),
						FOREIGN KEY (EmpID) REFERENCES Employees(EmpID) ON UPDATE CASCADE ON DELETE NO ACTION
						);


Create Table Performance (
							PerID INT PRIMARY KEY,
							EmpID INT NOT NULL,
							Month VARCHAR(10) NOT NULL,
							Year INT NOT NULL,
							ProjectsCompleted INT CHECK(ProjectsCompleted>=0),
							Rating DECIMAL(10,2) NULL CHECK(Rating BETWEEN 0 AND 5),
							Remarks VARCHAR(20) NOT NULL,
							FOREIGN KEY (EmpID) REFERENCES Employees(EmpID) ON UPDATE CASCADE ON DELETE NO ACTION
							);

CREATE INDEX Idx_Departments_DepartmentName ON Departments(DepartmentName);
CREATE INDEX Idx_Employees_Name_Gender_Age_City ON Employees(Name,Gender,Age,City);
CREATE INDEX Idx_Employees_HireDate ON Employees(HireDate);
CREATE INDEX Idx_Employees_DepartmentID ON Employees(DepartmentID);
CREATE INDEX Idx_Salaries_EmpID ON Salaries(EmpID);
CREATE INDEX Idx_Salaries_Month_Year ON Salaries(Month,Year);
Create Index Idx_Performance_Month_Year ON Performance(Month,Year);
Create Index Idx_Performance_EmpID ON Performance(EmpID);
Create Index Idx_Performance_ProjectsCompleted_Rating_Remarks ON Performance(ProjectsCompleted,Rating,Remarks);

INSERT INTO Departments (DepartmentID, DepartmentName, Manager, Location) VALUES
(101, 'HR', 'Dr. Sharma', 'India'),
(102, 'IT', 'Anil Kapoor', 'India'),
(103, 'Sales', 'David Watson', 'USA'),
(104, 'Marketing', 'Maria Lopez', 'Spain');

INSERT INTO Employees (EmpID, Name, Gender, Age, DepartmentID, HireDate, City) VALUES
(1, 'Priya Nair', 'F', 29, 101, '2019-05-10', 'Bengaluru'),
(2, 'Arjun Sharma', 'M', 35, 102, '2018-03-15', 'Delhi'),
(3, 'David Lee', 'M', 41, 103, '2020-08-20', 'New York'),
(4, 'Fatima Noor', 'F', 32, 101, '2021-06-11', 'Bengaluru'),
(5, 'Maria Garcia', 'F', 28, 104, '2022-01-05', 'Madrid'),
(6, 'Rohan Mehta', 'M', 37, 102, '2019-11-25', 'Delhi'),
(7, 'Ahmed Khan', 'M', 45, 103, '2017-07-30', 'Dubai'),
(8, 'Sneha Iyer', 'F', 30, 104, '2020-03-18', 'Mumbai');

INSERT INTO Salaries (SalaryID, EmpID, Month, Year, BaseSalary, Bonus, Deductions) VALUES
(201, 1, 'Jul', 2022, 60000, 5000, 2000),
(202, 2, 'Jul', 2022, 85000, 8000, 3000),
(203, 3, 'Jul', 2022, 95000, 7000, 4000),
(204, 4, 'Jul', 2022, 55000, 4000, 1500),
(205, 5, 'Jul', 2022, 50000, 6000, 2000),
(206, 6, 'Jul', 2022, 78000, 5000, 3500),
(207, 7, 'Jul', 2022, 88000, 10000, 5000),
(208, 8, 'Jul', 2022, 58000, 4500, 1000);

INSERT INTO Performance (PerID, EmpID, Month, Year, ProjectsCompleted, Rating, Remarks) VALUES
(301, 1, 'Jul', 2022, 5, 4.3, 'Excellent'),
(302, 2, 'Jul', 2022, 3, 3.7, 'Satisfactory'),
(303, 3, 'Jul', 2022, 6, 4.6, 'Very Good'),
(304, 4, 'Jul', 2022, 4, 4.0, 'Good'),
(305, 5, 'Jul', 2022, 5, 4.4, 'Excellent'),
(306, 6, 'Jul', 2022, 2, 3.5, 'Average'),
(307, 7, 'Jul', 2022, 7, 4.8, 'Outstanding'),
(308, 8, 'Jul', 2022, 3, 3.8, 'Good');

SELECT * FROM Departments;
SELECT *FROM Employees; 
SELECT * FROM Salaries;
SELECT * FROM Performance; 

--1) JOIN Practice
--Display employee name, department name, base salary, and performance rating.
SELECT
	e.EmpID,e.Name as 'Employee Name',d.DepartmentName,s.BaseSalary,p.Rating
FROM Employees e
JOIN Departments d ON e.DepartmentID =d.DepartmentID 
JOIN Salaries s ON s.EmpID =e.EmpID 
JOIN Performance p ON p.EmpID =e.EmpID
ORDER BY e.EmpID;

--2) CTE + Salary Analysis
--Using a CTE, calculate each employee’s net salary = BaseSalary + Bonus - Deductions and rank them within their department.
WITH EmployeeNetSalary AS (
    SELECT
        e.EmpID,e.Name,d.DepartmentName,
        s.BaseSalary,s.Bonus,s.Deductions,
        (s.BaseSalary + s.Bonus - s.Deductions) AS NetSalary,
        RANK() OVER (PARTITION BY d.DepartmentName ORDER BY (s.BaseSalary + s.Bonus - s.Deductions) DESC) AS DeptSalaryRank
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    INNER JOIN Salaries s ON e.EmpID = s.EmpID
)
SELECT 
    EmpID,Name,DepartmentName,BaseSalary,Bonus,Deductions,NetSalary,DeptSalaryRank
FROM EmployeeNetSalary
ORDER BY DepartmentName, DeptSalaryRank;

--3) Subquery + Filtering
--Find employees whose rating is above their department’s average rating.
SELECT 
    e.EmpID,e.Name,d.DepartmentName,p.Rating,
    dept_avg.AvgDepartmentRating
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
INNER JOIN Performance p ON e.EmpID = p.EmpID
INNER JOIN (
    -- Subquery to calculate average rating per department
    SELECT 
        e.DepartmentID,
        AVG(p.Rating) AS AvgDepartmentRating
    FROM Employees e
    INNER JOIN Performance p ON e.EmpID = p.EmpID
    WHERE p.Rating IS NOT NULL
    GROUP BY e.DepartmentID
) dept_avg ON e.DepartmentID = dept_avg.DepartmentID
WHERE p.Rating > dept_avg.AvgDepartmentRating
ORDER BY d.DepartmentName, p.Rating DESC;

--4)CASE + Conditional Aggregation
--Classify employees as:“Top Performer” Rating ≥ 4.5,“Good Performer” 4.0–4.49,“Needs Improvement” < 4.0
SELECT
    e.EmpID,e.Name,p.Rating,
    CASE 
        WHEN p.Rating >= 4.5 THEN 'Top Performer'
        WHEN p.Rating >= 4.0 AND p.Rating < 4.5 THEN 'Good Performer'
        ELSE 'Needs Improvement'
    END as PerformanceRank
FROM Employees e
INNER JOIN Performance p ON e.EmpID = p.EmpID
WHERE p.Rating IS NOT NULL
ORDER BY p.Rating DESC;

--5) Window Function (RANK)
--Rank departments by their average performance rating.
SELECT
    d.DepartmentID,d.DepartmentName,
    ROUND(AVG(p.Rating), 2) AS AveragePerformanceRating,
    RANK() OVER (ORDER BY AVG(p.Rating) DESC) AS PerformanceRank
FROM Departments d
JOIN Employees e ON d.DepartmentID = e.DepartmentID 
JOIN Performance p ON p.EmpID = e.EmpID 
WHERE p.Rating IS NOT NULL
GROUP BY d.DepartmentID, d.DepartmentName 
ORDER BY PerformanceRank;

--6) Analytical Query (LAG)
--Calculate how an employee’s performance rating changed compared to the previous month 
--(if July 2022 is current, assume June 2022 data for reference).
SELECT
    EmpID,Name,DepartmentName,Month,Year,CurrentRating,PreviousRating,
    COALESCE(CurrentRating - PreviousRating, 0) AS RatingChange,
    CASE 
        WHEN PreviousRating IS NULL THEN 'No previous data'
        WHEN CurrentRating > PreviousRating THEN 'Improved'
        WHEN CurrentRating < PreviousRating THEN 'Declined'
        ELSE 'No change'
    END AS PerformanceTrend
FROM (
    SELECT
        e.EmpID,e.Name,d.DepartmentName,
        p.Month,p.Year,p.Rating AS CurrentRating,
        LAG(p.Rating) OVER (PARTITION BY e.EmpID ORDER BY p.Year, 
            CASE p.Month 
                WHEN 'January' THEN 1
                WHEN 'February' THEN 2
                WHEN 'March' THEN 3
                WHEN 'April' THEN 4
                WHEN 'May' THEN 5
                WHEN 'June' THEN 6
                WHEN 'July' THEN 7
                WHEN 'August' THEN 8
                WHEN 'September' THEN 9
                WHEN 'October' THEN 10
                WHEN 'November' THEN 11
                WHEN 'December' THEN 12
            END
        ) AS PreviousRating
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    INNER JOIN Performance p ON e.EmpID = p.EmpID
    WHERE p.Rating IS NOT NULL
) AS RatingData
ORDER BY DepartmentName, EmpID, Year, 
    CASE Month 
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END;

--7) Nested CTE + Aggregation
--Using nested CTEs, calculate the total payroll cost (net salary) for each department and find the top-earning department.
WITH EmployeeNetSalaries AS (
    -- First CTE: Calculate net salary for each employee
    SELECT
        e.EmpID,e.Name,e.DepartmentID,d.DepartmentName,
        (s.BaseSalary + s.Bonus - s.Deductions) AS NetSalary
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    INNER JOIN Salaries s ON e.EmpID = s.EmpID
    WHERE s.Month = 'December' AND s.Year = 2023  -- Latest salary data
),
DepartmentPayroll AS (
    -- Second CTE: Aggregate net salaries by department
    SELECT
        DepartmentID,DepartmentName,
        COUNT(EmpID) AS EmployeeCount,
        SUM(NetSalary) AS TotalPayrollCost,
        ROUND(AVG(NetSalary), 2) AS AverageSalary
    FROM EmployeeNetSalaries
    GROUP BY DepartmentID, DepartmentName
),
RankedDepartments AS (
    -- Third CTE: Rank departments by payroll cost
    SELECT
        DepartmentID,DepartmentName,EmployeeCount,TotalPayrollCost,AverageSalary,
        RANK() OVER (ORDER BY TotalPayrollCost DESC) AS PayrollRank
    FROM DepartmentPayroll
)
-- Final SELECT: Get all departments with top department highlighted
SELECT
    DepartmentID,DepartmentName,EmployeeCount,TotalPayrollCost,AverageSalary,PayrollRank,
    CASE 
        WHEN PayrollRank = 1 THEN 'TOP EARNING DEPARTMENT'
        ELSE ''
    END AS Status
FROM RankedDepartments
ORDER BY PayrollRank;

--8) Correlated Subquery
--Find employees earning above the average net salary of their department.
WITH DepartmentAverages AS (
    SELECT
        e.DepartmentID,s.Month,s.Year,
        ROUND(AVG(s.BaseSalary + s.Bonus - s.Deductions), 2) AS AvgDeptSalary
    FROM Employees e
    INNER JOIN Salaries s ON e.EmpID = s.EmpID
    WHERE s.Month = 'December' AND s.Year = 2023
    GROUP BY e.DepartmentID, s.Month, s.Year
)
SELECT
    e.EmpID,e.Name,d.DepartmentName,
    (s.BaseSalary + s.Bonus - s.Deductions) AS NetSalary,da.AvgDeptSalary,
    ROUND((s.BaseSalary + s.Bonus - s.Deductions) - da.AvgDeptSalary, 2) AS AboveAverageBy,
    ROUND(((s.BaseSalary + s.Bonus - s.Deductions) / da.AvgDeptSalary - 1) * 100, 2) AS PercentAboveAvg
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
INNER JOIN Salaries s ON e.EmpID = s.EmpID
INNER JOIN DepartmentAverages da ON e.DepartmentID = da.DepartmentID 
    AND s.Month = da.Month 
    AND s.Year = da.Year
WHERE (s.BaseSalary + s.Bonus - s.Deductions) > da.AvgDeptSalary
ORDER BY d.DepartmentName, AboveAverageBy DESC;

--9) Employee Retention Query (Advanced)
--Identify employees with tenure greater than 3 years and performance rating consistently above 4.0.
SELECT
    e.EmpID,e.Name,e.HireDate,
    DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears,
    COUNT(p.Rating) AS TotalRatings,
    ROUND(AVG(p.Rating), 2) AS AverageRating,
    MIN(p.Rating) AS MinRating,
    MAX(p.Rating) AS MaxRating
FROM Employees e
JOIN Performance p ON e.EmpID = p.EmpID 
WHERE DATEDIFF(YEAR, e.HireDate, GETDATE()) > 3
GROUP BY e.EmpID, e.Name, e.HireDate
HAVING MIN(p.Rating) > 4.0  -- All ratings above 4.0
   AND COUNT(p.Rating) >= 3  -- At least 3 performance reviews
ORDER BY AverageRating DESC, TenureYears DESC;

--10) Real-World HR KPI Query (Advanced)
--Compute department efficiency as:
--(Avg Rating * Avg ProjectsCompleted) / Avg Salary * 1000
--Rank all departments based on this metric.
WITH DepartmentMetrics AS (
    SELECT
        d.DepartmentID,d.DepartmentName,d.Manager,
        COUNT(DISTINCT e.EmpID) AS EmployeeCount,
        -- Performance Metrics
        ROUND(AVG(p.Rating), 3) AS AvgRating,
        ROUND(AVG(p.ProjectsCompleted), 2) AS AvgProjectsCompleted,
        -- Salary Metrics
        ROUND(AVG(s.BaseSalary + s.Bonus - s.Deductions), 2) AS AvgNetSalary,
        -- Efficiency KPI Calculation
        ROUND(
            (AVG(p.Rating) * AVG(p.ProjectsCompleted)) / 
            NULLIF(AVG(s.BaseSalary + s.Bonus - s.Deductions), 0) * 1000, 
        4) AS EfficiencyKPI
    FROM Departments d
    INNER JOIN Employees e ON d.DepartmentID = e.DepartmentID
    INNER JOIN Performance p ON e.EmpID = p.EmpID
    INNER JOIN Salaries s ON e.EmpID = s.EmpID
    WHERE p.Rating IS NOT NULL 
      AND p.ProjectsCompleted IS NOT NULL
      AND s.Month = 'December' AND s.Year = 2023  -- Current salary data
      AND p.Month = 'December' AND p.Year = 2023  -- Current performance data
    GROUP BY d.DepartmentID, d.DepartmentName, d.Manager
)
SELECT
    DepartmentID,DepartmentName,Manager,EmployeeCount,
    AvgRating,AvgProjectsCompleted,AvgNetSalary,EfficiencyKPI,
    RANK() OVER (ORDER BY EfficiencyKPI DESC) AS EfficiencyRank,
    CASE 
        WHEN EfficiencyKPI >= (SELECT AVG(EfficiencyKPI) FROM DepartmentMetrics) * 1.2 
            THEN 'HIGH EFFICIENCY'
        WHEN EfficiencyKPI <= (SELECT AVG(EfficiencyKPI) FROM DepartmentMetrics) * 0.8 
            THEN 'LOW EFFICIENCY'
        ELSE 'AVERAGE EFFICIENCY'
    END AS EfficiencyCategory
FROM DepartmentMetrics
ORDER BY EfficiencyRank;

--11)  Bonus Challenge (Complex Analytical Logic)
--Find the most cost-effective top performer — 
--the employee with rating ≥ 4.5 and the lowest cost per project (NetSalary / ProjectsCompleted).
WITH TopPerformers AS (
    SELECT
        e.EmpID,e.Name,d.DepartmentName,p.Rating,p.ProjectsCompleted,
        (s.BaseSalary + s.Bonus - s.Deductions) AS NetSalary,
        ROUND(
            (s.BaseSalary + s.Bonus - s.Deductions) / NULLIF(p.ProjectsCompleted, 0), 2) AS CostPerProject,
        -- Performance metrics
        ROUND(p.Rating * p.ProjectsCompleted, 2) AS PerformanceScore
    FROM Employees e
    INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
    INNER JOIN Performance p ON e.EmpID = p.EmpID
    INNER JOIN Salaries s ON e.EmpID = s.EmpID
    WHERE p.Rating >= 4.5  -- Top performers only
      AND p.ProjectsCompleted > 0  -- Must have completed projects
      AND s.Month = 'JUL' AND s.Year = 2022  -- Current salary
      AND p.Month = 'JUL' AND p.Year = 2022  -- Current performance
)
SELECT
    EmpID,Name,DepartmentName,Rating,ProjectsCompleted,NetSalary,CostPerProject,PerformanceScore,
    RANK() OVER (ORDER BY CostPerProject ASC) AS CostEffectivenessRank,
    ROUND((PerformanceScore / NetSalary) * 1000, 2) AS EfficiencyRatio
FROM TopPerformers
ORDER BY CostPerProject ASC
OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY;
