
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fnRemove')
BEGIN
	DROP FUNCTION dbo.fnRemove
	PRINT 'DROP FUNCTION dbo.fnRemove'
END
GO


CREATE FUNCTION dbo.fnRemove(@Input NVARCHAR(MAX), @Pattern NVARCHAR(4000))
RETURNS NVARCHAR(MAX)
AS
BEGIN
/*
Remove all the characters specified by the @Pattern.
Return the result.
*/

	DECLARE @Output NVARCHAR(MAX) = @Input
	
    WHILE PATINDEX(@Pattern, @Output) > 0
    BEGIN
        SET @Output = STUFF(@Output, PATINDEX(@Pattern, @Output), 1, '')
    END
    
    RETURN @Output
    
END
GO
