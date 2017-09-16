
IF EXISTS(SELECT * FROM sys.procedures WHERE [name] = 'uspxSpaceUsed')
BEGIN
	DROP PROCEDURE dbo.uspxSpaceUsed
	PRINT 'DROP PROCEDURE dbo.uspxSpaceUsed'
END
GO

CREATE PROCEDURE dbo.uspxSpaceUsed
AS 
    BEGIN
	
    IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END;
	IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;
		
    SET NOCOUNT ON
    DECLARE @TSQL VARCHAR(255) = 'INSERT #Tables SELECT TABLE_NAME FROM ' + DB_NAME() + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE'''
    
    CREATE TABLE #Tables(name VARCHAR(255))
    EXEC (@TSQL)
    
    CREATE TABLE #SpaceUsed
	(
		Name 			VARCHAR(255) ,
		[Rows] 			VARCHAR(11) ,
		Reserved 		VARCHAR(18) ,
		[Data] 			VARCHAR(18) ,
		Index_Size 		VARCHAR(18) ,
		Unused 			VARCHAR(18)
	)
    
    DECLARE @Name VARCHAR(255)
    SELECT  @Name = ''
    
    WHILE EXISTS (SELECT * FROM #Tables WHERE Name > @Name ) 
	BEGIN
		SELECT @Name = MIN(name) 
		FROM #Tables
		WHERE name > @Name

		SELECT @TSQL = 'EXEC ' + DB_NAME() + '..sp_executesql N''INSERT #SpaceUsed EXEC sp_spaceused ' + @Name + ''''
		EXEC (@TSQL)
	END
		
    UPDATE #SpaceUsed SET Reserved = REPLACE(Reserved, 'KB', '')
    UPDATE #SpaceUsed SET [Data] = REPLACE([Data], 'KB', '')
    UPDATE #SpaceUsed SET Index_Size = REPLACE(Index_Size, 'KB', '')
    UPDATE #SpaceUsed SET Unused = REPLACE(Unused, 'KB', '')
    
    SELECT  
		Name
		,[Rows] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, [Rows]), 1), '.00', '')
		,Reserved = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, (Reserved / 1024 )), 1), '.00', ' MB')
		,[Data] = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ([Data] / 1024 )), 1), '.00', ' MB')
		,Index_Size = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, ( Index_Size/ 1024 )), 1), '.00', ' MB')
		,Unused = REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, (Unused / 1024 )), 1),'.00', ' MB')
		,Row_Size = CASE 
			WHEN [Rows] = '0' THEN '0 KB'
			ELSE REPLACE(CONVERT(VARCHAR(29), CONVERT(MONEY, [Data]) / CONVERT(MONEY, [Rows]), 1), '.00', '') + ' KB'
		END
    FROM #SpaceUsed
    ORDER BY CONVERT(MONEY, ([Data] / 1024 )) DESC
    
    IF OBJECT_ID('tempdb..#Tables') IS NOT NULL BEGIN DROP TABLE #Tables END;
    IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL BEGIN DROP TABLE #SpaceUsed END;
	
END
GO

GRANT EXEC ON dbo.uspxSpaceUsed TO PUBLIC;