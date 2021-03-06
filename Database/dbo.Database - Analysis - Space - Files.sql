
--=================================================================================================
-- Output sapce information for the files in this database.
--=================================================================================================

SELECT
	[Name] = f.name	 
	,[State] = f.state_desc		
	,[FileSizeMB] = ((f.[size] * 8) / 1024.00)
	,[SpaceUsedMB] = CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0
	,[FreeSpaceMB] = ((f.[size] * 8) / 1024.00) - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0
	,[UsedPercent] = (CONVERT(DECIMAL(25,4), (CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0) / ((f.[size] * 8) / 1024.00))) *100
	,[MaxSizeMB] = CASE 
		WHEN f.max_size = 0 THEN 'Fixed'
		WHEN f.max_size = -1 THEN 'Unlimited'
		ELSE CONVERT(NVARCHAR(25), ((f.max_size * 8.00) / 1024.00))
		END
	,[AutoGrow] = CASE 
		WHEN f.growth = 0 THEN 'None'
		WHEN f.is_percent_growth = 1 THEN CONVERT(NVARCHAR(25), f.growth) + ' %'
		WHEN f.is_percent_growth = 0 THEN CONVERT(NVARCHAR(25), CONVERT(INT,((f.growth * 8) / 1024.00))) + ' MB'
		ELSE NULL
		END
	,[Path] = f.physical_name
FROM sys.database_files AS f;
GO