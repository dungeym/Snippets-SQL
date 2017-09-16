-- ==========================================================================================
-- SETTING OBJECT PERMISSIONS
-- ==========================================================================================
DECLARE @Name NVARCHAR(255) = DB_NAME() + '_user'
DECLARE @TSQL NVARCHAR(MAX)

IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
SELECT UsrName = 'public'
INTO #Data
UNION
SELECT UsrName = 'guest'
UNION
SELECT UsrName = @Name


-- ================================================================================================
PRINT 'Removing Table permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE Table_Cursor CURSOR FOR 
SELECT 'REVOKE ' + p.Permission + ' ON OBJECT::dbo.' + o.[name] + ' FROM ' + u.UsrName + ';'
FROM sys.tables o,
(
	SELECT Permission = 'INSERT'
	UNION
	SELECT Permission = 'UPDATE'
	UNION
	SELECT Permission = 'DELETE'
	UNION
	SELECT Permission = 'SELECT'
) AS p,
(
	SELECT UsrName FROM #Data
) AS u
WHERE 1=1
AND o.[type] = 'U'
ORDER BY o.name ASC, p.Permission ASC, u.UsrName ASC;


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
PRINT 'Removing View permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE View_Cursor CURSOR FOR 
SELECT 'REVOKE ' + p.Permission + ' ON OBJECT::dbo.' + o.[name] + ' FROM ' + u.UsrName + ';'
FROM sys.views o,
(
	SELECT Permission = 'SELECT'
) AS p,
(
	SELECT UsrName FROM #Data
) AS u
WHERE 1=1
ORDER BY o.name ASC, p.Permission ASC, u.UsrName ASC;

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
PRINT 'Removing Stored Procedure permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE Procedure_Cursor CURSOR FOR 
SELECT 'REVOKE ' + p.Permission + ' ON OBJECT::dbo.' + o.[name] + ' FROM ' + u.UsrName + ';'
FROM sys.procedures o,
(
	SELECT Permission = 'EXECUTE'
) AS p,
(
	SELECT UsrName FROM #Data
) AS u
WHERE 1=1
ORDER BY o.name ASC, p.Permission ASC, u.UsrName ASC;

OPEN Procedure_Cursor;

FETCH NEXT FROM Procedure_Cursor 
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
    
    FETCH NEXT FROM Procedure_Cursor 
    INTO @TSQL;
    
END

CLOSE Procedure_Cursor;
DEALLOCATE Procedure_Cursor;


-- ================================================================================================
PRINT 'Removing Function permissions for [' + @Name + ']'
-- ================================================================================================
DECLARE Function_Cursor CURSOR FOR 
SELECT 'REVOKE ' + CASE WHEN [type] IN ('FN', 'FS') THEN 'EXECUTE' ELSE 'SELECT' END + ' ON OBJECT::dbo.' + o.[name] + ' FROM ' + u.UsrName + ';'
FROM sys.objects o,
(
	SELECT UsrName FROM #Data
) AS u
WHERE 1=1
AND o.[type] IN ('FN', 'TF', 'FS', 'FT')
ORDER BY o.name ASC, u.UsrName ASC

OPEN Function_Cursor;

FETCH NEXT FROM Function_Cursor 
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
    
    FETCH NEXT FROM Function_Cursor 
    INTO @TSQL;
    
END

CLOSE Function_Cursor;
DEALLOCATE Function_Cursor;


-- ================================================================================================
PRINT 'Removing View Definition permissions for [' + @Name + ']'
-- ================================================================================================
SET @TSQL = 'REVOKE VIEW DEFINITION ON SCHEMA::dbo TO [' + @Name + ']'
PRINT SPACE(5) + @TSQL
EXEC sp_executesql @TSQL
GO