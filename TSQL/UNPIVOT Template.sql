
IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;

SELECT 
    anpc.ID
	,anpc.AccountID
	,a.TradingAccountID
	,anpc.NonPostalAddressRdmID
	,a.Owner
	,a.LegalEntity
	,anpc.Address
	,anpc.AddressType
	,anpc.Department
	,a.ChangeDate
	,a.LastMessageGuid
	,a.LastMessageSubType
	,a.LastRequestReceived
	,a.LastRequestSent
	,anpc.DeletedDate
	,anpc.CreatedByID
	,anpc.CreatedDate
	,anpc.UpdatedByID
	,anpc.UpdatedDate
INTO #Data
FROM tblAccountNonPostalConfirmation anpc
INNER JOIN tblAccount a ON a.ID = anpc.AccountID
WHERE 1=1
AND anpc.NonPostalAddressRdmID = 109591
AND a.TradingAccountID = 57668


-- ================================================================================================
-- Assuming the required data has been inserted into #Data, UNPIVOT the data.
-- ================================================================================================
DECLARE @PivotColumnsAfter INT = 1 -- UNPIVOT every column after this one
DECLARE @AllColumnNames NVARCHAR(MAX)
DECLARE @FixedColumnNames NVARCHAR(MAX)
DECLARE @UnpivotColumnNames NVARCHAR(MAX)
DECLARE @TSQL NVARCHAR(MAX)


/*
To manage where the columns have different data types we convert all the columns to one type.
*/
SELECT
	@AllColumnNames = STUFF
	(
		(
         SELECT ',' + QUOTENAME(name) + ' = CONVERT(NVARCHAR(255), ' + QUOTENAME(name) + ')'
         FROM tempdb.sys.columns c
         WHERE 1=1
         AND [object_id] = OBJECT_ID(N'tempdb..#Data') 
         FOR XML PATH('')
         ), 1, 1, ''
	)
	,@FixedColumnNames = STUFF
	(
		(
         SELECT ',' + QUOTENAME(name) 
         FROM tempdb.sys.columns c
         WHERE 1=1
         AND [object_id] = OBJECT_ID(N'tempdb..#Data') 
         AND column_id <= @PivotColumnsAfter
         FOR XML PATH('')
         ), 1, 1, ''
	)
	,@UnpivotColumnNames = STUFF
	(
		(
         SELECT ',' + QUOTENAME(name) 
         FROM tempdb.sys.columns c
         WHERE 1=1
         AND [object_id] = OBJECT_ID(N'tempdb..#Data') 
         AND column_id > @PivotColumnsAfter
         FOR XML PATH('')
         ), 1, 1, ''
	)
 

/*
Reselect the data from #Data into ##Source (global temp table) using the new
coversion columns, this gives us source data with a single common data type.
*/
IF OBJECT_ID('tempdb..##Source') IS NOT NULL BEGIN DROP TABLE ##Source END;
SET @TSQL = 'SELECT ' + @AllColumnNames + ' INTO ##Source FROM tempdb..#Data'
EXEC sp_executesql @TSQL


/*
Run the UNPIVOT to get the data.
*/
SET @TSQL = 'SELECT ' + @FixedColumnNames + ', u.ColumnName, u.ColumnValue FROM tempdb..##Source UNPIVOT (ColumnValue FOR ColumnName IN (' + @UnpivotColumnNames + ')) u ORDER BY u.ColumnName ASC'
EXEC sp_executesql @TSQL
IF OBJECT_ID('tempdb..##Source') IS NOT NULL BEGIN DROP TABLE ##Source END;
GO



