
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnGetFirstDayOfMonth')
BEGIN
	DROP FUNCTION dbo.fnGetFirstDayOfMonth
	PRINT 'DROP FUNCTION dbo.fnGetFirstDayOfMonth'
END
GO


CREATE FUNCTION dbo.fnGetFirstDayOfMonth(@DateTime DATETIME)
RETURNS DATETIME
AS
BEGIN
/* 
This function returns a DateTime which which represents the first day of the month for the given date.
*/

	DECLARE @Result DATETIME
	DECLARE @Month INT = DATEPART(MM, @DateTime)
	DECLARE @Year INT = DATEPART(YY, @DateTime)
	
	SET @Result = 
		CONVERT (DATETIME, 
			CONVERT	(NVARCHAR(8), 
				CONVERT(VARCHAR(4), @Year) 
				+ CASE WHEN @Month < 10 THEN '0' + CONVERT(VARCHAR(1), @Month) ELSE CONVERT(VARCHAR(2), @Month) END
				+ CONVERT(NVARCHAR(2), '01')
				)
			)
			
	RETURN @Result
	
END
GO
