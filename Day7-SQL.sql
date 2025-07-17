CREATE TABLE Employees (
						EmpID int PRIMARY key,
						EmpName varchar(75) not null,
						Department varchar(50) not null,
						Salary bigint not null check (Salary > 0)
						);

CREATE TABLE Projects (
						ProjectID int PRIMARY key,
						ProjectName varchar(75) not null,
						Department varchar(50) not null
						);

CREATE TABLE TimeSheets (
						TimeID int PRIMARY key,
						EmpID int,
						ProjectID int,
						WorkDate Date not null,
						HoursWorked int not null check (HoursWorked > 0),
						foreign key (EmpID) references Employees(EmpID),
						foreign key (ProjectID) references Projects(ProjectID)
						);

Insert into Employees (EmpID,EmpName,Department,Salary)
Values
	(1,'Aditi','IT',60000),
	(2,'Rohit','HR',50000),
	(3,'Meena','Finance',65000),
	(4,'Karan','IT',58000),
	(5,'Sara','HR',52000);

INSERT INTO Projects (ProjectID, ProjectName, Department)
VALUES
    (101, 'Migration', 'IT'),
    (102, 'Recruitment Drive', 'HR'),
    (103, 'Audit 2024', 'Finance'), 
    (104, 'Website Redesign', 'IT');

INSERT INTO TimeSheets (TimeID, EmpID, ProjectID, WorkDate, HoursWorked)
VALUES
	(1001,1,101,'2024-01-05',5),
	(1002,2,102,'2024-01-06',7),
	(1003,3,103,'2024-01-07',6),
	(1004,1,104,'2024-01-08',4),
	(1005,4,101,'2024-01-09',8),
	(1006,5,102,'2024-01-10',5);

Select * from Employees 
Select * from Projects 
Select * from TimeSheets 

-- 1) List all employees along with the projects they have worked on.

SELECT 
    e.EmpName, p.ProjectName
FROM 
    Employees e
JOIN 
    Timesheets t ON e.EmpID = t.EmpID
JOIN 
    Projects p ON t.ProjectID = p.ProjectID
ORDER BY 
    e.EmpName, p.ProjectName;

-- 2) Show total hours worked per employee.

SELECT
    e.EmpID, e.EmpName, SUM(t.HoursWorked) AS [Total Hours Worked]
FROM
    Employees e
JOIN
    TimeSheets t ON e.EmpID = t.EmpID
GROUP BY 
    e.EmpID, e.EmpName
ORDER BY 
    [Total Hours Worked] DESC;

-- 3) Find the total hours worked on each project.

Select
	p.ProjectID,p.ProjectName,sum(t.HoursWorked) as [Total Hours Worked]
from
	Projects p
join
	TimeSheets t
on p.ProjectID=t.ProjectID
Group by
	p.ProjectID,p.ProjectName
Order by
	[Total Hours worked] Desc;

-- 4) Identify employees who have worked on more than one project.

Select
	e.EmpID,e.EmpName, Count (Distinct t.ProjectID) as [ProjectCount]
from
	Employees e
join
	TimeSheets t 
on e.EmpID=t.EmpID
group by
	e.EmpID,e.EmpName
Having
	Count (t.ProjectID)>1
Order by 
	[ProjectCount]  Desc;

-- 5) Display department-wise total hours worked.

-- 5) Display department-wise total hours worked.

SELECT
    e.Department,SUM(t.HoursWorked) AS [Total Hours Worked]
FROM
    Employees e
JOIN
    TimeSheets t ON e.EmpID = t.EmpID
GROUP BY
    e.Department
ORDER BY
    [Total Hours Worked] DESC;

-- 6) Show average hours worked per employee per project.

SELECT
    e.EmpID,e.EmpName,p.ProjectID, p.ProjectName,
    AVG(t.HoursWorked) AS [Average Hours Worked],
    COUNT(*) AS [Timesheet Entries]
FROM
    Employees e
JOIN
    TimeSheets t ON e.EmpID = t.EmpID
JOIN
    Projects p ON t.ProjectID = p.ProjectID
GROUP BY
    e.EmpID, e.EmpName, p.ProjectID, p.ProjectName
ORDER BY
    [Average Hours Worked] DESC;

-- 7) List employees who have not logged any hours.

SELECT
    e.EmpID,e.EmpName, e.Department
FROM
    Employees e
LEFT JOIN
    TimeSheets t ON e.EmpID = t.EmpID
WHERE
    t.EmpID IS NULL
ORDER BY
    e.EmpName;

-- 8) Show employees who worked more than 6 hours on any single day.

SELECT DISTINCT
    e.EmpID, e.EmpName, e.Department, t.WorkDate, t.HoursWorked
FROM
    Employees e
JOIN
    TimeSheets t ON e.EmpID = t.EmpID
WHERE
    t.HoursWorked > 6
ORDER BY
    t.HoursWorked DESC;

-- 9) Rank employees by total hours worked (across all projects).

-- 9) Rank employees by total hours worked (across all projects)

SELECT
    e.EmpID, e.EmpName, e.Department,
    SUM(t.HoursWorked) AS [Total Hours Worked],
    RANK() OVER (ORDER BY SUM(t.HoursWorked) DESC) AS [Rank]
FROM
    Employees e
JOIN
    TimeSheets t ON e.EmpID = t.EmpID
GROUP BY
    e.EmpID, e.EmpName, e.Department
ORDER BY
    [Total Hours Worked] DESC;

--10) List each project with number of employees assigned and total hours spent.

SELECT
    p.ProjectID, p.ProjectName, p.Department,
    COUNT(DISTINCT t.EmpID) AS [Number of Employees],
    SUM(t.HoursWorked) AS [Total Hours Spent]
FROM
    Projects p
JOIN
    TimeSheets t ON p.ProjectID = t.ProjectID
GROUP BY
    p.ProjectID, p.ProjectName, p.Department
ORDER BY
    [Total Hours Spent] DESC;

--Bonus Challenge
-- Write a query to find the top 2 employees in each department based on total hours worked.

WITH DepartmentHours AS (
    SELECT
        e.EmpID,e.EmpName,e.Department,
        SUM(t.HoursWorked) AS TotalHours,
        DENSE_RANK() OVER (PARTITION BY e.Department ORDER BY SUM(t.HoursWorked) DESC) AS DeptRank
    FROM
        Employees e
    JOIN
        TimeSheets t ON e.EmpID = t.EmpID
    GROUP BY
        e.EmpID, e.EmpName, e.Department
)
SELECT
    EmpID,EmpName,Department,TotalHours
FROM
    DepartmentHours
WHERE
    DeptRank <= 2
ORDER BY
    Department,TotalHours DESC;

