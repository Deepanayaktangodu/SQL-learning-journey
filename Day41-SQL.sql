Create table Employees (
						EmpID int Primary Key,
						Name varchar(50) not null Check(len(Name)>=2),
						Department varchar(50) not null Check(Department in('HR','IT','Finance')),
						HireDate date not null default getdate() Check(HireDate<=getdate()),
						Salary decimal (10,2) not null check (Salary>0),
						ManagerID int not null,
						Foreign Key (ManagerID) references Employees(EmpID)
						);

Create table Performance (
							EmpID int not null,
							Year bigint not null Check(Year>0),
							Rating int not null Check(Rating between 1 and 5),
							ProjectsCompleted int not null Check(ProjectsCompleted>=0),
							OvertimeHours int not null check(OvertimeHours>=0),
							Primary Key (EmpID, Year),
							foreign key(EmpID) references Employees(EmpID) on update cascade on delete no action
						);

Create Index Idx_Employees_Name on Employees(Name);
Create Index Idx_Employees_Department on Employees(Department);
Create Index Idx_Performance_EmpID on Performance(EmpID);
Create Index Idx_Employees_ManagerID on Employees(ManagerID);

INSERT INTO Employees (EmpID, Name, Department, HireDate, Salary, ManagerID)
VALUES
(101, 'Alice', 'HR', '2018-03-10', 55000, 201),
(102, 'Bob', 'IT', '2020-07-15', 65000, 202),
(103, 'Charlie', 'Finance', '2019-11-01', 70000, 203),
(104, 'Diana', 'IT', '2021-05-20', 60000, 202),
(105, 'Ethan', 'Finance', '2017-01-05', 72000, 203),
(106, 'Fiona', 'HR', '2022-02-10', 50000, 201),
(201, 'George', 'HR', '2015-08-12', 85000, NULL),
(202, 'Hannah', 'IT', '2014-04-01', 95000, NULL),
(203, 'Ian', 'Finance', '2016-10-22', 90000, NULL);

ALTER TABLE Employees ALTER COLUMN ManagerID int NULL;

INSERT INTO Performance (EmpID, Year, Rating, ProjectsCompleted, OvertimeHours)
VALUES
(101, 2021, 4, 5, 20),
(101, 2022, 5, 6, 25),
(102, 2021, 3, 3, 15),
(102, 2022, 4, 4, 18),
(103, 2021, 5, 7, 30),
(103, 2022, 4, 6, 28),
(104, 2022, 3, 2, 10),
(105, 2021, 4, 5, 22),
(105, 2022, 5, 7, 26),
(106, 2022, 4, 3, 14);

Select* from Employees 
Select * from Performance 

--1) List all employees along with their department and manager’s name.
SELECT
  e.Name AS EmployeeName,e.Department,
  m.Name AS ManagerName
FROM Employees AS e
LEFT JOIN Employees AS m ON e.ManagerID = m.EmpID;

--2) Find employees who joined before 2020 and have salary above 60,000.
SELECT
  Name,HireDate,Salary
FROM Employees
WHERE HireDate < '2020-01-01' AND Salary > 60000;

--3) Retrieve employees whose performance rating was 5 in any year.
Select
	e.EmpID,e.Name as 'Employee Name',e.Department,p.Rating
from Employees e
join Performance p on e.EmpID =p.EmpID 
where p.Rating =5;

--4) Show employees with average performance rating > 4 across all years.
Select 
	e.EmpID,e.Name as 'Employee Name',e.Department,
	ROUND(AVG(p.Rating),2) as [Average performance rating]
from Employees e
join Performance p on e.EmpID=p.EmpID 
group by e.EmpID,e.Name,e.Department 
having AVG(p.Rating) >4
order by [Average performance rating] Desc;

--5) Find the top 3 highest paid employees in the company.
SELECT top 3
  EmpID, Name,Department, Salary
FROM Employees
ORDER BY Salary DESC;

--6) For each department, find the employee with the highest salary (use window functions).
With HighestDepartmentSalary as (
					Select
						EmpID,Name,Department,Salary,
						Rank() over (Partition by Department Order by Salary Desc) as SalaryRank
						from Employees)
Select
	EmpID,Name,Department,Salary from HighestDepartmentSalary 
where SalaryRank =1;

--7) Calculate the yearly average rating per department.
SELECT
  e.Department,p.Year,
  AVG(p.Rating) AS AverageRating
FROM Employees AS e
JOIN Performance AS p ON e.EmpID = p.EmpID
GROUP BY e.Department, p.Year
ORDER BY e.Department, p.Year;

--8) Identify employees who have improved their rating from 2021 to 2022.
SELECT
  e.Name,
  p1.Rating AS Rating2021,p2.Rating AS Rating2022
FROM Employees AS e
JOIN Performance AS p1 ON e.EmpID = p1.EmpID
JOIN Performance AS p2 ON e.EmpID = p2.EmpID
WHERE p1.Year = 2021 AND p2.Year = 2022 AND p2.Rating > p1.Rating;

--9) Find employees who have worked more than 20 overtime hours in any year.
Select
	e.EmpID,e.Name as 'Employee Name',e.Department,p.OvertimeHours 
from Employees e
join Performance p on e.EmpID =p.EmpID 
where p.OvertimeHours >20;

--10) Bonus Challenge: Write a query to rank employees based on total projects completed across all years.
With EmployeeProjects as (
				Select
					EmpID,
					SUM(ProjectsCompleted) as TotalProjects
					from Performance 
					group by EmpID),
RankedEmployees AS (
  SELECT
    e.Name,ep.TotalProjects,
    RANK() OVER (ORDER BY ep.TotalProjects DESC) AS RankNum
  FROM Employees AS e
  JOIN EmployeeProjects AS ep
    ON e.EmpID = ep.EmpID)
SELECT
  Name,TotalProjects,RankNum
FROM RankedEmployees
ORDER BY RankNum;
