Create table Departments (
							DeptID int Primary key,
							DeptName varchar(100) not null unique Check(len(DeptName)>1)
						);

Create table Employees (
						EmpID int Primary key,
						Name varchar(100) not null Check(len(Name)>3),
						DeptID int not null,
						HireDate date not null default getdate() Check(HireDate<=getdate()),
						ManagerID int null,
						Salary decimal(10,2) not null Check(Salary>0),
						foreign key(DeptID) references Departments(DeptID) on update cascade on delete no action,
						foreign key (ManagerID) references Employees(EmpID) on update no action on delete no action
						);

SELECT name, definition 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Employees');


ALTER TABLE Employees
ADD CONSTRAINT CK_Employee_Name_Length CHECK(LEN(Name) >= 3);

Create table Leaves (
						LeaveID int Primary key,
						EmpID int not null,
						LeaveDate date not null default getdate(),
						LeaveType varchar(50) not null Check(LeaveType in ('Sick','Casual','Vacation')),
						foreign key(EmpID) references Employees(EmpID) on update cascade on delete no action
					);

Create Index Idx_Departments_DeptId on Departments(DeptID);
Create Index Idx_Employees_ManagerID on Employees(ManagerID);
Create Index Idx_Leaves_EmpId ON Leaves(EmpID);
Create Index Idx_Departments_DeptName on Departments(DeptName);
Create Index Idx_Employees_DeptID on Employees(DeptID);
CREATE INDEX Idx_Leaves_LeaveDate ON Leaves(LeaveDate);

INSERT INTO Departments VALUES
(1, 'HR'),
(2, 'Finance'),
(3, 'IT'),
(4, 'Marketing');

INSERT INTO Employees VALUES
(101, 'Alice', 1, '2018-02-12', NULL, 60000),
(102, 'Bob', 2, '2019-04-01', 101, 55000),
(103, 'Charlie', 3, '2020-06-23', 101, 70000),
(104, 'David', 3, '2021-01-15', 103, 65000),
(105, 'Eva', 4, '2017-09-10', NULL, 72000),
(106, 'Frank', 4, '2022-03-05', 105, 50000);

INSERT INTO Leaves VALUES
(1, 101, '2023-01-02', 'Sick'),
(2, 101, '2023-03-15', 'Casual'),
(3, 103, '2023-02-18', 'Sick'),
(4, 104, '2023-04-20', 'Vacation'),
(5, 106, '2023-05-05', 'Casual');

Select * from Departments 
Select * from Employees 
Select* from Leaves 

--1) List all employees with their department names.
SELECT
    e.EmpID,e.Name AS 'Employee Name',
    d.DeptName AS 'Department Name'
FROM Employees e
JOIN Departments d ON e.DeptID = d.DeptID
ORDER BY d.DeptName, e.Name;

--2) Find employees who joined before 2020 and earn more than 60,000.
SELECT
    e.EmpID,e.Name AS 'Employee Name',e.HireDate,e.Salary,
    d.DeptName AS 'Department'
FROM Employees e
JOIN Departments d ON e.DeptID = d.DeptID
WHERE e.Salary > 60000 
  AND e.HireDate < '2020-01-01'  -- Changed from 2022 to 2020
ORDER BY e.Salary DESC;

--3) Show the total salary expense per department.
Select
	d.DeptID,d.DeptName AS 'Department Name',
	SUM (e.Salary) as [Total salary expense]
from Employees e
join Departments d
on e.DeptID =d.DeptID 
Group by d.DeptID,d.DeptName
Order by [Total salary expense] Desc;

--4) Find employees who report directly to 'Alice'.
SELECT 
    e.EmpID,e.Name AS 'Employee Name',e.Salary,
    d.DeptName AS 'Department'
FROM Employees e
JOIN Departments d ON e.DeptID = d.DeptID
WHERE e.ManagerID = (
    SELECT EmpID 
    FROM Employees 
    WHERE Name = 'Alice')
ORDER BY e.Name;

--5) For each employee, find how many leaves they have taken.
SELECT
    e.EmpID,e.Name AS 'Employee Name',
    COUNT(l.LeaveID) AS 'Leaves Taken'
FROM Employees e
LEFT JOIN Leaves l ON e.EmpID = l.EmpID
GROUP BY e.EmpID, e.Name
ORDER BY COUNT(l.LeaveID) DESC, e.Name;

