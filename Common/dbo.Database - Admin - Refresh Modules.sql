--=================================================================================================
-- Refresh the modules of the database.
--=================================================================================================

SET NOCOUNT ON
DECLARE @TSQL NVARCHAR(MAX)

-- ================================================================================================
PRINT 'Refreshing View modules'
-- ================================================================================================
DECLARE RefreshView_Cursor CURSOR FOR 
SELECT 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + v.[name] + '''' 
FROM sys.views v WITH (NOLOCK)
INNER JOIN sys.sql_modules m ON v.[object_id] = m.[object_id]
INNER JOIN sys.schemas s WITH (NOLOCK) ON s.[schema_id] = v.[schema_id]
WHERE 1=1
AND m.is_schema_bound = 0
ORDER BY v.[name] ASC


OPEN RefreshView_Cursor;

FETCH NEXT FROM RefreshView_Cursor 
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
    EXEC sp_executesql @TSQL 
    
    FETCH NEXT FROM RefreshView_Cursor 
    INTO @TSQL;
    
END

CLOSE RefreshView_Cursor;
DEALLOCATE RefreshView_Cursor;


-- ================================================================================================
PRINT 'Refreshing Stored Procedure modules'
-- ================================================================================================
DECLARE RefreshProcedure_Cursor CURSOR FOR 
SELECT 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + p.[name] + ''''
FROM sys.procedures p WITH (NOLOCK)
INNER JOIN sys.schemas s WITH (NOLOCK) ON s.[schema_id] = p.[schema_id]
WHERE 1=1
AND [type] IN ('P') 
ORDER BY p.[name] ASC;

OPEN RefreshProcedure_Cursor;

FETCH NEXT FROM RefreshProcedure_Cursor 
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
    EXEC sp_executesql @TSQL 
    
    FETCH NEXT FROM RefreshProcedure_Cursor 
    INTO @TSQL;
    
END

CLOSE RefreshProcedure_Cursor;
DEALLOCATE RefreshProcedure_Cursor;


-- ================================================================================================
PRINT 'Refreshing Function modules'
-- ================================================================================================
-- http://msdn.microsoft.com/en-us/library/ms177596.aspx
DECLARE RefreshFunction_Cursor CURSOR FOR 
SELECT DISTINCT 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + o.[name] + ''''
FROM sys.objects o WITH (NOLOCK)
INNER JOIN sys.sql_modules m WITH (NOLOCK) ON o.[object_id] = m.[object_id]
INNER JOIN sys.schemas s WITH (NOLOCK) ON s.[schema_id] = o.[schema_id]
LEFT JOIN sys.sql_expression_dependencies ed WITH (NOLOCK) ON ed.referenced_id = o.[object_id]
LEFT JOIN sys.objects ed_o WITH (NOLOCK) ON ed_o.[object_id] = ed.referencing_id AND ed_o.type_desc = 'CHECK_CONSTRAINT'
WHERE 1=1
AND o.[type] IN ('FN', 'TF') 
AND m.is_schema_bound = 0
AND ed_o.[object_id] IS NULL -- Exclude where the FN is referenced by a Check Constraint.
ORDER BY 'EXEC sp_refreshsqlmodule ''' + s.[name] + '.' + o.[name] + '''' ASC;

OPEN RefreshFunction_Cursor;

FETCH NEXT FROM RefreshFunction_Cursor
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
    EXEC sp_executesql @TSQL 
    
    FETCH NEXT FROM RefreshFunction_Cursor
    INTO @TSQL;
    
END

CLOSE RefreshFunction_Cursor;
DEALLOCATE RefreshFunction_Cursor;


-- ================================================================================================
PRINT 'Refreshing Triggers modules'
-- ================================================================================================
DECLARE RefreshTrigger_Cursor CURSOR FOR 
SELECT 'EXEC sp_refreshsqlmodule ''' + name + '''' 
FROM sys.triggers t WITH (NOLOCK)
WHERE 1=1
AND [type] IN ('TR') 
ORDER BY name ASC;

OPEN RefreshTrigger_Cursor;

FETCH NEXT FROM RefreshTrigger_Cursor
INTO @TSQL;

WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT SPACE(5) + @TSQL
    EXEC sp_executesql @TSQL 
    
    FETCH NEXT FROM RefreshTrigger_Cursor
    INTO @TSQL;
    
END

CLOSE RefreshTrigger_Cursor;
DEALLOCATE RefreshTrigger_Cursor;

GO