/*
SELECT 'EXEC uspxWriteFK ''' + fk.name + '''', 'fk_' + OBJECT_NAME(fk.parent_object_id) + '_' + OBJECT_NAME(fkc.referenced_object_id)
FROM sys.foreign_keys fk WITH (NOLOCK)
INNER JOIN sys.foreign_key_columns fkc WITH (NOLOCK) ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables t WITH (NOLOCK) ON fk.parent_object_id = t.object_id
ORDER BY t.name ASC
*/
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'uspxWriteFK')
BEGIN
	DROP PROCEDURE dbo.uspxWriteFK
	PRINT 'DROP PROCEDURE dbo.uspxWriteFK'
END
GO

CREATE PROCEDURE dbo.uspxWriteFK
	@FK_Name VARCHAR(255)
AS
BEGIN
	
	SET NOCOUNT ON 
	
	DECLARE @SQL 			VARCHAR(1000)
	DECLARE @FK_NewName		VARCHAR(500)
	SET @SQL = 
	(
		SELECT '		EXEC sp_rename ''' + @FK_Name + ''', ''fk_' + OBJECT_NAME(fk.parent_object_id) + '_' + OBJECT_NAME(fkc.referenced_object_id) + ''', ''OBJECT'''
		FROM sys.foreign_keys fk WITH (NOLOCK)
		INNER JOIN sys.foreign_key_columns fkc WITH (NOLOCK) ON fk.object_id = fkc.constraint_object_id
		INNER JOIN sys.tables t WITH (NOLOCK) ON fk.parent_object_id = t.object_id
		WHERE fk.name = @FK_Name
	)
	SET @FK_NewName = 
	(
		SELECT 'fk_' + OBJECT_NAME(fk.parent_object_id) + '_' + OBJECT_NAME(fkc.referenced_object_id) + ''', ''OBJECT'''
		FROM sys.foreign_keys fk WITH (NOLOCK)
		INNER JOIN sys.foreign_key_columns fkc WITH (NOLOCK) ON fk.object_id = fkc.constraint_object_id
		INNER JOIN sys.tables t WITH (NOLOCK) ON fk.parent_object_id = t.object_id
		WHERE fk.name = @FK_Name
	)

	PRINT 'IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = ''' + @FK_Name + ''')'
	PRINT 'BEGIN'
	PRINT '		-- Done as part of database standardization, July 2012'
	PRINT @SQL
	PRINT '		PRINT ''Rename foreign key constraint [' + @FK_Name + '] = [' + @FK_NewName + ']'''
	PRINT 'END'
	
END
GO