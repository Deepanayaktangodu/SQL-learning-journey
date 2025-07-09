CREATE TABLE Employees (
						EmployeeID INT PRIMARY KEY,
						Name CHAR(100) NOT NULL,
						DepartmentID INT,
						Salary BIGINT ,	
						HireDate DATE,	
						ManagerID INT,  -- Only define the column once
    
    -- Define FKs separately (not inline)
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    FOREIGN KEY (ManagerID) REFERENCES Employees(EmployeeID)  -- Only one FK on ManagerID
);

Create table Departments (

							DepartmentID int Primary Key,
							DepartmentName varchar (100)Not Null 
							);

Insert into Employees (EmployeeID, Name, DepartmentID, Salary,HireDate, ManagerID)
Values 
	(1, 'Alice', 101, 70000, '2018-03-15', 3),
	(2, 'Bob', 102, 48000, '2019-07-10', 3),
	(3, 'Charlie', 101, 90000, '2015-01-20', Null),
	(4, 'David', 103, 60000, '2020-05-25', 2),
	(5, 'Eva', 102, 75000, '2017-11-30', 3);

Insert into Departments (DepartmentID,DepartmentName)
Values
	(101, 'Engineering'),
	(102, 'Sales'),
	(103, 'HR');

Select * from Employees 
Select * from Departments 

-- 1) List all employee names and their salaries.

Select
	Name, Salary 
from
	Employees; 

-- 1A) Sort results by salary (highest to lowest):

Select
	Name, Salary 
from
	Employees
Order by
		Salary Desc;

-- 1B) Filter for employees earning more than $50,000:

Select
	Name, Salary 
from
	Employees
where 
		Salary > '50000';

-- 2) Find employees who work in the Sales department.

--Answer 1: Using join
 
SELECT 
	e.EmployeeID, e.Name 
FROM 
	Employees e
INNER JOIN
	Departments d ON
		d.DepartmentID = e.DepartmentID
WHERE 
	d.DepartmentName = 'Sales';

-- Answer 2: Using Department ID

Select 
	EmployeeID, Name 
from
	Employees 
where
	DepartmentID=102;

-- 3) Count the number of employees in each department.

SELECT 
	DepartmentID, COUNT(EmployeeID) AS NumberOfEmployees
FROM 
	Employees
GROUP BY 
	DepartmentID;

--3A) With Department name
SELECT 
	d.DepartmentName, COUNT(e.EmployeeID) AS NumberOfEmployees
FROM 
	Employees e
JOIN	
	Departments d 
ON 
	e.DepartmentID = d.DepartmentID
GROUP BY 
	d.DepartmentName;

-- 4) Show the employee name along with their department name.

Select
	e.Name, d.DepartmentName
from
	Employees e
Join 
	Departments d on

e.DepartmentID=d.DepartmentID; 

-- 5) Find the highest salary among employees in each department.

SELECT 
    d.DepartmentID,d.DepartmentName, MAX(e.Salary) AS HighestSalary
FROM 
    Employees e
JOIN 
    Departments d ON 
e.DepartmentID = d.DepartmentID
GROUP BY 
    d.DepartmentID, d.DepartmentName;

-- Query (Using Window Functions):

WITH RankedSalaries AS (
    SELECT 
		e.EmployeeID, e.Name, e.Salary, d.DepartmentID, d.DepartmentName,
        RANK() OVER (PARTITION BY d.DepartmentID ORDER BY e.Salary DESC) AS SalaryRank
FROM 
	Employees e
JOIN 
	Departments d ON e.DepartmentID = d.DepartmentID
)
SELECT 
    EmployeeID, Name, Salary, DepartmentID, DepartmentName
FROM 
    RankedSalaries
WHERE 
    SalaryRank = 1;

-- 6) List employees hired after January 1, 2018.

Select 
	EmployeeID, Name, DepartmentID, HireDate 
From
	Employees 
where
	HireDate> '2018-01-01';

-- 7) Find employees who do not have a manager (i.e., top-level managers).

Select
	EmployeeID,Name, DepartmentID,ManagerID
From
	Employees 
Where 
	ManagerID is Null;

-- Checking both null and zero

SELECT
    EmployeeID, Name, DepartmentID, ManagerID
FROM
    Employees
WHERE
    ManagerID IS NULL OR ManagerID = 0;

--Bonus challenge:
--Write a query to find the names of employees along with their managers’ names.

SELECT 
    E.Name AS EmployeeName,
    M.Name AS ManagerName
FROM 
    Employees E
LEFT JOIN 
    Employees M
ON 
    E.ManagerID = M.EmployeeID;

