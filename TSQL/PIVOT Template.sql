
SET NOCOUNT ON
IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;

CREATE TABLE #Data 
(
 Id INT,
 Col_1 INT
)


INSERT INTO #Data
VALUES	(1, 12345),
		(1, 23456),
		(1, 45678),
		(2, 57823),
		(2, 11111),
		(2, 34304),
		(2, 12344)


DECLARE @MaxCount INT = (SELECT MAX([Count]) FROM (SELECT Id, [Count] = COUNT(Col_1) FROM #Data GROUP BY Id) t)
 
DECLARE @SQL NVARCHAR(MAX) = ''
DECLARE @Id INT = 0
 
WHILE @Id < @MaxCount
BEGIN
	SET @Id = @Id + 1;
	SET @SQL = @Sql + ', MAX(CASE WHEN RowNo = ' + CAST(@Id AS NVARCHAR(10)) + ' THEN Col_1 END) AS Col' + CAST(@Id AS NVARCHAR(10));
END


SET @SQL = N';WITH CTE AS 
(
	SELECT 
		ID
		, Col_1
		, RowNo = ROW_NUMBER() OVER (PARTITION BY ID ORDER BY Col_1)
	FROM #Data
)
SELECT ID ' + @SQL + N'
FROM CTE
GROUP BY ID';
 

PRINT @SQL; 
EXECUTE (@SQL);
GO