
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnGetDateOnly')
BEGIN
	DROP FUNCTION dbo.fnGetDateOnly
	PRINT 'DROP FUNCTION dbo.fnGetDateOnly'
END
GO


CREATE FUNCTION dbo.fnGetDateOnly(@DateTime DATETIME)
RETURNS DATETIME
AS
BEGIN
/* 
Strip the time from a DATETIME value.
*/

	RETURN CAST(CAST(@DateTime AS DATE) AS DATETIME)
	
END
go