IF EXISTS(SELECT * FROM sys.objects WHERE name = 'fnFormatNumber' AND type = 'FN')
BEGIN
	DROP FUNCTION fnFormatNumber
	PRINT '...DROPPED FUNCTION [fnFormatNumber]'
END
GO


CREATE FUNCTION fnFormatNumber (@Value DECIMAL(32,9), @Precision INT)
	RETURNS nvarchar(255)
AS
BEGIN
/*
Re-format the @Value to a comma seperated string.
Round the @Value according to the @Precision value.

06.04.11	dungeym		initial scripting
*/
	
	DECLARE @Return NVARCHAR(255)
	SET @Return = NULL
	
	IF @Value IS NULL
		SET @Return = 'The [@Value] argument in the function [fnFormatNumber] cannot be NULL.'
	ELSE IF @Precision IS NULL
		SET @Return = 'The [@Precision] argument in the function [fnFormatNumber] cannot be NULL.'
	ELSE IF @Precision < 0
		SET @Return = 'The [@Precision] argument in the function [fnFormatNumber] must be greater than zero.'
	ELSE
	BEGIN
		DECLARE @StringValue AS NVARCHAR(255)
		DECLARE @Point AS INT
		DECLARE @Left AS NVARCHAR(255)
		DECLARE @Right AS NVARCHAR(255)

		/*
			Convert @Value to a string, split by the decimal point character to @Left and @Right
		*/
		SET @StringValue = CAST(@Value AS NVARCHAR(255))
		SET @Point = PATINDEX('%.%', @StringValue)
		SET @Left = SUBSTRING(@StringValue, 0, @Point)
		SET @Right = SUBSTRING(@StringValue, (@Point+1), 255)


		/*
			Work backwards through the @Left string
			After every third character prefix the current @FormattedLeft value with a comma character
		*/
		DECLARE @Index INT
		DECLARE @FormattedLeft AS NVARCHAR(255)
		DECLARE @Step INT

		SET @FormattedLeft = ''
		SET @Step = 0
		SET @Index = LEN(@Left)
		WHILE @Index >= 0
		BEGIN
			SET @FormattedLeft = SUBSTRING(@Left, (@Index), 1) + @FormattedLeft
			SET @Step = @Step + 1
			
			IF @Step = 3 AND @Index > 1
			BEGIN
				SET @FormattedLeft = ',' + @FormattedLeft	
				SET @Step = 0
			END
			
			SET @Index = @Index - 1
		END


		/*
			Prefix the @Right value with '0.' to make it a fraction
			Cast it as a decimal then round it according to the @Precision value
			Substring out the decimal values according to the @Precision
			Test what's left, if it has a value prefix the value with the '.' character
		*/
		DECLARE @FormattedRight NVARCHAR(255)
		SET @FormattedRight = ROUND(CAST(('0.' + @Right) AS DECIMAL(32,9)), @Precision)
		SET @FormattedRight = SUBSTRING(@FormattedRight, 3, (@Precision))
		IF LEN(@FormattedRight) > 0 SET @FormattedRight = '.' + @FormattedRight

		/*
			Combine the two values and return
		*/
		SET @Return = @FormattedLeft + @FormattedRight
	END
	
	RETURN @Return
END
GO

-- Test: the first two should return some error text
SELECT dbo.fnFormatNumber(NULL, NULL)
SELECT dbo.fnFormatNumber(123456789.123456789, NULL)
SELECT dbo.fnFormatNumber(123456789.123456789, 1)
SELECT dbo.fnFormatNumber(123456789.123456789, 2)
SELECT dbo.fnFormatNumber(123456789.123456789, 3)
SELECT dbo.fnFormatNumber(123456789.123456789, 4)