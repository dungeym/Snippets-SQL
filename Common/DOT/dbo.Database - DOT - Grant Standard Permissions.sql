-- ==========================================================================================
-- SETTING OBJECT PERMISSIONS
-- ==========================================================================================
DECLARE @Name NVARCHAR(255)
DECLARE @CanInsert BIT
DECLARE @CanUpdate BIT
DECLARE @CanDelete BIT
DECLARE @CanExecute BIT

SET @Name = DB_NAME() + '_user'
SET @CanInsert = 1
SET @CanUpdate = 1
SET @CanDelete = 1
SET @CanExecute = 1

DECLARE @TSQL NVARCHAR(MAX)

-- ================================================================================================
PRINT 'Applying Table permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE Table_Cursor CURSOR FOR 
SELECT 'GRANT SELECT'
 + CASE WHEN @CanInsert = 1 THEN ', INSERT' ELSE '' END 
 + CASE WHEN @CanUpdate = 1 THEN ', UPDATE' ELSE '' END 
 + CASE WHEN @CanDelete = 1 THEN ', DELETE' ELSE '' END
+ ' ON [' + name + '] TO [' + @Name + ']' FROM sys.tables WHERE type = 'U' ORDER BY [name] ASC;

OPEN Table_Cursor;

FETCH NEXT FROM Table_Cursor 
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRY
		EXEC sp_executesql @TSQL
		PRINT SPACE(5) + @TSQL
	END TRY
	BEGIN CATCH
		PRINT SPACE(5) + 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()		
	END CATCH
    
    FETCH NEXT FROM Table_Cursor 
    INTO @TSQL;
    
END

CLOSE Table_Cursor;
DEALLOCATE Table_Cursor;


-- ================================================================================================
PRINT 'Applying View permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE View_Cursor CURSOR FOR 
SELECT 'GRANT SELECT ON [' + name + '] TO [' + @Name + ']' FROM sys.views ORDER BY [name] ASC;

OPEN View_Cursor;

FETCH NEXT FROM View_Cursor 
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRY
		EXEC sp_executesql @TSQL
		PRINT SPACE(5) + @TSQL
	END TRY
	BEGIN CATCH
		PRINT SPACE(5) + 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()		
	END CATCH
    
    FETCH NEXT FROM View_Cursor 
    INTO @TSQL;
    
END

CLOSE View_Cursor;
DEALLOCATE View_Cursor;


-- ================================================================================================
PRINT 'Applying Stored Procedure permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE Procedure_Cursor CURSOR FOR 
SELECT 'GRANT EXECUTE ON [' + name + '] TO [' + @Name + ']' FROM sys.procedures ORDER BY [name] ASC;

OPEN Procedure_Cursor;

FETCH NEXT FROM Procedure_Cursor 
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	IF @CanExecute = 1
	BEGIN TRY
		EXEC sp_executesql @TSQL
		PRINT SPACE(5) + @TSQL
	END TRY
	BEGIN CATCH
		PRINT SPACE(5) + 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()		
	END CATCH
    
    FETCH NEXT FROM Procedure_Cursor 
    INTO @TSQL;
    
END

CLOSE Procedure_Cursor;
DEALLOCATE Procedure_Cursor;


-- ================================================================================================
PRINT 'Applying Function permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE Function_Cursor CURSOR FOR 
SELECT 'GRANT '
+ CASE WHEN [type] IN ('FN', 'FS') THEN 'EXECUTE' ELSE 'SELECT' END 
+ ' ON [' + name + '] TO [' + @Name + ']' 
FROM sys.objects WHERE [type] IN ('FN', 'TF', 'FS', 'FT') ORDER BY name ASC;

OPEN Function_Cursor;

FETCH NEXT FROM Function_Cursor 
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	IF @CanExecute = 1
	BEGIN TRY
		EXEC sp_executesql @TSQL
		PRINT SPACE(5) + @TSQL
	END TRY
	BEGIN CATCH
		PRINT SPACE(5) + 'FAILED | ' + @TSQL + ' | (Error:' + CONVERT(NVARCHAR(255), ERROR_NUMBER()) + ') ' + ERROR_MESSAGE()		
	END CATCH	
    
    FETCH NEXT FROM Function_Cursor 
    INTO @TSQL;
    
END

CLOSE Function_Cursor;
DEALLOCATE Function_Cursor;


-- ================================================================================================
PRINT 'Applying View Definition permissions for [' + @Name + ']'
-- ================================================================================================
SET @TSQL = 'GRANT VIEW DEFINITION ON SCHEMA::dbo TO [' + @Name + ']'
PRINT SPACE(5) + @TSQL
EXEC sp_executesql @TSQL
GO
