
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnRemoveCharacters')
BEGIN
	DROP FUNCTION dbo.fnRemoveCharacters
	PRINT 'DROP FUNCTION dbo.fnRemoveCharacters'
END
GO


CREATE FUNCTION dbo.fnRemoveCharacters(@Input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
/*
Remove everything except numeric characters from the input string.
Return the result.
*/

    DECLARE @Pattern NVARCHAR(4000) = '%[^0-9]%'
    RETURN dbo.fnRemove(@Input, @Pattern)
    
END
GO