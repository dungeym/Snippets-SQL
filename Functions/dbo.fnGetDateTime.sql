
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnGetDateTime')
BEGIN
	DROP FUNCTION dbo.fnGetDateTime
	PRINT 'DROP FUNCTION dbo.fnGetDateTime'
END
GO


CREATE FUNCTION dbo.fnGetDateTime (@Date DATETIME, @Time NVARCHAR(12))
RETURNS DATETIME
AS
BEGIN
/* 
This appends the date from @Date with the time from @Time.
*/
 
	RETURN CONVERT(DATETIME, CONVERT(NVARCHAR(12), GETDATE(), 106) + ' ' + @Time)
	
END
GO