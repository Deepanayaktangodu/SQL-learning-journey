CREATE TABLE Employees (
							EmpID INT PRIMARY KEY,
							EmpName VARCHAR(50) NOT NULL CHECK(LEN(EmpName)>=2),
							Department VARCHAR(30) NOT NULL CHECK(LEN(Department)>=2),
							HireDate DATE NOT NULL DEFAULT GETDATE() CHECK(HireDate<=GETDATE()),
							Salary DECIMAL(10,2) NOT NULL CHECK(Salary>0),
							ManagerID INT NULL,
							CONSTRAINT FK_ManagerID FOREIGN KEY (ManagerID) REFERENCES Employees(EmpID) ON UPDATE NO ACTION ON DELETE NO ACTION
						);

CREATE TABLE Projects (
							ProjectID INT PRIMARY KEY,
							ProjectName VARCHAR(50) NOT NULL CHECK(LEN(ProjectName)>=2),
							Department VARCHAR(30) NOT NULL CHECK(LEN(Department)>=2),
							StartDate DATE DEFAULT GETDATE(),
							EndDate DATE DEFAULT GETDATE(),
							CONSTRAINT CHK_EndDate CHECK (EndDate >= StartDate)
						);

CREATE TABLE EmployeeProjects (
								EmpID INT,
								ProjectID INT NOT NULL,
								HoursWorked INT NOT NULL CHECK(HoursWorked>=0),
								PRIMARY KEY (EmpID, ProjectID),
								FOREIGN KEY (EmpID) REFERENCES Employees(EmpID) ON UPDATE CASCADE ON DELETE NO ACTION,
								FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID) ON UPDATE CASCADE ON DELETE NO ACTION
							);

Create Index Idx_Employees_EmpName on Employees(EmpName);
Create Index Idx_Employees_Department on Employees(Department);
Create Index Idx_Employees_Salary on Employees(Salary);
CREATE INDEX Idx_Employees_ManagerID ON Employees(ManagerID)
Create Index Idx_Projects_ProjeectName on Projects(ProjectName);
Create Index Idx_Projects_Department on Projects(Department);
CREATE INDEX Idx_Projects_StartDate ON Projects(StartDate)
Create Index Idx_EmployeeProjects_EmpID on EmployeeProjects(EmpID);
Create Index Idx_EmployeeProjects_ProjectID on EmployeeProjects(ProjectID);

INSERT INTO Employees VALUES
(1, 'Alice', 'HR', '2020-01-15', 50000, NULL),
(2, 'Bob', 'Finance', '2019-03-01', 65000, 1),
(3, 'Charlie', 'Finance', '2021-07-01', 60000, 2),
(4, 'David', 'IT', '2022-01-20', 55000, 1),
(5, 'Emma', 'IT', '2018-11-11', 70000, 4),
(6, 'Frank', 'Sales', '2021-06-15', 45000, 2),
(7, 'Grace', 'Sales', '2019-09-10', 48000, 6);

INSERT INTO Projects VALUES
(101, 'Payroll System', 'Finance', '2023-01-01', '2023-06-30'),
(102, 'Recruitment Portal', 'HR', '2023-02-01', '2023-08-01'),
(103, 'CRM Development', 'Sales', '2023-03-15', '2023-09-15'),
(104, 'Network Upgrade', 'IT', '2023-04-01', '2023-10-01');

INSERT INTO EmployeeProjects VALUES
(2, 101, 120),
(3, 101, 80),
(1, 102, 150),
(4, 104, 100),
(5, 104, 200),
(6, 103, 180),
(7, 103, 160);

Select * from Employees 
Select * from Projects 
Select * from EmployeeProjects 

--1) Department Salary Analysis
--Find the average, minimum, and maximum salary for each department.
Select 
	Department,
	ROUND(AVG(Salary),2) as [Average Salary],
	MIN(Salary) as [Minimum Salary],
	MAX(Salary) as [Maximum Salary]
from Employees 
group by Department;

--2) Manager-Employee Relationship
--List each employee along with their manager’s name.
SELECT
    E.EmpName AS EmployeeName,M.EmpName AS ManagerName
FROM Employees AS E
LEFT JOIN Employees AS M ON E.ManagerID = M.EmpID;

--3) Longest Tenure Employees
--Find the top 3 employees with the longest tenure in the company.
SELECT TOP 3
    EmpID,EmpName,Department,HireDate,
    DATEDIFF(DAY, HireDate, GETDATE()) AS [Tenure In Days],
    DATEDIFF(YEAR, HireDate, GETDATE()) AS [Tenure In Years]
