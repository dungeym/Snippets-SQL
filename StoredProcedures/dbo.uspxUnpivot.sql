
IF EXISTS (SELECT * FROM sys.procedures WHERE [name] = 'uspxUnpivot')
BEGIN
	DROP PROCEDURE dbo.uspxUnpivot
	PRINT 'DROP PROCEDURE dbo.uspxUnpivot'
END
GO


CREATE PROCEDURE dbo.uspxUnpivot
	@TempTableName NVARCHAR(255),
	@LastFixedColumnIndex INT = 1,
	@MaxWidth INT = 255	
AS
BEGIN
/*
Convert a series of columns into Key/Value pair rows.
The columns converted are those who's column index is greater than @LastFixedColumnIndex
To handle where the data types are different all columns are converted to NVARCHAR(x)

07062018	dungeym		initial scripting.
*/
	
	DECLARE @AllColumnNames NVARCHAR(MAX) -- All the columns in the temp table.	
	DECLARE @FixedColumnNames NVARCHAR(MAX) -- All the columns with a column index equal to or lower than @LastFixedColumnIndex.
	DECLARE @UnpivotColumnNames NVARCHAR(MAX) -- All the columns to be unpivoted.
	DECLARE @ObjectName NVARCHAR(255) = N'tempdb..' + @TempTableName

	-- Populate comma-separated lists of quoted column names according to requirements.
	SELECT
		@AllColumnNames = STUFF
		(
			(
			 SELECT ',' + QUOTENAME(name) + ' = CONVERT(NVARCHAR(' + CONVERT(NVARCHAR(20), @MaxWidth) + '), ' + QUOTENAME(name) + ')'
			 FROM tempdb.sys.columns c
			 WHERE 1=1
			 AND [object_id] = OBJECT_ID(@ObjectName) 
			 FOR XML PATH('')
			 ), 1, 1, ''
		)
		,@FixedColumnNames = STUFF
		(
			(
			 SELECT ',' + QUOTENAME(name) 
			 FROM tempdb.sys.columns c
			 WHERE 1=1
			 AND [object_id] = OBJECT_ID(@ObjectName) 
			 AND column_id <= @LastFixedColumnIndex
			 FOR XML PATH('')
			 ), 1, 1, ''
		)
		,@UnpivotColumnNames = STUFF
		(
			(
			 SELECT ',' + QUOTENAME(name) 
			 FROM tempdb.sys.columns c
			 WHERE 1=1
			 AND [object_id] = OBJECT_ID(@ObjectName) 
			 AND column_id > @LastFixedColumnIndex
			 FOR XML PATH('')
			 ), 1, 1, ''
		)
 

	/*
	Reselect the data from #Data into ##Source (global temp table) using the new coverted columns.
	This gives us source data with a single common data type.
	*/
	IF OBJECT_ID('tempdb..##Source') IS NOT NULL BEGIN DROP TABLE ##Source END;
	
	
	DECLARE @TSQL NVARCHAR(MAX)
	SET @TSQL = 'SELECT ' + @AllColumnNames + ' INTO ##Source FROM ' + @ObjectName
	EXEC sp_executesql @TSQL


	-- Run the UNPIVOT to get the results.
	SET @TSQL = 'SELECT ' + @FixedColumnNames + ', u.ColumnName, u.ColumnValue FROM tempdb..##Source UNPIVOT (ColumnValue FOR ColumnName IN (' + @UnpivotColumnNames + ')) u ORDER BY u.ColumnName ASC'
	EXEC sp_executesql @TSQL
	
	
	IF OBJECT_ID('tempdb..##Source') IS NOT NULL BEGIN DROP TABLE ##Source END;

END
GO
