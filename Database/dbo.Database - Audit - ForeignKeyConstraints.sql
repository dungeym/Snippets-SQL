
--=================================================================================================
-- Output basic information about the foreign key constraints.
--=================================================================================================

SELECT 
	ForeignKeyConstraintName = OBJECT_NAME(fkc.constraint_object_id)
	, ParentTableName = pt.name
	, ParentColumnName = pc.name
	, ReferencedTableName = rt.name
	, ReferencedColumnName = rc.name
FROM sys.foreign_key_columns fkc
INNER JOIN sys.tables pt ON pt.object_id = fkc.parent_object_id
INNER JOIN sys.columns pc ON pc.object_id = pt.object_id AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.tables rt ON rt.object_id = fkc.referenced_object_id
INNER JOIN sys.columns rc ON rc.object_id = rt.object_id AND rc.column_id = fkc.referenced_column_id
WHERE 1=1

-- ALTER TABLE <Schema>.<TableName> NOCHECK CONSTRAINT <Constraint Name>
-- ALTER TABLE <Schema>.<TableName> CHECK CONSTRAINT <Constraint Name>
