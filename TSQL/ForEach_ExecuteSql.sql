
SET NOCOUNT ON
SELECT @@SERVICENAME AS [Server], DB_NAME() AS [Database], GETUTCDATE() AS [Timestamp]

--=================================================================================================
-- Build the #Data table to include the [TSQL] column
--=================================================================================================
IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;

SELECT 
	RowIndex = ROW_NUMBER() OVER(ORDER BY MAX(f.id))
	
	,[TSQL] = CASE
		WHEN t.[Description] = 'EMIR_Matched' THEN 'EXEC uspMatchedNotificationMessageInterEntity ' + CONVERT(VARCHAR(25), MAX(f.id)) + ';'
		WHEN t.[Description] = 'DFA_Matched' THEN 'EXEC uspMatchedNotificationMessageInterEntity ' + CONVERT(VARCHAR(25), MAX(f.id)) + ';'
		WHEN t.[Description] = 'EMIR_Unmatched' THEN 'EXEC uspUnmatchedNotificationMessageInterEntity ' + CONVERT(VARCHAR(25), MAX(f.id)) + ';'
		WHEN t.[Description] = 'DFA_Unmatched' THEN 'EXEC uspUnmatchedNotificationMessageInterEntity ' + CONVERT(VARCHAR(25), MAX(f.id)) + ';'
		ELSE NULL
		END
	
	-- Paste the remainder of the SELECT statement below, keep the 'INTO #Data' text
	,id = MAX(f.id)
	,ImportType = t.[Description]
	,ImportStatus = s.[Description]
INTO #Data
FROM dbo.tblImportFile f WITH (NOLOCK) 
INNER JOIN dbo.tblImportStatus s WITH (NOLOCK) ON s.id = f.ImportStatus_id
INNER JOIN dbo.tblImportType t WITH (NOLOCK) ON t.id = f.ImportType_id
WHERE 1=1
AND t.[Description] IN ('DFA_Unmatched', 'EMIR_Unmatched', 'DFA_Matched', 'EMIR_Matched')
AND s.[Description] = 'Complete'
GROUP BY t.[Description], s.[Description]


--=================================================================================================
-- Output...
--=================================================================================================
SELECT * 
FROM #Data
ORDER BY RowIndex ASC


--=================================================================================================
-- Execute the contents of the [TSQL] column for each row in #Data
--=================================================================================================
DECLARE @RowIndex INT = 1
DECLARE @UpperIndex INT = (SELECT MAX(RowIndex) FROM #Data)
DECLARE @TSQL NVARCHAR(MAX)

WHILE @RowIndex <= @UpperIndex
BEGIN
	SET @TSQL = (SELECT [TSQL] FROM #Data WHERE RowIndex = @RowIndex AND [TSQL] IS NOT NULL)
	PRINT @TSQL
	EXEC sp_executesql @TSQL
	
	SET @RowIndex = @RowIndex +1
	
END
GO