
-- ================================================================================================
-- Output the table names in dependancy order.

-- Jamie Thomson
-- http://sqlblog.com/blogs/jamie_thomson/archive/2009/09/08/deriving-a-list-of-tables-in-dependency-order.aspx
-- ================================================================================================

WITH fk_tables AS 
(
	SELECT
		FromSchema = s1.name
		,FromTable = o1.Name
		,ToSchema = s2.name
		,ToTable = o2.Name
	FROM sys.foreign_keys fk
	INNER JOIN sys.objects o1 ON fk.parent_object_id = o1.[object_id]
	INNER JOIN sys.schemas s1 ON o1.[schema_id] = s1.[schema_id]
	INNER JOIN sys.objects o2 ON fk.referenced_object_id = o2.[object_id]
	INNER JOIN sys.schemas s2 ON o2.[schema_id] = s2.[schema_id] 
	WHERE 1=1
	AND NOT
	(
		s1.name = s2.name
		AND o1.name = o2.name
	)
)
,ordered_tables AS
(
		SELECT
			SchemaName = s.name
			,TableName = t.name
			,[Level] = 0
		FROM
		(
			SELECT *
			FROM sys.tables
			WHERE 1=1
			AND name != 'sysdiagrams'
		) t
		INNER JOIN sys.schemas s ON t.[schema_id] = s.[schema_id]
		LEFT OUTER JOIN fk_tables fk ON s.name = fk.FromSchema AND t.name = fk.FromTable
		WHERE 1=1
		AND fk.FromSchema IS NULL
	UNION ALL
		SELECT
			fk.FromSchema
			,fk.FromTable
			,ot.[Level] + 1
		FROM fk_tables fk
		INNER JOIN ordered_tables ot ON fk.ToSchema = ot.SchemaName AND fk.ToTable = ot.TableName
)
SELECT DISTINCT
	ot.SchemaName
	,ot.TableName
	,ot.[Level]
FROM ordered_tables ot
INNER JOIN 
(
	SELECT 
		SchemaName
		,TableName
		,[Level] = MAX([Level])
	FROM ordered_tables
	GROUP BY SchemaName, TableName
) mx ON ot.SchemaName = mx.SchemaName AND ot.TableName = mx.TableName AND mx.[Level] = ot.[Level]
ORDER BY ot.[Level] ASC, ot.TableName ASC
GO

