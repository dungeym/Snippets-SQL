
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnOffSetWorkingDay')
BEGIN
	DROP FUNCTION dbo.fnOffSetWorkingDay
	PRINT 'DROP FUNCTION dbo.fnOffSetWorkingDay'
END
GO


CREATE FUNCTION dbo.fnOffSetWorkingDay(@DateTime DATETIME, @OffSet INT )
RETURNS DATETIME
AS
BEGIN
/* 
This function returns a DateTime which has been OffSet by the given integer whilst 
taking into account working/non-working days (Sat and Sun).
*/

	DECLARE @Result DATETIME
	DECLARE @Increment INT

	SELECT @Increment =
	CASE
		WHEN @OffSet = 0 THEN 0
		WHEN @OffSet > 0 THEN 1
		WHEN @OffSet < 0 THEN -1
	END
	
	WHILE(@Result IS NULL) 
	BEGIN
		IF(dbo.fnIsWorkingDay(@DateTime) = 1 ) 
		BEGIN
			IF (@OffSet = 0)
			BEGIN
				SET @Result = @DateTime
				BREAK
			END
			ELSE
			BEGIN
				SET @OffSet = ABS(@OffSet) - 1
			END
		END	
		
		SELECT @DateTime = DATEADD(dd, @Increment, @DateTime)
		
	END
	
	RETURN @Result
	
END
GO