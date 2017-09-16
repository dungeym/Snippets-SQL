IF EXISTS(SELECT * FROM sys.objects WHERE name = 'fnParseStringToTable' AND type = 'TF')
BEGIN
	DROP FUNCTION fnParseStringToTable
	PRINT '...DROPPED FUNCTION [fnParseStringToTable]'
END
GO


CREATE FUNCTION dbo.fnParseStringToTable(@Value VARCHAR(MAX), @Delimiter VARCHAR(10))
	RETURNS @ParseResult TABLE (id INT NOT NULL IDENTITY(1, 1), Field VARCHAR(MAX))
AS
BEGIN
/*
Split the @Value using the @Delimiter and return table containing a row for each value in the split string.

xx.xx.10	ekrems		initial scripting
*/  

	DECLARE @Pos INT
	DECLARE @LastPos INT
	DECLARE @Field VARCHAR(MAX)
	DECLARE @DelimiterLength INT
	DECLARE @StringLength INT

	SELECT @StringLength = LEN(@Value), @DelimiterLength = LEN(@Delimiter)

	IF(@StringLength > 0 AND @DelimiterLength > 0)
	BEGIN
		SELECT @Pos = CHARINDEX(@Delimiter, @Value), @LastPos = 1
		WHILE @Pos > 0
		BEGIN
			SELECT @Field = SUBSTRING(@Value, @LastPos, @Pos - @LastPos)
			
			INSERT INTO @ParseResult (Field) VALUES (LTRIM(RTRIM(@Field)))

			SELECT @LastPos = @Pos + @DelimiterLength
			SELECT @Pos = charindex(@Delimiter, @Value, @LastPos)  
		END

		-- If the delimiter is last character then add empty row
		IF @LastPos = LEN(@Value) + @DelimiterLength
		BEGIN
			SELECT @Field = ''
			INSERT INTO @ParseResult (Field) VALUES (LTRIM(RTRIM(@Field)))
		END
		ELSE
			-- If still data after last delimiter then load
			IF @LastPos < @StringLength + @DelimiterLength
			BEGIN
				SELECT @Field = SUBSTRING(@Value, @LastPos, (@StringLength - @LastPos) + @DelimiterLength)
				INSERT INTO @ParseResult (Field) VALUES (LTRIM(RTRIM(@Field)))
			END
	END

	RETURN

END
GO

-- Test: INNER JOIN should  lmit the results to 1-6 values
SELECT MyNumber FROM
(
SELECT 1 AS MyNumber
UNION
SELECT 2
UNION
SELECT 3
UNION
SELECT 4
UNION
SELECT 5
UNION
SELECT 6
) AS cte
INNER JOIN dbo.fnParseStringToTable('0;1;2;3;4;5;6;7;8;9;', ';') fn ON fn.id = cte.MyNumber