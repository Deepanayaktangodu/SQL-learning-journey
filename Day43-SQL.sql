Create table Employees (
							EmpID int Primary key,
							Name varchar(50) not null unique Check(len(Name)>=2),
							Department varchar(25) not null Check(Department in ('IT','HR','Finance')),
							JoinDate date not null default getdate(),
							Salary decimal(8,2) not null Check(Salary>0),
							ManagerID int null,
							foreign key(ManagerID) references Employees(EmpID)
						);

Create table Projects(
						ProjectID int Primary key,
						ProjectName varchar(100) not null UNIQUE Check(len(ProjectName)>=2),
						Department varchar(25) not null,
						Budget decimal(8,2) not null Check(Budget>0),
						StartDate date not null default getdate(),
						EndDate date not null default getdate()
						);

Create table EmployeeProjects(
								EmpID int not null,
								ProjectID int not null,
								HoursWorked int not null Check(HoursWorked>=0),
								Rating decimal(2,1) not null Check(Rating between 1 and 5),
								PRIMARY KEY (EmpID, ProjectID),
								foreign key(EmpID) references Employees (EmpID) on update cascade on delete no action,
								foreign key(ProjectID) references Projects(ProjectID) on update cascade on delete no action
								);

Create Index Idx_Employees_Name on Employees(Name);
Create Index Idx_Employees_Department on Employees(Department);
Create Index Idx_Projects_ProjectName on Projects(ProjectName);
Create index Idx_Projects_Budget on Projects(Budget);
Create Index Idx_Projects_Department on Projects(Department);
Create Index Idx_EmployeeProjects_Rating on EmployeeProjects(Rating);

INSERT INTO Employees (EmpID, Name, Department, JoinDate, Salary, ManagerID) VALUES
(1, 'Alice', 'IT', '2019-01-15', 75000, NULL),
(2, 'Bob', 'IT', '2020-03-10', 60000, 1),
(3, 'Charlie', 'HR', '2018-06-05', 50000, NULL),
(4, 'Diana', 'HR', '2021-02-20', 45000, 3),
(5, 'Ethan', 'Finance', '2017-11-12', 85000, NULL),
(6, 'Fiona', 'Finance', '2020-08-01', 55000, 5),
(7, 'George', 'IT', '2021-05-10', 58000, 2),
(8, 'Hannah', 'HR', '2019-09-25', 52000, 3),
(9, 'Ian', 'Finance', '2022-01-12', 48000, 6),
(10, 'Jack', 'IT', '2019-11-11', 62000, 1);

INSERT INTO Projects (ProjectID, ProjectName, Department, Budget, StartDate, EndDate) VALUES
(101, 'Payroll System', 'HR', 200000, '2020-01-01', '2020-12-31'),
(102, 'Fraud Detection', 'Finance', 300000, '2020-06-15', '2021-06-15'),
(103, 'Cloud Upgrade', 'IT', 250000, '2021-01-01', '2021-12-31'),
(104, 'HR Portal', 'HR', 150000, '2021-07-01', '2022-06-30'),
(105, 'Trading System', 'Finance', 400000, '2021-09-01', '2022-08-31'),
(106, 'AI Chatbot', 'IT', 350000, '2022-01-01', '2022-12-31');

INSERT INTO EmployeeProjects (EmpID, ProjectID, HoursWorked, Rating) VALUES
(2, 103, 1600, 4.5),
(7, 103, 1200, 4.2),
(10, 103, 1400, 4.8),
(4, 101, 1000, 4.1),
(8, 101, 800, 3.9),
(4, 104, 1200, 4.3),
(8, 104, 900, 4.0),
(6, 102, 1800, 4.6),
(9, 105, 1000, 4.2),
(6, 105, 1600, 4.5),
(2, 106, 1500, 4.7),
(7, 106, 1400, 4.4);

Select* from Employees 
Select * from Projects 
Select * from EmployeeProjects 

--1) Find the average salary per department and rank departments by salary using a window function.
SELECT
    Department,
    CAST(AVG(Salary) AS DECIMAL(8, 2)) AS AverageSalary,
    RANK() OVER (ORDER BY AVG(Salary) DESC) AS Rank
FROM Employees
GROUP BY Department
ORDER BY Rank ASC;

