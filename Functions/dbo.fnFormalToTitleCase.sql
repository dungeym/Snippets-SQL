
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnFormalToTitleCase')
BEGIN
	DROP FUNCTION dbo.fnFormalToTitleCase
	PRINT 'DROP FUNCTION dbo.fnFormalToTitleCase'
END
GO


CREATE FUNCTION dbo.fnFormalToTitleCase (@Input AS NVARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN
/*
Convert the @Input to Title Case (where the first character or each word is upper case, the rest is lower case.)
Return the result.
*/  

	DECLARE @Result VARCHAR(255)
	DECLARE @Position INT
	DECLARE @Length INT

	SELECT 
		@Result = N' ' + LOWER(@Input),
		@Position = 1,
		@Length = LEN(@Input) + 1

	WHILE @Position > 0 AND @Position < @Length
	BEGIN
		SET @Result = STUFF(@Result, @Position + 1, 1, UPPER(SUBSTRING(@Result,@Position + 1, 1)))
		SET @Position = CHARINDEX(N' ', @Result, @Position + 1)
		
	END

	RETURN RIGHT(@Result, @Length - 1)

END