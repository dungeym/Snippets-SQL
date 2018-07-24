
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnGetFirstDayOfMonth')
BEGIN
	DROP FUNCTION dbo.fnGetFirstDayOfMonth
	PRINT 'DROP FUNCTION dbo.fnGetFirstDayOfMonth'
END
GO


CREATE FUNCTION dbo.fnGetLastDayOfMonth(@DateTime DATETIME)
RETURNS DATETIME
AS
BEGIN
/* 
This function returns a DateTime which which represents the last day of the month for the given date.
*/

	DECLARE @Result DATETIME
	
	SELECT @Result = DATEADD(dd, -1, DATEADD(mm, DATEDIFF(m, 0, @DateTime)+1, 0))
	
	RETURN @Result
	
END
GO