Create table Users (
					UserID int Primary key,
					Name Char (50) not null,
					Age int not null Check (Age between 10 and 120),
					Country char (50) not null
					);

Create table Workouts(
						WorkoutID int Primary key,
						UserID int not null,
						WorkoutType varchar(75) not null,
						DurationMins int not null check (DurationMins between 1 and 300),
						CaloriesBurned int not null check (CaloriesBurned between 0 and 2000),
						WorkoutDate Date not null check (WorkoutDate<=GetDate()),
						foreign key (UserID) references Users(UserID) on delete cascade
					);

Create table HealthStats(
							StatID int Primary key,
							UserID int not null,
							StatDate Date not null check (StatDate<=GetDate()),
							WeighKG decimal (5,2) not null check (WeighKG>0),
							HeartRate int not null check (HeartRate between 30 and 220),
							SleepHours decimal (5,2) not null check (SleepHours between 0 and 24),
							foreign key (UserID) references Users (UserID) on delete cascade
						);

Create index Idx_Workouts_UserID on Workouts(UserID);
Create index Idx_HealthStats_UserID on HealthStats(UserID);

INSERT INTO Users (UserID, Name, Age, Country) VALUES
(1, 'Arjun', 28, 'India'),
(2, 'Bella', 35, 'USA'),
(3, 'Chen', 24, 'China'),
(4, 'Dmitry', 42, 'Russia'),
(5, 'Ella', 30, 'Germany');

INSERT INTO Workouts (WorkoutID, UserID, WorkoutType, DurationMins, CaloriesBurned, WorkoutDate) VALUES
(101, 1, ' Running ', 30, 300, '2024-06-01'),
(102, 2, 'Yoga', 45, 200, '2024-06-02'),
(103, 1, 'Cycling', 60, 500, '2024-06-03'),
(104, 3, 'Swimming', 40, 400, '2024-06-05'),
(105, 4, 'Running', 20, 180, '2024-06-07'),
(106, 5, 'Yoga', 50, 250, '2024-06-09'),
(107, 2, 'Cycling', 30, 270, '2024-06-10');

INSERT INTO HealthStats (StatID, UserID, StatDate, WeighKG, HeartRate, SleepHours) VALUES
(201, 1, '2024-06-01', 70.5, 72, 7.5),
(202, 2, '2024-06-01', 65.0, 68, 6.0),
(203, 3, '2024-06-01', 80.2, 75, 8.0),
(204, 4, '2024-06-01', 90.0, 80, 5.5),
(205, 5, '2024-06-01', 68.5, 70, 6.8);

Select * from Users 
Select * from Workouts 
Select * from HealthStats 

--1) List all users along with their country and age.

Select * from Users 

--2) Show the total calories burned by each user.
	
Select
	u.UserID,u.Name as 'User Name', SUM (w.CaloriesBurned) as [Total Calories Burned]
from
	Users u
left join
	Workouts w
on u.UserID=w.UserID 
Group by
	u.UserID,u.Name
Order by
	[Total Calories Burned] Desc;

--3) Find the average workout duration per workout type.

SELECT 
    TRIM(WorkoutType) AS WorkoutType, 
    ROUND(AVG(DurationMins), 2) AS 'Average Duration (mins)'
FROM 
    Workouts 
GROUP BY 
    TRIM(WorkoutType)
ORDER BY 
    'Average Duration (mins)' DESC;

--4) List the top 3 users who burned the most total calories.

SELECT TOP 3
    u.UserID,u.Name AS 'User Name',
    COALESCE(SUM(w.CaloriesBurned), 0) AS 'Total Calories Burned'
FROM
    Users u
LEFT JOIN
    Workouts w ON u.UserID = w.UserID
GROUP BY
    u.UserID, u.Name
ORDER BY
    'Total Calories Burned' DESC;

--5) Display user names along with their most frequent workout type.

With WorkoutFrequency as(
				Select
					u.UserID,u.Name AS 'User Name',
					TRIM(w.WorkoutType) AS WorkoutType,
					COUNT(*) AS WorkoutCount,
					Rank() over (Partition by u.UserID Order by COUNT(*) Desc) as Rank
				From
					Users u
				left join
					Workouts w
				on u.UserID =w.UserID 
				Group by
					u.UserID,u.Name,TRIM(w.WorkoutType))
Select
	 [User Name],
	 WorkoutType AS 'Most Frequent Workout Type',
	 WorkoutCount AS 'Number of Workouts'
FROM 
    WorkoutFrequency
WHERE 
    Rank = 1 OR WorkoutType IS NULL;

--6) Show the average heart rate and sleep hours per user.

Select 
	u.UserID,u.Name as 'User Name',
	ROUND (AVG(h.HeartRate),0) as [AVG Heart Rate],
	ROUND (AVG(h.SleepHours),1) as [AVG Sleep Hours]
from
	Users u
left join
	HealthStats h
on u.UserID =h.UserID 
Group by
	u.UserID,u.Name
ORDER BY
    u.UserID;

--7) Find the most popular workout type based on count.

SELECT TOP 1
    TRIM(WorkoutType) AS 'Most Popular Workout',
    COUNT(*) AS 'Total Sessions'
FROM
    Workouts
GROUP BY
    TRIM(WorkoutType)
ORDER BY
    'Total Sessions' DESC;

--8) List users who did not do any workouts.

SELECT
    u.UserID, u.Name AS 'User Name'
FROM
    Users u
LEFT JOIN
    Workouts w ON u.UserID = w.UserID
WHERE
    w.WorkoutID IS NULL;

--9) Display the user who had the longest single workout session.

SELECT TOP 1
    u.UserID,u.Name AS 'User Name',
    Trim (w.WorkoutType),
    w.DurationMins AS 'Longest Session (mins)',
    w.WorkoutDate
FROM
    Users u
JOIN
    Workouts w ON u.UserID = w.UserID
ORDER BY
    w.DurationMins DESC;

--10) For each country, find the average calories burned per user.

SELECT 
    u.Country,
    ROUND(AVG(ISNULL(w.CaloriesBurned, 0)), 2) AS 'Average Calories Burned per User'
FROM
    Users u
LEFT JOIN
    Workouts w ON u.UserID = w.UserID
GROUP BY
    u.Country
ORDER BY
    'Average Calories Burned per User' DESC;

--Bonus Challenge: 
--Identify users who worked out at least 3 times and maintained an average sleep of more than 7 hours.

Select
	u.UserID,u.Name as 'User Name',
	count (w.WorkoutID) as [Workout Sessions],
	Round (AVG(h.SleepHours),2) as [AVG Sleep Hours]
from
	Users u
join
	HealthStats h
on u.UserID =h.UserID 
join
	Workouts w
on h.UserID =w.UserID 
Group by
	u.UserID,u.Name
HAVING
    COUNT(w.WorkoutID) >= 3 AND
    AVG(h.SleepHours) > 7
ORDER BY
	 'Workout Sessions' DESC;
