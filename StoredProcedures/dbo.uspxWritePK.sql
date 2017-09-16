/*
SELECT 'EXEC uspxWritePK ''' + i.name + '''' 
FROM sys.indexes i 
WHERE is_primary_key = 1
*/
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'uspxWritePK')
BEGIN
	DROP PROCEDURE dbo.uspxWritePK
	PRINT 'DROP PROCEDURE dbo.uspxWritePK'
END
GO

CREATE PROCEDURE dbo.uspxWritePK
	@PK_Name VARCHAR(255)
AS
BEGIN
	
	SET NOCOUNT ON 
	
	DECLARE @SQL 			VARCHAR(1000)
	DECLARE @FK_NewName		VARCHAR(500)
	SET @SQL = 
	(
		SELECT '		EXEC sp_rename ''' + i.name + ''', ' + '''pk_' + OBJECT_NAME(i.object_id) + ''', ''OBJECT'''
		FROM sys.indexes i 
		WHERE is_primary_key = 1
		AND i.name = @PK_Name
	)
	SET @FK_NewName = 
	(
		SELECT 'pk_' + OBJECT_NAME(i.object_id)
		FROM sys.indexes i 
		WHERE is_primary_key = 1
		AND i.name = @PK_Name
	)

	PRINT '-- Rename PRIMARY KEY'
	PRINT 'IF EXISTS (SELECT * FROM sys.indexes WHERE is_primary_key = 1 AND name = ''' + @PK_Name + ''')'
	PRINT 'BEGIN'
	PRINT '		-- Done as part of database standardization, July 2012'
	PRINT @SQL
	PRINT '		PRINT ''Rename primary key [' + @PK_Name + '] = [' + @FK_NewName + ']'''
	PRINT 'END'
	
END
GO