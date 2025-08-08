Create table Employees (
						EmployeeID int primary key,
						EmployeeName varchar(50) not null,
						DepartmentID int not null,
						JoinDate date not null default getdate() check(JoinDate<=getdate()),
						Gender varchar(20) not null check (Gender in ('Male','Female')),
						foreign key (DepartmentID) references Departments(DepartmentID) on update cascade
						);

Create table Departments (
							DepartmentID int Primary key,
							DepartmentName varchar(50) not null,
							);

Create table Salaries(
						SalaryID int primary key,
						EmployeeID int not null,
						Month varchar(20) not null CHECK (Month IN (
						'January', 'February', 'March', 'April', 'May', 'June',
						'July', 'August', 'September', 'October', 'November', 'December')),
						BaseSalary decimal (10,2) not null check(BaseSalary>0),
						Bonus decimal (10,2) not null check(Bonus>=0),
						foreign key(EmployeeID) references Employees(EmployeeID) on update cascade,
						UNIQUE (EmployeeID, Month)   -- Prevent duplicate salary entries for same employee in same month
						);

Create table Leaves (
						LeaveID int primary key,
						EmployeeID int not null,
						LeaveDate date not null,
						LeaveType varchar(30) not null check (LeaveType in ('Sick','Casual')),
						foreign key(EmployeeID) references Employees(EmployeeID) on update cascade
					);

Create Index Idx_Employees_DepartmentID on Employees(DepartmentID);
Create Index Idx_Salaries_EmployeeID on Salaries(EmployeeID);
Create Index Idx_Leaves_EmployeeID on Leaves(EmployeeID);

INSERT INTO Employees VALUES
(1, 'Anjali Rao', 101, '2020-01-15', 'Female'),
(2, 'Ravi Kumar', 102, '2019-03-20', 'Male'),
(3, 'Meera Iyer', 101, '2021-07-10', 'Female'),
(4, 'Karan Malhotra', 103, '2018-11-05', 'Male');

INSERT INTO Departments VALUES
(101, 'Finance'),
(102, 'HR'),
(103, 'Engineering');

INSERT INTO Salaries VALUES
(201, 1, 'January', 50000, 5000),
(202, 2, 'January', 45000, 3000),
(203, 3, 'January', 48000, 4000),
(204, 4, 'January', 60000, 6000),
(205, 1, 'February', 50000, 4500),
(206, 2, 'February', 45000, 3500);

INSERT INTO Leaves VALUES
(301, 1, '2024-01-10', 'Sick'),
(302, 2, '2024-01-12', 'Casual'),
(303, 1, '2024-02-02', 'Casual'),
(304, 3, '2024-02-15', 'Sick');

Select *from Departments 
Select * from Employees 
Select * from Salaries
Select * from Leaves 

--1) List all employees with their department names and date of joining.
Select
	e.EmployeeID,e.EmployeeName,
	d.DepartmentID,d.DepartmentName,e.JoinDate
from
	Employees e
join
	Departments d
on e.DepartmentID =d.DepartmentID
ORDER BY
    e.EmployeeID;

--2) Show the monthly salary (base + bonus) for each employee.
SELECT
    e.EmployeeID,e.EmployeeName,
    d.DepartmentName,s.Month,
    (s.BaseSalary + s.Bonus) AS MonthlySalary
FROM
    Employees e
JOIN
    Departments d ON e.DepartmentID = d.DepartmentID
JOIN
    Salaries s ON e.EmployeeID = s.EmployeeID
ORDER BY
    e.EmployeeID, 
    CASE s.Month
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

--3) Display departments with average total salary greater than 50000.
Select
	d.DepartmentID,d.DepartmentName,
	ROUND(AVG(s.BaseSalary + s.Bonus),2) as [AVG Total Salary]
from
	Departments d
join
	Employees e
on d.DepartmentID  =e.DepartmentID 
join
	Salaries s
on e.EmployeeID =s.EmployeeID 
Group by
	d.DepartmentID,d.DepartmentName
Having
	AVG(s.BaseSalary + s.Bonus) >50000
Order by
	[AVG Total Salary] Desc;

--4) Find employees who have taken more than one leave.
SELECT
    e.EmployeeID,e.EmployeeName,d.DepartmentName,
    COUNT(l.LeaveID) AS TotalLeavesTaken
FROM
    Employees e
JOIN
    Leaves l ON e.EmployeeID = l.EmployeeID
JOIN
    Departments d ON e.DepartmentID = d.DepartmentID
GROUP BY
    e.EmployeeID, e.EmployeeName, d.DepartmentName
