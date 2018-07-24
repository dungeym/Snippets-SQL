
--=================================================================================================
-- Disable all the triggers in the database.
--=================================================================================================

SET NOCOUNT ON 

DECLARE @TSQL NVARCHAR(MAX)
DECLARE Data_Cursor CURSOR FOR 
SELECT [TSQL] = 'ENABLE TRIGGER dbo.' + tr.[name] + ' ON dbo.' + t.[name] + ';'	
FROM sys.triggers tr 
INNER JOIN sys.tables t ON t.[object_id] = tr.parent_id
WHERE 1=1
AND tr.is_disabled = 1


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
