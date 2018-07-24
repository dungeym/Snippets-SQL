
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnConvertTicksToDateTime')
BEGIN
	DROP FUNCTION dbo.fnConvertTicksToDateTime
	PRINT 'DROP FUNCTION dbo.fnConvertTicksToDateTime'
END
GO


CREATE FUNCTION dbo.fnConvertTicksToDateTime (@Ticks BIGINT)      
RETURNS DATETIME
AS
BEGIN
/*
A single 'tick' represents one hundred nanoseconds or one ten-millionth of a second. 

So a Tick value represents the number of 100-nanosecond intervals that have elapsed since:
- 12:00:00 midnight, January 1, 0001 
- 0:00:00 UTC on January 1, 0001, in the Gregorian calendar

This is also the DateTime.MinValue. 
It does not include the number of ticks that are attributable to leap seconds.

https://msdn.microsoft.com/en-us/library/system.datetime.ticks(v=vs.110).aspx

The minimum DATETIME SQL Server can store/process is January 1, 1753 00:00:00.
https://docs.microsoft.com/en-us/sql/t-sql/data-types/datetime-transact-sql?view=sql-server-2017
*/

	DECLARE @TicksPerNanosecond FLOAT = 100
	DECLARE @Nanosecond FLOAT = 1 / @TicksPerNanosecond
	DECLARE @Millisecond FLOAT = (@Nanosecond * 1000000)
	DECLARE @Second FLOAT = (@Millisecond * 1000)
	DECLARE @Minute FLOAT = (@Second * 60)
	DECLARE @Hour FLOAT = (@Minute * 60)
	DECLARE @Day FLOAT = (@Hour * 24)
		
	DECLARE @BaseDate DATETIME = '1753-01-01 00:00:00'
	DECLARE @January_01_01_1753_AsTicks FLOAT = 552877920000000000
	DECLARE @TicksSinceBaseDate FLOAT = @Ticks - @January_01_01_1753_AsTicks

	DECLARE @Division FLOAT
	DECLARE @Remaining FLOAT

	-- Calculate Days
	SET @Division = @TicksSinceBaseDate / @Day
	DECLARE @NumbersOfDays FLOAT = FLOOR(@Division)
	SET @Remaining = @Division - @NumbersOfDays

	-- Calculate Hours
	SET @Division = (@Day * @Remaining) / @Hour
	DECLARE @NumbersOfHours FLOAT = FLOOR(@Division)
	SET @Remaining = @Division - @NumbersOfHours

	-- Calculate Minutes
	SET @Division = (@Hour * @Remaining) / @Minute
	DECLARE @NumbersOfMinutes FLOAT = FLOOR(@Division)
	SET @Remaining = @Division - @NumbersOfMinutes

	-- Calculate Seconds
	SET @Division = (@Minute * @Remaining) / @Second
	DECLARE @NumbersOfSeconds FLOAT = FLOOR(@Division)
	SET @Remaining = @Division - @NumbersOfSeconds

	-- Calculate Milliseconds
	SET @Division = (@Second * @Remaining) / @Millisecond
	DECLARE @NumbersOfMilliseconds FLOAT = FLOOR(@Division)
	SET @Remaining = @Division - @NumbersOfMilliseconds

	-- Calculate Nanoseconds
	SET @Division = (@Millisecond * @Remaining) / @Nanosecond
	DECLARE @NumbersOfNanoseconds FLOAT = FLOOR(@Division)
	SET @Remaining = @Division - @NumbersOfNanoseconds


	DECLARE @OutputDate DATETIME 
	SET @OutputDate = DATEADD(DAY, @NumbersOfDays, @BaseDate)
	SET @OutputDate = DATEADD(HOUR, @NumbersOfHours, @OutputDate)
	SET @OutputDate = DATEADD(MINUTE, @NumbersOfMinutes, @OutputDate)
	SET @OutputDate = DATEADD(SECOND, @NumbersOfSeconds, @OutputDate)
	SET @OutputDate = DATEADD(MILLISECOND, @NumbersOfMilliseconds, @OutputDate)
	
	IF (SELECT [compatibility_level] FROM sys.databases WHERE name = DB_NAME()) > 100
	BEGIN
		-- DATEADD does not support nanosecond in versions prior to...I think SQL 2008.
		-- If this is the case then nanosecond level precision is lost.
		SET @OutputDate = DATEADD(NANOSECOND, @NumbersOfNanoseconds, @OutputDate)
	END
	
	RETURN @OutputDate

END 
GO