--=================================================================================================
-- Rebuild or Reorganize the indexes based on their current level of fragmentation.
--=================================================================================================

SET NOCOUNT ON

DECLARE @RebuildFragmentation		FLOAT = 30.0
DECLARE @RebuildOnline				BIT = 1
DECLARE @MinStatisticsAgeInHours	INT = NULL
DECLARE @MaxDopRestriction			TINYINT = NULL -- Use all the processors
DECLARE @TraceOnly					BIT = 1

/*
Rebuild or Reorganise indexes as required, indexes with fragmentation below 5% are ignored.
See: http://msdn.microsoft.com/en-us/library/ms188917.aspx

170812		dungeym		initial scripting

@RebuildFragmentation: the switch between what is REBUILT and what is REORGANISED
@RebuildOnline: set to 1 to rebuild the indexes online if this version of MS SQL supports it
@MinStatisticsAgeInHours: update STATS if not NULL and Index LastUpdated age is great than GETDATE() - @MinStatisticsAgeInHours
@MaxDopRestriction: Max Degree of Parallelism, how many processors can be used if the index is rebuild online
@TraceOnly: set to 1 to output actions (TSQL) without executing actions
*/
	
DECLARE @Object_id INT
DECLARE @Index_id INT
DECLARE @PartitionNumber BIGINT
DECLARE @AvgFragmentation FLOAT
DECLARE @PageCount BIGINT
DECLARE @LastUpdated DATETIME
DECLARE @SchemaName NVARCHAR(130) 
DECLARE @ObjectName NVARCHAR(130) 
DECLARE @IndexName NVARCHAR(130) 
DECLARE @PartitionCount BIGINT	
DECLARE @ProcessorCount INT
DECLARE @CanOnlineRebuild BIT

IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
IF OBJECT_ID('tempdb..#ProcessorData') IS NOT NULL BEGIN DROP TABLE #ProcessorData END;

CREATE TABLE #ProcessorData 
(
	[Index]				INT
	,Name				VARCHAR(128)
	,InternalValue		INT
	,CharacterValue		INT
)


