
/*
SELECT 'SELECT * FROM ' + s.name, s.name, REPLACE(s.name, 'History', '')
FROM sys.tables s WITH (NOLOCK)
WHERE s.name LIKE '%History'
ORDER BY s.name ASC 
*/

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'uspxWriteTR')
BEGIN
	DROP PROCEDURE dbo.uspxWriteTR
	PRINT 'DROP PROCEDURE dbo.uspxWriteTR'
END
GO

CREATE PROCEDURE dbo.uspxWriteTR
	@TableName VARCHAR(255)
AS
BEGIN

	SET NOCOUNT ON
		
	DECLARE @TableNameHistory VARCHAR(255)
	SET @TableNameHistory = @TableName + 'History'

	DECLARE @TriggerName VARCHAR(255)
	SET @TriggerName = 'tr_' + @TableName
	DECLARE @ColumnName VARCHAR(255)


	PRINT 'IF EXISTS(SELECT * FROM sys.triggers WHERE [name] = ''' + @TriggerName + '_Update'')'
	PRINT 'BEGIN'
	PRINT '		DROP TRIGGER [' + @TriggerName + '_Update]'
	PRINT '		PRINT ''DROPPED TRIGGER [' + @TriggerName + '_Update]'''
	PRINT 'END'
	PRINT 'GO'
	PRINT ''
	PRINT 'CREATE TRIGGER ' + @TriggerName + '_Update'
	PRINT 'ON dbo.' + @TableName
	PRINT 'FOR UPDATE'
	PRINT 'AS'
	PRINT ''
	PRINT '		INSERT INTO dbo.' + @TableNameHistory
	PRINT '			('
	PRINT '				Id,'

	DECLARE temp_cursor CURSOR FOR 
	SELECT [name] 
	FROM sys.columns 
	WHERE object_id = OBJECT_ID(@TableName)
	AND [name] NOT IN
	(
		'Id',
		'DeletedDate',
		'CreatedDate',
		'CreatedByUid',
		'UpdatedDate',
		'UpdatedByUid',
		'DbStamp'
	)
	ORDER BY column_id

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @ColumnName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		PRINT '				' + @ColumnName + ','

		FETCH NEXT FROM temp_cursor 
		INTO @ColumnName
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;

	PRINT '				DeletedDate,'
	PRINT '				CreatedDate,'
	PRINT '				CreatedByUid,'
	PRINT '				UpdatedDate,'
	PRINT '				UpdatedByUid'
	PRINT '			)'
	PRINT '		SELECT'
	PRINT '			Id,'

	DECLARE temp_cursor CURSOR FOR 
	SELECT [name] 
	FROM sys.columns 
	WHERE object_id = OBJECT_ID(@TableName)
	AND [name] NOT IN
	(
		'Id',
		'DeletedDate',
		'CreatedDate',
		'CreatedByUid',
		'UpdatedDate',
		'UpdatedByUid',
		'DbStamp'
	)
	ORDER BY column_id

	OPEN temp_cursor

	FETCH NEXT FROM temp_cursor 
	INTO @ColumnName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		PRINT '			' + @ColumnName + ','

		FETCH NEXT FROM temp_cursor 
		INTO @ColumnName
	END 

	CLOSE temp_cursor;
	DEALLOCATE temp_cursor;

	PRINT '			DeletedDate,'
	PRINT '			CreatedDate,'
	PRINT '			CreatedByUid,'
	PRINT '			UpdatedDate,'
	PRINT '			UpdatedByUid'
	PRINT '		FROM deleted'
	PRINT ''
	PRINT 'GO'
	PRINT ''
	
END
GO
