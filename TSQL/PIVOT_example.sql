--CREATE TABLE tblTest (
--    Id INT
--    ,Col_1 INT
--    )
 
INSERT INTO tblTest
VALUES (
    1
    ,12345
    )
    ,(
    1
    ,23456
    )
    ,(
    1
    ,45678
    )
    ,(
    2
    ,57823
    )
    ,(
    2
    ,11111
    )
    ,(
    2
    ,34304
    )
    ,(
    2
    ,12344
    )
 
DECLARE @MaxCount INT;
 
SELECT @MaxCount = max(cnt)
FROM (
    SELECT Id
        ,count(Col_1) AS cnt
    FROM tblTest
    GROUP BY Id
    ) X;
 
DECLARE @SQL NVARCHAR(max)
    ,@i INT;
 
SET @i = 0;
SET @SQL = '';
 
WHILE @i < @MaxCount
BEGIN
    SET @i = @i + 1;
    SET @SQL = @Sql + ',
    MAX(CASE WHEN RowNo = ' + cast(@i AS NVARCHAR(10)) + ' THEN  Col_1 END) AS Col' + cast(@i AS NVARCHAR(10));
END
 
SET @SQL = N';WITH CTE AS (
   SELECT ID, Col_1, row_number() OVER (PARTITION BY ID ORDER BY Col_1) AS rowno
   FROM   tblTest
)
SELECT ID ' + @SQL + N'
FROM   CTE
GROUP  BY ID';
 
PRINT @SQL;
 
EXECUTE (@SQL);
GO

DECLARE @MaxCount INT;
 
SELECT @MaxCount = max(cnt)
FROM (
    SELECT Id
        ,count(Col_1) AS cnt
    FROM tblTest
    GROUP BY Id
    ) X;
 
DECLARE @SQL NVARCHAR(max)
    ,@i INT;
 
SET @i = 0;
 
WHILE @i < @MaxCount
BEGIN
    SET @i = @i + 1;
    SET @SQL = COALESCE(@Sql + ', ', '') + 'Col' + cast(@i AS NVARCHAR(10));
END
 
SET @SQL = N';WITH CTE AS (
   SELECT ID, Col_1, ''Col'' + CAST(row_number() OVER (PARTITION BY ID ORDER BY Col_1) AS Varchar(10)) AS RowNo
   FROM   tblTest
)
SELECT *
FROM   CTE
PIVOT (MAX(Col_1) FOR RowNo IN (' + @SQL + N')) pvt';
 
PRINT @SQL;
 
EXECUTE (@SQL);
