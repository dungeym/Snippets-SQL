
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnStringHashCode')
BEGIN
	DROP FUNCTION dbo.fnStringHashCode
	PRINT 'DROP FUNCTION dbo.fnStringHashCode'
END
GO


CREATE FUNCTION dbo.fnStringHashCode(@Input NVARCHAR(MAX)) RETURNS INT
WITH RETURNS NULL ON NULL INPUT 
BEGIN
/*
This function is equivalent to java.lang.String's hashCode method.

SQL Server doesn't support arithmetic overflow, which is central to the published Java algorithm, 
so we need to perform all operations against a longer data type and explicitly truncate overflow 
after every arithmetic operation that modIFies @HashCode. The overflow check is simply to mask the 
result to 32 bits and check if the number is larger than (2 ^ 31) - 1. 

If the check detects overflow, we subtract (2 ^ 32).
*/
 
	DECLARE @Index INT = 1
	DECLARE @HashCode BIGINT = 0

	
	WHILE @Index <= LEN(@Input)
	BEGIN
		SET @HashCode = (31 * @HashCode) & 0xFFFFFFFF
		IF @HashCode > 2147483647
		BEGIN
			SET @HashCode = @HashCode - 4294967296
		END

		SET @HashCode = (@HashCode + UNICODE(SUBSTRING(@Input, @Index, 1))) & 0xFFFFFFFF
		
		IF @HashCode > 2147483647
		BEGIN
			SET @HashCode = @HashCode - 4294967296
		END

		SET @Index = @Index + 1
	END
	
	RETURN @HashCode
	
END 
GO