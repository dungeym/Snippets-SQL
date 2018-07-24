
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnConvertDateTimeToTicks')
BEGIN
	DROP FUNCTION dbo.fnConvertDateTimeToTicks
	PRINT 'DROP FUNCTION dbo.fnConvertDateTimeToTicks'
END
GO


CREATE FUNCTION dbo.fnConvertDateTimeToTicks (@DateTime DATETIME)      
RETURNS BIGINT
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

	DECLARE @Days INT = DATEDIFF(DAY, @BaseDate, @DateTime)
	DECLARE @DateWithoutTime DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, @DateTime), 0)
	DECLARE @Hours INT = DATEDIFF(HOUR, @DateWithoutTime, @DateTime)
	DECLARE @Minutes INT = DATEDIFF(MINUTE, @DateWithoutTime, @DateTime) - (@Hours * 60)
	DECLARE @Seconds INT = DATEDIFF(SECOND, @DateWithoutTime, @DateTime) - (@Hours * 60 * 60) - (@Minutes * 60)
	DECLARE @Milliseconds INT = DATEDIFF(MILLISECOND, @DateWithoutTime, @DateTime) - (@Hours * 60 * 60 * 1000) - (@Minutes * 60 * 1000) - (@Seconds * 1000)

	-- Nanosecond level precision is lost.
	
	DECLARE @Output BIGINT = @January_01_01_1753_AsTicks
	SET @Output = @Output + (@Days * @Day)
	SET @Output = @Output + (@Hours * @Hour)
	SET @Output = @Output + (@Minutes * @Minute)
	SET @Output = @Output + (@Seconds * @Second)
	SET @Output = @Output + (@Milliseconds * @Millisecond)
	
	RETURN @OutputDate

END 
GO