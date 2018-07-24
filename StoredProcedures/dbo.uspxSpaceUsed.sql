
IF EXISTS (SELECT * FROM sys.procedures WHERE [name] = 'uspxSpaceUsed') 
BEGIN
	DROP PROCEDURE dbo.uspxSpaceUsed
	PRINT 'DROP PROCEDURE dbo.uspxSpaceUsed'
END
GO


CREATE PROCEDURE dbo.uspxSpaceUsed
	@TableName NVARCHAR(255) = NULL,
	@OrderBySpaceUsed BIT = 1
AS 
BEGIN
/*
Output the details of the amount of space used by a table.

20140124	dungeym		initial scripting
*/
	
    IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END;
	IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;
		
		
    SET NOCOUNT ON
    DECLARE @TSQL VARCHAR(255) = 'INSERT #Tables SELECT TABLE_NAME FROM ' + DB_NAME() + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE'''
    
    
    CREATE TABLE #Tables(name VARCHAR(255))
    EXEC (@TSQL)
    
    
    CREATE TABLE #SpaceUsed
	(
		[Name] 			VARCHAR(255),
		[Rows] 			VARCHAR(11),
		[Total] 		VARCHAR(18),
		[Data] 			VARCHAR(18),
		[Indexes] 		VARCHAR(18),
		[Unused] 		VARCHAR(18)
	)
    
    
    DECLARE @Name VARCHAR(255) = ''    
    WHILE EXISTS (SELECT * FROM #Tables WHERE [Name] > @Name) 
	BEGIN
		SELECT @Name = MIN(name) 
		FROM #Tables
		WHERE name > @Name

		SELECT @TSQL = 'EXEC ' + DB_NAME() + '..sp_executesql N''INSERT #SpaceUsed EXEC sp_spaceused ' + @Name + ''''
		EXEC (@TSQL)
	END
	
	
    UPDATE #SpaceUsed SET [Total] = REPLACE([Total], 'KB', '')
    UPDATE #SpaceUsed SET [Data] = REPLACE([Data], 'KB', '')
    UPDATE #SpaceUsed SET [Indexes] = REPLACE([Indexes], 'KB', '')
    UPDATE #SpaceUsed SET [Unused] = REPLACE([Unused], 'KB', '')
    
    
    SELECT  
		[Name]
		,[Rows] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, [Rows]), 1), '.00', '')
		,[Data] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ([Data] / 1024)), 1), '.00', ' MB')
		,[Indexes] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ([Indexes]/ 1024)), 1), '.00', ' MB')
		,[Unused] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ([Unused] / 1024)), 1),'.00', ' MB')
		,[Total] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ([Total] / 1024)), 1), '.00', ' MB')
		,[AvgRowSize] = CASE 
			WHEN [Rows] = '0' THEN '0 KB'
			ELSE REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, [Data]) / CONVERT(MONEY, [Rows]), 1), '.00', '') + ' KB'
		END
    FROM #SpaceUsed
    WHERE 1=1
    AND (@TableName IS NULL OR [Name] = @TableName)
    ORDER BY 
    CASE WHEN @OrderBySpaceUsed = 1 THEN CONVERT(MONEY, ([Data] / 1024)) END DESC,
	CASE WHEN @OrderBySpaceUsed = 0 THEN [Name] END ASC
    
    
    IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END;
    IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;
	
END
GO


GRANT EXECUTE ON dbo.uspxSpaceUsed TO PUBLIC
GO