FROM Employees 
ORDER BY [Tenure In Days] DESC;

--4) Project Allocation
--Show how many employees are working in each project.
SELECT
    p.ProjectID,p.ProjectName,p.Department,
    COUNT(DISTINCT ep.EmpID) AS [Employee Count],
    STRING_AGG(e.EmpName, ', ') WITHIN GROUP (ORDER BY e.EmpName) AS [Employee Names] 
FROM Projects p
LEFT JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
LEFT JOIN Employees e ON ep.EmpID = e.EmpID
GROUP BY p.ProjectID, p.ProjectName, p.Department
ORDER BY [Employee Count] DESC;

--5) Employee Project Hours
--Find the employee who has contributed the maximum hours to projects.
Select Top 1
	e.EmpID,e.EmpName,e.Department,
	ROUND(SUM(ep.HoursWorked),2) as [Hours Worked on Projects]
from Employees e
join EmployeeProjects ep on ep.EmpID =e.EmpID 
group by e.EmpID,e.EmpName,e.Department 
order by [Hours Worked on Projects] Desc;

--6) Cross Department Projects
--Identify employees working on projects outside their own department.
Select
	e.EmpID,e.EmpName,e.Department as [Employee Department],
	p.ProjectID,p.ProjectName,p.Department as [Project Department],
	ep.HoursWorked
from Employees e
join EmployeeProjects ep on e.EmpID =ep.EmpID 
join Projects p on p.ProjectID =ep.ProjectID 
where e.Department<>p.Department 
order by e.EmpName,p.ProjectName;

--7) Project Duration
--Calculate the total number of days each project ran.
SELECT
    ProjectID,ProjectName,Department,StartDate,EndDate,
    DATEDIFF(DAY, StartDate, COALESCE(EndDate, GETDATE())) AS [Project Duration in Days],
    CASE 
        WHEN EndDate IS NULL THEN 'Ongoing'
        ELSE 'Completed'
    END AS [Project Status]
FROM Projects 
ORDER BY [Project Duration in Days] DESC;

--8) Salary Growth Potential
--Assume each employee’s salary grows by 10% yearly. Show projected salaries for 2025.
Select
	EmpID,EmpName,Department,Salary as [Present Salary],
	ROUND(Salary * 1.10, 2) AS [2025 Projected Salary],
    ROUND(Salary * 0.10, 2) AS [Salary Increase],
    ROUND((Salary * 1.10) - Salary, 2) AS [Annual Increase Amount]
FROM Employees
ORDER BY [Annual Increase Amount] DESC;

--9) Department Contribution to Projects
--Find which department contributed the highest total hours across all projects.
SELECT TOP 1
    p.Department,
    ROUND(SUM(ep.HoursWorked), 2) AS [Total Hours Worked],
    COUNT(DISTINCT ep.ProjectID) AS [Number of Projects],
    COUNT(DISTINCT ep.EmpID) AS [Number of Employees]
FROM Projects p
JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
GROUP BY p.Department
ORDER BY [Total Hours Worked] DESC;

--10) Window Function – Salary Ranking
--Rank employees by salary within each department.
WITH EmployeeSalary AS (
    SELECT
        EmpID,EmpName,Department,Salary,
        RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS SalaryRank
    FROM Employees)
SELECT
    EmpID,EmpName,Department,Salary,SalaryRank
FROM EmployeeSalary
ORDER BY Department, SalaryRank;

--Bonus Challenge
--11) Recursive CTE – Management Hierarchy: 
--Build a hierarchy tree showing each employee and their reporting chain up to the top manager.
WITH ManagementHierarchy AS (
    SELECT
        EmpID,EmpName,Department,ManagerID,
        1 AS Level,
        CAST(EmpName AS VARCHAR(MAX)) AS HierarchyPath
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    SELECT
        e.EmpID,e.EmpName,e.Department,e.ManagerID,
        mh.Level + 1 AS Level,
        CAST(mh.HierarchyPath + ' -> ' + e.EmpName AS VARCHAR(MAX)) AS HierarchyPath
    FROM Employees e
    INNER JOIN ManagementHierarchy mh ON e.ManagerID = mh.EmpID
    WHERE mh.Level < 10 -- Safety limit to prevent infinite recursion
)
SELECT
    EmpID,EmpName,Department,
    Level,HierarchyPath AS [Reporting Chain]
FROM ManagementHierarchy
ORDER BY Level, HierarchyPath;







	



