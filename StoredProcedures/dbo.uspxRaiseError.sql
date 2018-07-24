
IF EXISTS(SELECT * FROM sys.procedures WHERE [name] = 'uspxRaiseError')
BEGIN
	DROP PROCEDURE dbo.uspxRaiseError
	PRINT 'DROP PROCEDURE dbo.uspxRaiseError'
END
GO


CREATE PROCEDURE dbo.uspxRaiseError
	@State			INT = NULL,
	@Severity		INT = NULL
AS
BEGIN
/*
Output the details of an error that has occured in a Try-Catch block.
Override the State and Severity as required.

20140124	dungeym		initial scripting
*/
	
	IF ERROR_NUMBER() IS NULL RETURN;
	
	DECLARE @ErrorNumber     INT = ERROR_NUMBER()
    DECLARE @ErrorSeverity   INT = ERROR_SEVERITY()
	DECLARE @ErrorState      INT = ERROR_STATE()
	DECLARE @ErrorLine       INT = ERROR_LINE()
	DECLARE @ErrorProcedure  NVARCHAR(200) = ISNULL(ERROR_PROCEDURE(), '-')
	DECLARE @ErrorMessage    NVARCHAR(4000) = N'Error %d, Severity %d, State %d, Procedure %s, Line %d, Message: ' + ERROR_MESSAGE()

	IF @State IS NULL
	BEGIN
		SET @State = @ErrorState
	END
	
	IF @Severity IS NULL
	BEGIN
		SET @Severity = @ErrorSeverity
	END
	
	RAISERROR (@ErrorMessage, @Severity, @State, @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine)

END
GO


GRANT EXECUTE ON dbo.uspxRaiseError TO PUBLIC
GO