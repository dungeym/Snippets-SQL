
--=================================================================================================
-- Drop default constraints.
-- Drop triggers.
-- Drop unique constraints.
-- Drop indexes.
-- Drop foreign key constraints.
-- Drop primary key constraints.
-- Drop every object in the database.
--=================================================================================================

SET NOCOUNT ON

-- ================================================================================================
-- DROP CONSTRAINT (DEFAULT)
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + t.name + ' DROP CONSTRAINT ' + dc.name
	FROM sys.default_constraints dc 
	INNER JOIN sys.tables t ON dc.parent_object_id = t.[object_id]
	INNER JOIN sys.columns c ON dc.parent_object_id = c.[object_id] AND dc.parent_column_id = c.column_id

	
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL		

		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO


-- ================================================================================================
-- DROP TRIGGER
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 'DROP TRIGGER ' + t.[name] 
	FROM sys.triggers t

	
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL		

		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO


-- ================================================================================================
-- DROP UNIQUE CONSTRAINTS
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + OBJECT_NAME(i.[object_id]) + ' DROP ' + i.name 
	FROM sys.indexes i 
	WHERE 1=1
	AND i.type_desc = 'NONCLUSTERED' 
	AND i.is_unique_constraint = 1

	
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL		

		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO


-- ================================================================================================
-- DROP INDEX
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 'DROP INDEX [' + i.name + '] ON [dbo].[' + OBJECT_NAME(i.[object_id]) + '] WITH ( ONLINE = OFF )',*
	FROM sys.indexes i 
	INNER JOIN sys.tables t ON t.[object_id] = i.[object_id]
	WHERE 1=1
	AND i.is_unique = 0
	AND i.name IS NOT NULL
	AND t.is_ms_shipped = 0

	
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO


-- ================================================================================================
-- DROP FOREIGN KEY
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + t.name + ' DROP CONSTRAINT ' + fk.name
	FROM sys.foreign_keys fk 
	INNER JOIN sys.tables t ON fk.parent_object_id = t.[object_id]
	WHERE 1=1
	AND t.is_ms_shipped = 0
	ORDER BY t.name ASC, fk.name

	
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO


-- ================================================================================================
-- DROP PRIMARY KEY
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + t.name + ' DROP CONSTRAINT ' + i.name
	FROM sys.indexes i 
	INNER JOIN sys.tables t ON i.[object_id] = t.[object_id]
	WHERE 1=1
	AND i.is_primary_key = 1
	ORDER BY t.name ASC

	
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO


-- ================================================================================================
-- DROP OBJECTS
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE Data_Cursor CURSOR FOR 
	SELECT 
		[TSQL] = CASE 
			WHEN o.[type] IN ('FN', 'FS', 'FT', 'IF', 'TF') THEN 'DROP FUNCTION ' + o.name
			WHEN o.[type] IN ('P', 'PC') THEN 'DROP PROCEDURE ' + o.name
			WHEN o.[type] = 'V' THEN 'DROP VIEW ' + o.name
			WHEN o.[type] = 'U' THEN 'DROP TABLE ' + o.name			
			END
	FROM sys.objects o 
	WHERE 1=1
	AND o.is_ms_shipped = 0
	AND o.[type] IN ('FN', 'FS', 'FT', 'IF', 'TF', 'P', 'PC', 'V', 'U')
	ORDER BY 
		CASE 
		WHEN o.[type] IN ('FN', 'FS', 'FT', 'IF', 'TF') THEN 0
		WHEN o.[type] IN ('P', 'PC') THEN 1
		WHEN o.[type] = 'V' THEN 2
		WHEN o.[type] = 'U' THEN 3
		ELSE 99
		END ASC

		
	OPEN Data_Cursor;
	FETCH NEXT FROM Data_Cursor INTO @TSQL;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM Data_Cursor 
		INTO @TSQL
	END 

	
	CLOSE Data_Cursor;
	DEALLOCATE Data_Cursor;
END
GO