
/*
Notes:
- the temp table, #Data, is created with an INDEX (on the [id] PRIMARY KEY column).  Small performance cost.
- the batch operations use the [id] from #Data to access the [Entity_id] which uses the INDEX. Good performance.
- there's no need to popluate #Data with Entity_id values is a specific order. Performance saving.
- there's no additional overhead from other approaches that require updating or continual scanning of the temp table. Performance saving.
*/

SET NOCOUNT ON

-- Create temp table
IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
CREATE TABLE #Data
(
	id			INT IDENTITY(1,1) PRIMARY KEY,
	Entity_id	INT NOT NULL
)


-- Popluate temp table
INSERT INTO #Data (Entity_id)
SELECT TOP 100100 le.id
FROM dbo.tblLogEntry le WITH (NOLOCK)
WHERE 1=1


-- Batch operation settings
DECLARE @BatchSize INT = 5000
DECLARE @id INT = 0
DECLARE @Max_id INT = (SELECT MAX(id) FROM #Data)


WHILE @id <= @Max_id
BEGIN

	-- ===============================================================================================
	-- BATCH OPERATION - START
	-- ===============================================================================================
	
	BEGIN TRY
		-- Create a TRANSACTION if needed
		
		SELECT 
			Min_id = MIN(id)
			, Max_id = MAX(id)
			, Min_Entity_id = MIN(Entity_id)
			, Max_Entity_id = MAX(Entity_id)
			, [id] = @id
			, [BatchSize] = @BatchSize
		FROM #Data
		WHERE id BETWEEN @id AND (@id + @BatchSize)
		
		-- UPDATE Example
		--UPDATE dbo.tblLogEntry SET 
		--	DeletedDate = GETUTCDATE()
		--WHERE id IN (SELECT Entity_id FROM #Data WHERE id BETWEEN @id AND (@id + @BatchSize))
		
		-- DELETE Example
		--DELETE dbo.tblLogEntry 
		--WHERE id IN (SELECT Entity_id FROM #Data WHERE id BETWEEN @id AND (@id + @BatchSize))
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		
		--BREAK; -- exit the loop if you need
	END CATCH;
	
	-- ===============================================================================================
	-- BATCH OPERATION - END
	-- ===============================================================================================
	
	-- Increment @id
	SET @id = @id + @BatchSize
	
END


-- Remove temp table
IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;