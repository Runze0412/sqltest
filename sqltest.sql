CREATE DATABASE MonexInterview;
GO
USE MonexInterview;

-----------------------------
CREATE TABLE Holidays_Staging (
    DATE   NVARCHAR(50),
    REASON NVARCHAR(50),
);

--DROP TABLE Holidays
SELECT * FROM Holidays_Staging
TRUNCATE TABLE Holidays_Staging
-----------------------------

CREATE TABLE Holidays_Production (
    DATE  DATE NOT NULL,
    REASON NVARCHAR(200) NOT NULL,
);

SELECT * FROM Holidays_Production
--DROP TABLE Holidays_Production
TRUNCATE TABLE Holidays_Production
-----------------------------

IF OBJECT_ID('dbo.Calendar_Master', 'U') IS NOT NULL  -----------reusable
    DROP TABLE dbo.Calendar_Master;

CREATE TABLE Holidays_information(
	CalendarDate DATE,
	DayName	NVARCHAR(15), --Monday, Tuesday....
	IsWeekend BIT, --1 yes, 2 no.
	IsHoliday BIT DEFAULT 0,
	HolidayReason NVARCHAR(100)
);

--DROP TABLE Holidays_information

WITH DateSeries AS (
    SELECT CAST('2026-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d)
    FROM DateSeries
    WHERE d < '2026-12-31'
)

---insert data in the big table
INSERT INTO Holidays_information (CalendarDate, DayName, IsWeekend)
SELECT 
    d AS CalendarDate,
    DATENAME(WEEKDAY, d) AS DayName,
    CASE WHEN DATENAME(WEEKDAY, d) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END AS IsWeekend
FROM DateSeries
OPTION (MAXRECURSION 366);

-------------join with Holidays table
UPDATE C
SET 
    C.IsHoliday = 1,
    C.HolidayReason = H.REASON
FROM Holidays_information C
INNER JOIN dbo.Holidays_Production H ON C.CalendarDate = H.[DATE];

-------------
SELECT * FROM Holidays_information

--------------------------------------basic logicSELECT COUNT(*) as business_daysFROM Holidays_informationWHERE CalendarDate BETWEEN '2026-01-01' AND '2026-01-05'  AND IsWeekend = 0 AND IsHoliday = 0;

SELECT CalendarDate, HolidayReasonFROM Holidays_informationWHERE CalendarDate BETWEEN '2026-01-01' AND '2026-01-05'  AND IsHoliday = 1;

---------------- Function
CREATE FUNCTION dbo.GetBusinessdays(
	@StartDate DATE,
	@EndDate DATE
)

RETURNS INT
AS
BEGIN
	IF @StartDate > @EndDate
	BEGIN
	DECLARE @ErrorMsg INT = CAST('Error: StartDate cannot be greater than EndDate!' AS INT);
	END

	DECLARE @WorkDays INT;
	SELECT @WorkDays = COUNT(*)
	FROM Holidays_information
	WHERE CalendarDate BETWEEN @StartDate and @EndDate
		AND IsWeekend = 0  --remove weendends
		AND IsHoliday = 0; -- remove holidays

	RETURN ISNULL(@WorkDays,0)  --make sure NULL to 0 for any unexpected situation
END;

drop function dbo.GetBusinessdays

-----------------Test
SELECT dbo.GetBusinessdays('2026-01-01','2026-01-05') AS business_days

SELECT dbo.GetBusinessdays('2026-07-01','2026-01-05')


-----------------------------------------------------------------------

CREATE FUNCTION dbo.GetBusinessdays_test(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN

    RETURN (
        SELECT 
            CASE 
                WHEN @StartDate > @EndDate 
                THEN CAST('Error: StartDate > EndDate' AS INT)  
                ELSE COUNT(*) 
            END
        FROM Holidays_information 
        WHERE CalendarDate BETWEEN @StartDate AND @EndDate
          AND IsWeekend = 0
          AND IsHoliday = 0
    );
END;

SELECT dbo.GetBusinessdays_test('2026-01-01','2026-01-05') AS business_days

SELECT dbo.GetBusinessdays_test('2026-07-01','2026-01-05')
drop function dbo.GetBusinessdays_test


-----------------------------------------------Function
CREATE FUNCTION dbo.GetBusinessdays(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN

    RETURN (
        SELECT 
            CASE 
                WHEN @StartDate > @EndDate 
                THEN CAST('Error: StartDate cannot be greater than EndDate!' AS INT) ---Error handling
                ELSE COUNT(*) 
            END
        FROM Holidays_information 
        WHERE CalendarDate > @StartDate   --CalendarDate BETWEEN @StartDate AND @EndDate
		  AND CalendarDate <= @EndDate
          AND IsWeekend = 0
          AND IsHoliday = 0
    );
END;
------------------------------------------------test
SELECT * FROM Holidays_information

SELECT dbo.GetBusinessdays('2026-04-01','2026-04-02') AS business_days --1 right
SELECT dbo.GetBusinessdays('2026-04-01','2026-04-07') AS business_days --2 right

SELECT dbo.GetBusinessdays('2026-01-01','2026-01-02') AS business_days  --1 right

SELECT dbo.GetBusinessdays('2026-01-19','2026-01-20') AS business_days  --1 right




SELECT dbo.GetBusinessdays('2026-07-01','2026-01-05') AS business_days