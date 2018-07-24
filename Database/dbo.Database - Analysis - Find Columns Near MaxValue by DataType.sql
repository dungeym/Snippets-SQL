
--=================================================================================================
-- Search the database for columns (of type INT or BIGINT) and check the max value in each column 
-- to see how close it is to the maximum allowable value for the column based on its data type.
--=================================================================================================

SET NOCOUNT ON

--=================================================================================================
-- Create table.
--=================================================================================================
IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
CREATE TABLE #Data
(
	TableName			NVARCHAR(255), 
	ColumnName			NVARCHAR(255), 
	DataType			NVARCHAR(255), 
	IsIdentity			BIT,
	IsFkColumn			BIT,
	CurrentMaxValue		BIGINT
)


--=================================================================================================
-- Insert the Table and Column information.
--=================================================================================================
INSERT INTO #Data (TableName, ColumnName, DataType, IsIdentity, IsFkColumn)
SELECT 
	TableName = t.name
	,ColumnName = c.name	
	,DataType = UPPER(y.name)
	,IsIdentity = c.is_identity
	,IsFkColumn = CASE WHEN fk.constraint_object_id IS NOT NULL THEN 1 ELSE 0 END
FROM sys.columns c 
INNER JOIN sys.tables t ON t.[object_id] = c.[object_id]
INNER JOIN sys.types y ON y.system_type_id = c.system_type_id
LEFT JOIN sys.foreign_key_columns fk ON fk.parent_object_id = t.[object_id] AND fk.parent_column_id = c.column_id
WHERE 1=1
AND UPPER(y.name) IN ('INT', 'BIGINT')
ORDER BY t.name ASC, c.column_id


--=================================================================================================
-- Update the CurrentMaxValue for each Table+Column.
--=================================================================================================
DECLARE @TableName NVARCHAR(255) 
DECLARE @ColumnName NVARCHAR(255)
DECLARE @TSQL NVARCHAR(MAX)


DECLARE Data_Cursor CURSOR FOR
SELECT TableName, ColumnName
FROM #Data
WHERE 1=1
AND IsFkColumn = 0
ORDER BY TableName ASC, ColumnName ASC


OPEN Data_Cursor;
FETCH NEXT FROM Data_Cursor INTO @TableName, @ColumnName;


WHILE @@FETCH_STATUS = 0
BEGIN
	
	SET @TSQL = 'UPDATE #Data SET CurrentMaxValue = (SELECT MAX(' + @ColumnName + ') FROM ' + @TableName + ' WHERE ' + @ColumnName + ' IS NOT NULL) WHERE TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
	--PRINT @TSQL
	EXEC sp_executesql @TSQL
	
	FETCH NEXT FROM Data_Cursor INTO @TableName, @ColumnName
	
END


CLOSE Data_Cursor;
DEALLOCATE Data_Cursor;


--=================================================================================================
-- Output report.
--=================================================================================================
SELECT * 
FROM 
(
	SELECT 
		d.TableName
		,d.ColumnName
		,d.IsIdentity
		,d.IsFkColumn
		,d.DataType 
		,d.CurrentMaxValue
		,AllowableMaxValue = CASE 
			WHEN DataType = 'INT' THEN '2147483647'
			WHEN DataType = 'BIGINT' THEN '9223372036854775807'
			ELSE '-1'
			END
		,Usage = CASE 
			WHEN CurrentMaxValue IS NULL THEN CONVERT(DECIMAL(20,2), 0)
			WHEN CurrentMaxValue = 0 THEN CONVERT(DECIMAL(20,2), 0)
			WHEN DataType = 'INT' THEN CONVERT(DECIMAL(20,2), CurrentMaxValue) / CONVERT(DECIMAL(20,2), 2147483647)
			WHEN DataType = 'BIGINT' THEN CONVERT(DECIMAL(38,2), CurrentMaxValue) / CONVERT(DECIMAL(38,2), 9223372036854775807)
			ELSE CONVERT(DECIMAL(20,2), -1)
			END
	FROM #Data d
) AS cte
WHERE 1=1
AND cte.IsFkColumn = 0
ORDER BY cte.[Usage] DESC, cte.TableName ASC, cte.ColumnName ASC
GO
