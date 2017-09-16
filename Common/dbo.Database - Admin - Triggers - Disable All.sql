--=================================================================================================
-- Disable all the triggers in the database.
--=================================================================================================

SET NOCOUNT ON 

IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;

SELECT [TSQL] = 'DISABLE TRIGGER dbo.' + tr.[name] + ' ON dbo.' + t.[name] + ';'	
INTO #Data
FROM sys.triggers tr WITH (NOLOCK)
INNER JOIN sys.tables t WITH (NOLOCK) ON t.[object_id] = tr.parent_id
WHERE tr.is_disabled = 0

DECLARE @TSQL VARCHAR(MAX)
WHILE (SELECT COUNT(*) FROM #Data) != 0
BEGIN
	SET @TSQL = (SELECT TOP 1 [TSQL] FROM #Data)
	
	PRINT @TSQL
	EXEC (@TSQL)
	
	DELETE FROM #Data WHERE [TSQL] = @TSQL
	
END
GO	