--6) Use a window function to rank employees by salary within their department.
WITH EmployeeSalary AS (
    SELECT
        e.EmpID,e.Name AS 'Employee Name',
        d.DeptID,d.DeptName AS 'Department Name',e.Salary,
        RANK() OVER (PARTITION BY d.DeptID ORDER BY e.Salary DESC) AS 'SalaryRank'
    FROM Employees e
    JOIN Departments d ON e.DeptID = d.DeptID
)
SELECT 
    EmpID,[Employee Name],DeptID,[Department Name],Salary,SalaryRank
FROM EmployeeSalary
ORDER BY DeptID, SalaryRank;

--7) Find employees who have never taken a leave.
SELECT
    e.EmpID,e.Name AS 'Employee Name',
    d.DeptName AS 'Department'
FROM Employees e
LEFT JOIN Leaves l ON e.EmpID = l.EmpID
JOIN Departments d ON e.DeptID = d.DeptID
WHERE l.LeaveID IS NULL
ORDER BY e.Name;

--8) Retrieve the department with the highest average salary.
SELECT TOP 1 WITH TIES
    d.DeptID,d.DeptName AS 'Department Name',
    CAST(AVG(e.Salary) AS DECIMAL(10,2)) AS 'Average Salary',
    COUNT(e.EmpID) AS 'Employee Count'
FROM Departments d
JOIN Employees e ON d.DeptID = e.DeptID
GROUP BY d.DeptID, d.DeptName
ORDER BY AVG(e.Salary) DESC;

--9) Using a recursive CTE, display the employee hierarchy starting from Alice.
With EmployeeHierarchy as (
	Select
		EmpID,Name,DeptID,ManagerID,
		0 as level, CAST(Name as varchar(1000)) as HierarchyPath
	from Employees e
	where Name='Alice'
UNION ALL
    SELECT
        e.EmpID,e.Name,e.DeptID,e.ManagerID,
        eh.Level + 1,
        CAST(eh.HierarchyPath + ' -> ' + e.Name AS VARCHAR(1000))
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmpID
)
SELECT
    e.EmpID,e.Name AS 'Employee Name',
    d.DeptName AS 'Department',e.Level,
    REPLICATE('    ', e.Level) + e.Name AS 'Hierarchy',
    e.HierarchyPath
FROM EmployeeHierarchy e
JOIN Departments d ON e.DeptID = d.DeptID
ORDER BY e.HierarchyPath;

--10) For each department, calculate the percentage of employees earning above 60,000.
WITH DepartmentStats AS (
    SELECT
        d.DeptID,d.DeptName AS 'Department Name',
        COUNT(e.EmpID) AS 'Total Employees',
        SUM(CASE WHEN e.Salary > 60000 THEN 1 ELSE 0 END) AS 'High Earners'
    FROM Departments d
    LEFT JOIN Employees e ON d.DeptID = e.DeptID
    GROUP BY d.DeptID, d.DeptName)
SELECT
    DeptID,[Department Name],
    [Total Employees],[High Earners],
    CASE 
        WHEN [Total Employees] = 0 THEN 0.00
        ELSE CAST(([High Earners] * 100.0 / [Total Employees]) AS DECIMAL(5,2))
    END AS 'Percentage Above 60K'
FROM DepartmentStats
ORDER BY [Percentage Above 60K] DESC;

-- Bonus Challenge
-- Find employees whose salary is above the overall company average but who have taken more than 1 leave in 2023.
WITH CompanyStats AS (
    SELECT AVG(Salary) AS AvgSalary FROM Employees
),
LeaveCounts2023 AS (
    SELECT 
        l.EmpID,
        COUNT(*) AS LeaveCount
    FROM Leaves l
    WHERE YEAR(l.LeaveDate) = 2023
    GROUP BY l.EmpID
    HAVING COUNT(*) > 1
)
SELECT 
    e.EmpID,e.Name AS 'Employee Name',e.Salary,
    d.DeptName AS 'Department',
    cs.AvgSalary AS 'Company Average',
    lc.LeaveCount AS '2023 Leaves Taken'
FROM Employees e
JOIN CompanyStats cs ON 1=1
JOIN LeaveCounts2023 lc ON e.EmpID = lc.EmpID
JOIN Departments d ON e.DeptID = d.DeptID
WHERE e.Salary > cs.AvgSalary
ORDER BY e.Salary DESC;