
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnParseStringToTable')
BEGIN
	DROP FUNCTION dbo.fnParseStringToTable
	PRINT 'DROP FUNCTION dbo.fnParseStringToTable'
END
GO


CREATE FUNCTION dbo.fnParseStringToTable(@Value VARCHAR(MAX), @Delimiter VARCHAR(10))
RETURNS @ParseResult TABLE (id INT NOT NULL IDENTITY(1, 1), Field VARCHAR(MAX))
AS
BEGIN
/*
Create a table from the input @Value by splitting the contents according to the @Delimiter string/
Return the table.
*/  

	DECLARE @Position INT
	DECLARE @LastPosition INT
	DECLARE @Field VARCHAR(MAX)
	DECLARE @DelimiterLength INT = LEN(@Delimiter)
	DECLARE @StringLength INT = LEN(@Value)

	IF(@StringLength > 0 AND @DelimiterLength > 0)
	BEGIN
		SELECT @Position = CHARINDEX(@Delimiter, @Value), @LastPosition = 1
		
		WHILE @Position > 0
		BEGIN
			SELECT @Field = SUBSTRING(@Value, @LastPosition, @Position - @LastPosition)
			
			INSERT INTO @ParseResult (Field) VALUES (LTRIM(RTRIM(@Field)))

			SELECT @LastPosition = @Position + @DelimiterLength
			SELECT @Position = CHARINDEX(@Delimiter, @Value, @LastPosition)  
		END

		-- If the delimiter is last character then add empty row.
		IF @LastPosition = LEN(@Value) + @DelimiterLength
		BEGIN
			SELECT @Field = ''
			INSERT INTO @ParseResult (Field) VALUES (LTRIM(RTRIM(@Field)))
		END
		ELSE
			-- If there is still data after last delimiter then add it as the last row.
			IF @LastPosition < @StringLength + @DelimiterLength
			BEGIN
				SELECT @Field = SUBSTRING(@Value, @LastPosition, (@StringLength - @LastPosition) + @DelimiterLength)
				INSERT INTO @ParseResult (Field) VALUES (LTRIM(RTRIM(@Field)))
			END
	END

	RETURN

END
GO
