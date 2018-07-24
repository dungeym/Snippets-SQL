--=================================================================================================
-- Refresh all the modules of the database.
-- http://msdn.microsoft.com/en-us/library/ms177596.aspx
--=================================================================================================

SET NOCOUNT ON

-- ================================================================================================
PRINT 'Refreshing View modules'
-- ================================================================================================
DECLARE @TSQL NVARCHAR(MAX)
DECLARE Data_Cursor CURSOR FOR 
SELECT 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + v.[name] + '''' 
FROM sys.views v 
INNER JOIN sys.sql_modules m ON v.[object_id] = m.[object_id]
INNER JOIN sys.schemas s ON s.[schema_id] = v.[schema_id]
WHERE 1=1
AND m.is_schema_bound = 0
ORDER BY v.[name] ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL;


WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
	EXEC sp_executesql @TSQL 
 
	FETCH NEXT FROM Data_Cursor INTO @TSQL;
 
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO


-- ================================================================================================
PRINT 'Refreshing Stored Procedure modules'
-- ================================================================================================
DECLARE @TSQL NVARCHAR(MAX)
DECLARE Data_Cursor CURSOR FOR 
SELECT 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + p.[name] + ''''
FROM sys.procedures p 
INNER JOIN sys.schemas s ON s.[schema_id] = p.[schema_id]
WHERE 1=1
AND [type] IN ('P') 
ORDER BY p.[name] ASC;


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL;


WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
	EXEC sp_executesql @TSQL 
 
	FETCH NEXT FROM Data_Cursor INTO @TSQL;
 
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO


-- ================================================================================================
PRINT 'Refreshing Function modules'
-- ================================================================================================
DECLARE @TSQL NVARCHAR(MAX)
DECLARE Data_Cursor CURSOR FOR 
SELECT DISTINCT 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + o.[name] + ''''
FROM sys.objects o 
INNER JOIN sys.sql_modules m ON o.[object_id] = m.[object_id]
INNER JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
LEFT JOIN sys.sql_expression_dependencies ed ON ed.referenced_id = o.[object_id]
LEFT JOIN sys.objects ed_o ON ed_o.[object_id] = ed.referencing_id AND ed_o.type_desc = 'CHECK_CONSTRAINT'
WHERE 1=1
AND o.[type] IN ('FN', 'TF') 
AND m.is_schema_bound = 0
AND ed_o.[object_id] IS NULL -- Exclude where the FN is referenced by a Check Constraint.
ORDER BY 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + o.[name] + '''' ASC;


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL;


WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
	EXEC sp_executesql @TSQL 
 
	FETCH NEXT FROM Data_Cursor INTO @TSQL;
 
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO


-- ================================================================================================
PRINT 'Refreshing Triggers modules'
-- ================================================================================================
DECLARE @TSQL NVARCHAR(MAX)
DECLARE Data_Cursor CURSOR FOR 
SELECT 'EXEC sp_refreshsqlmodule ''' + name + '''' 
FROM sys.triggers t 
WHERE 1=1
AND [type] IN ('TR') 
ORDER BY name ASC;


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL;


WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
	EXEC sp_executesql @TSQL 
 
	FETCH NEXT FROM Data_Cursor INTO @TSQL;
 
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;
GO