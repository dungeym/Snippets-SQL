
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnIsWorkingDay')
BEGIN
	DROP FUNCTION dbo.fnIsWorkingDay
	PRINT 'DROP FUNCTION dbo.fnIsWorkingDay'
END
GO


CREATE FUNCTION dbo.fnIsWorkingDay(@DateTime DATETIME)
RETURNS BIT
AS
BEGIN
/* 
Determine if the @DateTime is either a Saturday or a Sunday.

NB - it is agnostic of the server "datefirst" setting, which is normally 7 (Sunday).
*/

	DECLARE @Result BIT
	
	SELECT @Result = CASE WHEN @@DATEFIRST + DATEPART(WEEKDAY, @DateTime) IN (7, 8) THEN 1 ELSE 0 END
	
	RETURN @Result
	
END
GO