--2) List employees who are managers (i.e., have subordinates).
Select
	EmpID,Name as 'Employee Name',Department
from Employees 
where EmpID in (
		Select distinct ManagerID 
		from Employees 
		where ManagerID is not null)
order by EmpID;
			
--3) Identify the employee with the highest total hours worked across all projects.
Select top 1
	e.EmpID ,e.Name as 'Employee Name',e.Department,
	SUM(ep.HoursWorked) as [Total Hours Worked]
from Employees e
join EmployeeProjects ep on e.EmpID=ep.EmpID  
group by e.EmpID,e.Name,e.Department 
order by [Total Hours Worked] Desc;

--4) For each project, find the top-rated employee (highest rating) using ROW_NUMBER().
WITH RankedEmployees AS (
				SELECT
						p.ProjectID,p.ProjectName,
						e.EmpID,e.Name AS "Employee Name",ep.Rating,
						ROW_NUMBER() OVER(PARTITION BY p.ProjectID ORDER BY ep.Rating DESC) AS RankNum
			FROM EmployeeProjects ep
			JOIN Projects p ON ep.ProjectID = p.ProjectID
			JOIN Employees e ON ep.EmpID = e.EmpID)
SELECT
    ProjectID,ProjectName,EmpID,"Employee Name",Rating
FROM RankedEmployees
WHERE RankNum = 1
ORDER BY ProjectID;

--5) Write a query to calculate the total budget handled by each department and rank them.
Select
	Department,
	SUM(Budget) as [Total Budget],
	Rank() over (Order by SUM(Budget) Desc) as Rank
from Projects
Group by Department 
Order by [Total Budget] Desc;

--6) Find employees who have worked on more than 1 project.
Select
	e.EmpID,e.Name as 'Employee Name',e.Department,
	Count(ep.ProjectID) as [Project Count], STRING_AGG(p.ProjectName, ', ') AS "Projects"
from Employees e
join EmployeeProjects ep on e.EmpID =ep.EmpID 
join Projects p on p.ProjectID =ep.ProjectID 
group by e.EmpID,e.Name,e.Department 
having Count(distinct ep.ProjectID)>1
order by [Project Count] Desc;

--7) Calculate the employee-wise weighted average rating (weighted by HoursWorked).
Select
	e.EmpID,e.Name as 'Employee Name',e.Department,
	SUM(ep.Rating*ep.HoursWorked)/SUM(ep.HoursWorked) as 'Weighted Average Rating'
from Employees e
join EmployeeProjects ep on e.EmpID =ep.EmpID 
group by e.EmpID,e.Name,e.Department 
order by 'Weighted Average Rating' Desc;

--8) Retrieve employees who earn above their departmental average salary.
WITH DepartmentAverages AS (
    SELECT
        Department,AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY Department)
SELECT
    e.EmpID,e.Name,e.Department,e.Salary,da.AvgSalary
FROM Employees e
JOIN DepartmentAverages da ON e.Department = da.Department
WHERE e.Salary > da.AvgSalary
ORDER BY e.Department, e.Salary DESC;

--9) Using a recursive CTE, list the hierarchy of employees under manager Alice (EmpID=1).
WITH EmployeeHierarchy AS (
    SELECT
        EmpID,Name,ManagerID,0 AS Level
    FROM Employees
    WHERE EmpID = 1
 UNION ALL
 SELECT
        e.EmpID,e.Name,e.ManagerID,eh.Level + 1 AS Level
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmpID)
SELECT
    EmpID,Name,ManagerID,Level
FROM EmployeeHierarchy
ORDER BY Level, EmpID;

--10) Bonus Challenge : 
-- Find the top 3 employees across the company who contributed the most hours to projects in 2021 only.
Select Top 3
	e.EmpID,e.Name as 'Employee Name',e.Department,
	SUM(ep.HoursWorked) as [Total Hours Worked]
from Employees e
join EmployeeProjects ep on e.EmpID =ep.EmpID 
join Projects p on p.ProjectID=ep.ProjectID 
where NOT (p.StartDate > '2021-12-31' OR p.EndDate < '2021-01-01')
group by e.EmpID,e.Name,e.Department 
order by [Total Hours Worked] Desc;