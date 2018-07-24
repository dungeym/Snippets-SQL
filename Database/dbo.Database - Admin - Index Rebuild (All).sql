
--=================================================================================================
-- Drop all statistics that were automatically created.
-- Rebuild the remaining indexes.
--=================================================================================================

SET NOCOUNT ON
SELECT @@SERVICENAME AS [Server], DB_NAME() AS [Database], GETUTCDATE() AS [Timestamp]

--=================================================================================================
-- DROP STATISTICS where auto_created = 1
--=================================================================================================
DECLARE @TSQL NVARCHAR(MAX)
DECLARE @DateTime NVARCHAR(255) = CONVERT(NVARCHAR(255), GETUTCDATE(), 127)
RAISERROR ('%s Starting...', 0, 1, @DateTime) WITH NOWAIT

DECLARE Data_Cursor CURSOR DYNAMIC FOR 
SELECT 'DROP STATISTICS ' + o.name + '.' + s.name + ';'
FROM sys.stats s 
INNER JOIN sys.objects o ON o.[object_id] = s.[object_id]
WHERE 1=1
AND s.auto_created = 1
AND s.user_created = 0
AND o.type_desc = 'USER_TABLE'
ORDER BY o.name ASC, s.name ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL;


WHILE @@FETCH_STATUS = 0
BEGIN
	
	SET @DateTime = CONVERT(NVARCHAR(255), GETUTCDATE(), 127)
	RAISERROR ('%s %s', 0, 1, @DateTime, @TSQL) WITH NOWAIT
	EXEC sp_executesql @TSQL
	
	FETCH NEXT FROM Data_Cursor INTO @TSQL
	
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;


SET @DateTime = CONVERT(NVARCHAR(255), GETUTCDATE(), 127)
RAISERROR ('%s Complete.', 0, 1, @DateTime) WITH NOWAIT
GO


--=================================================================================================
-- ALTER INDEX (REBUILD) on all tables.
--=================================================================================================
DECLARE @TSQL NVARCHAR(MAX)
DECLARE @DateTime NVARCHAR(255) = CONVERT(NVARCHAR(255), GETUTCDATE(), 127)
RAISERROR ('%s Starting...', 0, 1, @DateTime) WITH NOWAIT

DECLARE Data_Cursor CURSOR DYNAMIC FOR 
SELECT 'ALTER INDEX ALL ON ' + [Name] + ' REBUILD;' 
FROM sys.tables
ORDER BY [name] ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TSQL;


WHILE @@FETCH_STATUS = 0
BEGIN
	
	SET @DateTime = CONVERT(NVARCHAR(255), GETUTCDATE(), 127)
	RAISERROR ('%s %s', 0, 1, @DateTime, @TSQL) WITH NOWAIT
	EXEC sp_executesql @TSQL
	
	FETCH NEXT FROM Data_Cursor INTO @TSQL
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;


SET @DateTime = CONVERT(NVARCHAR(255), GETUTCDATE(), 127)
RAISERROR ('%s Complete.', 0, 1, @DateTime) WITH NOWAIT
GO