HAVING
    COUNT(l.LeaveID) > 1
ORDER BY
    TotalLeavesTaken DESC;

--5) Identify the department with the highest total bonus payout.
Select top 1
	d.DepartmentID,d.DepartmentName,
	SUM(s.Bonus) as [Total Bonus Payout]
from
	Departments d
join
	Employees e
on e.DepartmentID =d.DepartmentID 
join
	Salaries s
on e.EmployeeID =s.EmployeeID 
Group by
	d.DepartmentID,d.DepartmentName
Order by
	[Total Bonus Payout]  Desc;

--6) Show all employees who haven't received salary for February.
SELECT
    e.EmployeeID,e.EmployeeName,d.DepartmentName
FROM
    Employees e
JOIN
    Departments d ON e.DepartmentID = d.DepartmentID
WHERE
    e.EmployeeID NOT IN (
        SELECT EmployeeID 
        FROM Salaries 
        WHERE Month = 'February')
ORDER BY
    e.EmployeeID;

--7) Display total number of leaves per employee and their department.
SELECT
    e.EmployeeID,e.EmployeeName,d.DepartmentName,
    COUNT(l.LeaveID) AS TotalLeaves
FROM
    Employees e
JOIN
    Departments d ON e.DepartmentID = d.DepartmentID
LEFT JOIN
    Leaves l ON e.EmployeeID = l.EmployeeID
GROUP BY
    e.EmployeeID, e.EmployeeName, d.DepartmentName
ORDER BY
    TotalLeaves DESC;

--8) Rank employees based on their January total salary (base + bonus).
WITH EmployeeSalary AS (
    SELECT
        e.EmployeeID,e.EmployeeName,d.DepartmentName,
        (s.BaseSalary + s.Bonus) AS TotalSalary,
        RANK() OVER (ORDER BY (s.BaseSalary + s.Bonus) DESC) AS SalaryRank,
        DENSE_RANK() OVER (ORDER BY (s.BaseSalary + s.Bonus) DESC) AS DenseSalaryRank,
        ROW_NUMBER() OVER (ORDER BY (s.BaseSalary + s.Bonus) DESC) AS RowNum
    FROM
        Employees e
    JOIN
        Departments d ON e.DepartmentID = d.DepartmentID
    JOIN
        Salaries s ON e.EmployeeID = s.EmployeeID
    WHERE
        s.Month = 'January'
)
SELECT
    EmployeeID,EmployeeName,DepartmentName,
    TotalSalary,SalaryRank,DenseSalaryRank,RowNum
FROM
    EmployeeSalary
ORDER BY
    SalaryRank;

--9) List employees who took leave in January but not in February.
Select distinct
	e.EmployeeID,e.EmployeeName,d.DepartmentName
from
	Employees e
JOIN
    Departments d ON e.DepartmentID = d.DepartmentID
JOIN
    Leaves jan ON e.EmployeeID = jan.EmployeeID
    AND MONTH(jan.LeaveDate) = 1
    AND YEAR(jan.LeaveDate) = YEAR(GETDATE())
LEFT JOIN
    Leaves feb ON e.EmployeeID = feb.EmployeeID
    AND MONTH(feb.LeaveDate) = 2
    AND YEAR(feb.LeaveDate) = YEAR(GETDATE())
WHERE
    feb.LeaveID IS NULL
ORDER BY
    e.EmployeeName;

--10) Show departments with no employees currently listed.
SELECT
    d.DepartmentID,d.DepartmentName
FROM
    Departments d
LEFT JOIN
    Employees e ON d.DepartmentID = e.DepartmentID
WHERE
    e.EmployeeID IS NULL
ORDER BY
    d.DepartmentName;

--Bonus Challenge
--Find the top 2 departments with the highest average salary per employee (include base + bonus).
WITH DepartmentSalaries AS (
    SELECT
        d.DepartmentID,d.DepartmentName,
        ROUND(AVG(s.BaseSalary + s.Bonus), 2) AS AverageTotalSalary,
        DENSE_RANK() OVER (ORDER BY AVG(s.BaseSalary + s.Bonus) DESC) AS Rank
    FROM
        Departments d
    JOIN
        Employees e ON d.DepartmentID = e.DepartmentID
    JOIN
        Salaries s ON e.EmployeeID = s.EmployeeID
    GROUP BY
        d.DepartmentID, d.DepartmentName)
SELECT
    DepartmentID,DepartmentName,AverageTotalSalary
FROM
    DepartmentSalaries
WHERE
    Rank <= 2
ORDER BY
    Rank;
	