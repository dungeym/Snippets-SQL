
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnGetDateOnlyAsInt')
BEGIN
	DROP FUNCTION dbo.fnGetDateOnlyAsInt
	PRINT 'DROP FUNCTION dbo.fnGetDateOnlyAsInt'
END
GO


CREATE FUNCTION dbo.fnGetDateOnlyAsInt(@DateTime DATETIME)
RETURNS INT
AS
BEGIN
/* 
Return the @DateTime value as an integer in the format yyyymmdd
*/

	RETURN CONVERT(NVARCHAR(8), @DateTime, 112)
	
END
GO