
SET NOCOUNT ON	

-- ================================================================================================
-- DROP CONSTRAINT (DEFAULT)
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 'ALTER TABLE dbo.' + t.name + ' DROP CONSTRAINT ' + dc.name
	FROM sys.default_constraints dc WITH (NOLOCK)
	INNER JOIN sys.tables t WITH (NOLOCK) ON dc.parent_object_id = t.object_id
	INNER JOIN sys.columns c WITH (NOLOCK) ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL		

		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO

-- ================================================================================================
-- DROP TRIGGER
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 'DROP TRIGGER ' + [name] 
	FROM sys.triggers

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL		

		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO

-- ================================================================================================
-- DROP UNIQUE CONSTRAINTS
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + OBJECT_NAME(i.object_id) + ' DROP ' + i.name 
	FROM sys.indexes i 
	WHERE 1=1
	AND type_desc = 'NONCLUSTERED' 
	AND is_unique_constraint = 1

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL		

		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO

-- ================================================================================================
-- DROP INDEX
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 'DROP INDEX [' + i.name + '] ON [dbo].[' + OBJECT_NAME(i.object_id) + '] WITH ( ONLINE = OFF )'
	FROM sys.indexes i WITH (NOLOCK)
	WHERE i.name LIKE 'idx%'

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO

-- ================================================================================================
-- DROP FOREIGN KEY
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + t.name + ' DROP CONSTRAINT ' + fk.name
	FROM sys.foreign_keys fk WITH (NOLOCK)
	INNER JOIN sys.tables t WITH (NOLOCK) ON fk.parent_object_id = t.object_id
	ORDER BY t.name ASC, fk.name

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO

-- ================================================================================================
-- DROP PRIMARY KEY
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 'ALTER TABLE ' + t.name + ' DROP CONSTRAINT ' + i.name
	FROM sys.indexes i WITH (NOLOCK)
	INNER JOIN sys.tables t WITH (NOLOCK) ON i.object_id = t.object_id
	WHERE i.is_primary_key = 1
	ORDER BY t.name ASC

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO

-- ================================================================================================
-- DROP OBJECTS
-- ================================================================================================
BEGIN	
	DECLARE @TSQL NVARCHAR(MAX)

	DECLARE temp_cursor CURSOR FOR 
	SELECT 
		[TSQL] = CASE 
			WHEN o.[type] IN ('FN', 'FS', 'FT', 'IF') THEN 'DROP FUNCTION ' + o.name
			WHEN o.[type] IN ('P', 'PC') THEN 'DROP PROCEDURE ' + o.name
			WHEN o.[type] = 'V' THEN 'DROP VIEW ' + o.name
			WHEN o.[type] = 'U' THEN 'DROP TABLE ' + o.name			
			END
	FROM sys.objects o WITH (NOLOCK)
	WHERE 1=1
	AND o.is_ms_shipped = 0
	AND o.[type] IN ('FN', 'FS', 'FT', 'IF', 'P', 'PC', 'V', 'U')
	ORDER BY 
		CASE 
		WHEN o.[type] IN ('FN', 'FS', 'FT', 'IF') THEN 0
		WHEN o.[type] IN ('P', 'PC') THEN 1
		WHEN o.[type] = 'V' THEN 2
		WHEN o.[type] = 'U' THEN 3
		ELSE 99
		END ASC

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @TSQL

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC sp_executesql @TSQL
		PRINT @TSQL
		
		FETCH NEXT FROM temp_cursor 
		INTO @TSQL
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;
END
GO