INSERT INTO #ProcessorData
EXECUTE xp_msver 'ProcessorCount'
SET @ProcessorCount = (SELECT TOP 1 InternalValue FROM #ProcessorData)
SET @MaxDopRestriction = ISNULL(@MaxDopRestriction, @ProcessorCount)


SET @CanOnlineRebuild = 0
IF (SELECT SERVERPROPERTY('EditionID')) IN (1804890536, 610778273, -2117995310)
BEGIN 
	SET @CanOnlineRebuild = 1
END


PRINT N'======================================================================================='
PRINT N'Trace Only = ' + CONVERT(NVARCHAR(25), @TraceOnly)
PRINT N'Rebuild Fragmentation = ' + CONVERT(NVARCHAR(25), @RebuildFragmentation)	
PRINT N'Rebuild Online = ' + CONVERT(NVARCHAR(25), @RebuildOnline)
PRINT N'Can Rebuild Online = ' + CONVERT(NVARCHAR(25), @CanOnlineRebuild)
PRINT N'Processesor Count = ' + CONVERT(NVARCHAR(25), @ProcessorCount)
PRINT N'Max Degree of Parallelism = ' + CONVERT(NVARCHAR(25), @MaxDopRestriction)
PRINT N'======================================================================================='
PRINT N''


-- Populate the #Table with data from the SP
SELECT
	[Object_id] = ips.[object_id]
	,[Index_id] = ips.index_id		
	,AvgFragmentation = ips.avg_fragmentation_in_percent
	,PartitionNumber = ips.partition_number
	,[PageCount] = ips.page_count
	,TableName = OBJECT_NAME(ips.[object_id])
	,IndexName = idx.[name]
	,ActionGroup = CASE 
		WHEN ips.page_count <= 8 THEN 3
		WHEN ips.avg_fragmentation_in_percent <= 5.0 THEN 3
		WHEN ips.avg_fragmentation_in_percent > 5.0 AND ips.avg_fragmentation_in_percent < @RebuildFragmentation THEN 2
		ELSE 1
		END
	,LastUpdated = STATS_DATE(ips.[object_id], ips.index_id)
INTO #Data
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED') ips
JOIN sys.indexes idx ON ips.[object_id] = idx.[object_id] AND ips.index_id = idx.index_id
WHERE ips.index_id > 0 -- ignore HEAP indexes


DECLARE My_Cursor CURSOR FOR 
SELECT [Object_id], Index_id, PartitionNumber, AvgFragmentation, [PageCount], LastUpdated
FROM #Data
ORDER BY ActionGroup ASC, TableName ASC, IndexName ASC

OPEN My_Cursor

FETCH NEXT FROM My_Cursor
INTO @Object_id, @Index_id, @PartitionNumber, @AvgFragmentation, @PageCount, @LastUpdated
		
WHILE @@FETCH_STATUS = 0
BEGIN		
	
	DECLARE @IndexTSQL NVARCHAR(4000) 
	DECLARE @StatisticsTSQL NVARCHAR(4000) 
	DECLARE @PartitionTSQL NVARCHAR(255)
	DECLARE @FragmentationDescription NVARCHAR(25)
	DECLARE @LastUpdatedDescription NVARCHAR(25)
	DECLARE @PageCountDescription NVARCHAR(25)
	DECLARE @ContainsLOB BIT	
	DECLARE @ErrorMessage NVARCHAR(MAX)	

	SELECT 
		@ObjectName = QUOTENAME(o.name)
		,@SchemaName = QUOTENAME(s.name)
	FROM sys.objects AS o WITH (NOLOCK)
	JOIN sys.schemas as s WITH (NOLOCK) ON s.schema_id = o.schema_id
	WHERE 1=1
	AND o.[object_id] = @Object_id
	
	SELECT 
		@IndexName = QUOTENAME(i.name)
	FROM sys.indexes i WITH (NOLOCK)
	WHERE 1=1
	AND i.[object_id] = @Object_id 
	AND i.index_id = @Index_id
	
	SELECT 
		@PartitionCount = COUNT(*)
	FROM sys.partitions p WITH (NOLOCK)
	WHERE 1=1
	AND [object_id] = @Object_id 
	AND index_id = @Index_id		
	
	SET @ContainsLOB = 0
	IF (SELECT COUNT(1)
		FROM sys.columns c WITH (NOLOCK)
		WHERE c.[object_id] = @Object_id
		AND (c.system_type_id In (34, 35, 99) OR max_length = -1)
		-- system_type_id: 34 => image, 35 => text, 99 => ntext
		-- max_length: = -1 => varbinary(max), varchar(max), nvarchar(max), xml 
		) > 0
	BEGIN
		SET @ContainsLOB = 1
	END


	-- Build the @IndexTSQL
	SET @IndexTSQL = N'ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @ObjectName
	SET @StatisticsTSQL = N'UPDATE STATISTICS ' + @SchemaName + N'.' + @ObjectName + N' ' + @IndexName + N' WITH FULLSCAN'
	
	SET @PartitionTSQL = NULL
	IF @PartitionCount > 1
	BEGIN
		SET @PartitionTSQL = N' PARTITION = ' + CAST(@PartitionNumber AS NVARCHAR(10))
	END
	
	IF (@AvgFragmentation < @RebuildFragmentation AND @AvgFragmentation > 5.0) OR (@AvgFragmentation >= @RebuildFragmentation AND (@ContainsLOB = 1 OR @PartitionCount > 1))
	BEGIN
		SET @IndexTSQL = @IndexTSQL + N' REORGANIZE' + ISNULL(@PartitionTSQL, '')
	END
	ELSE
	BEGIN
		IF @RebuildOnline = 1 AND @CanOnlineRebuild = 1 AND @ContainsLOB = 0
		BEGIN
			SET @IndexTSQL = @IndexTSQL + N' REBUILD WITH (ONLINE = ON, MAXDOP = ' + CONVERT(VARCHAR(2), @MaxDopRestriction) + N')';
		END
		ELSE
		BEGIN
			SET @IndexTSQL = @IndexTSQL + N' REBUILD WITH (ONLINE = OFF)';
		END
	END
	

	SET @FragmentationDescription = CONVERT(NVARCHAR(25), @AvgFragmentation)
	SET @LastUpdatedDescription = CONVERT(NVARCHAR(50), @LastUpdated, 120)
	SET @PageCountDescription = CONVERT(NVARCHAR(50), @PageCount)
	
	RAISERROR(N'     %s.%s.%s: %s pages, %s%% fragmented, statistics updated at %s', 0, 0, @SchemaName, @ObjectName, @IndexName, @PageCountDescription, @FragmentationDescription, @LastUpdatedDescription) WITH NOWAIT;
	
	IF @TraceOnly = 1 AND @AvgFragmentation > 5.0 AND @PageCount > 8
	BEGIN
		RAISERROR(N'%s', 0, 0, @IndexTSQL) WITH NOWAIT;
	END
	IF @TraceOnly = 1 AND (@MinStatisticsAgeInHours IS NOT NULL AND DATEDIFF(hh, @LastUpdated, GETDATE()) > ABS(@MinStatisticsAgeInHours))
	BEGIN
		RAISERROR(N'%s', 0, 0, @StatisticsTSQL) WITH NOWAIT;			
	END
	
	IF @TraceOnly = 0 AND @AvgFragmentation > 5.0 AND @PageCount > 8
	BEGIN
		BEGIN TRY
			RAISERROR(N'%s', 0, 0, @IndexTSQL) WITH NOWAIT;
			EXECUTE sp_executesql @IndexTSQL
		END TRY
		BEGIN CATCH
			SET @ErrorMessage = ERROR_MESSAGE()
			RAISERROR(N'EXCEPTION: %s', 0, 0, @ErrorMessage) WITH NOWAIT;
		END CATCH
	END		
	
	IF @TraceOnly = 0 AND (@MinStatisticsAgeInHours IS NOT NULL AND DATEDIFF(hh, @LastUpdated, GETDATE()) > ABS(@MinStatisticsAgeInHours))
	BEGIN 
		BEGIN TRY
			RAISERROR(N'%s', 0, 0, @StatisticsTSQL) WITH NOWAIT;
			EXECUTE sp_executesql @StatisticsTSQL
		END TRY
		BEGIN CATCH				
			SET @ErrorMessage = ERROR_MESSAGE()
			RAISERROR(N'EXCEPTION: %s', 0, 0, @ErrorMessage) WITH NOWAIT;
		END CATCH
	END
	
	-- Next...
	FETCH NEXT FROM My_Cursor
	INTO @Object_id, @Index_id, @PartitionNumber, @AvgFragmentation, @PageCount, @LastUpdated
	
END

CLOSE My_Cursor
DEALLOCATE My_Cursor

IF OBJECT_ID('tempdb..#Data') IS NOT NULL BEGIN DROP TABLE #Data END;
IF OBJECT_ID('tempdb..#ProcessorData') IS NOT NULL BEGIN DROP TABLE #ProcessorData END;

