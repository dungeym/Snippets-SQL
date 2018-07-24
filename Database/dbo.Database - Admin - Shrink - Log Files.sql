
--=================================================================================================
-- Shrink the Log files.
-- Change the name of the database in the script.
-- -- http://technet.microsoft.com/en-us/library/ms189493%28v=sql.105%29.aspx
--=================================================================================================

SELECT @@SERVICENAME AS [Server], DB_NAME() AS [Database], GETUTCDATE() AS [Timestamp]
GO


--=================================================================================================
-- Log the size of the database files
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


--=================================================================================================
-- Truncate the log by changing the database recovery model to SIMPLE.
--=================================================================================================
ALTER DATABASE DatabaseName SET RECOVERY SIMPLE;
GO

--=================================================================================================
-- Shrink the truncated log file to 1 MB.
--=================================================================================================
DBCC SHRINKFILE (DatabaseName_log, 1);
GO


--=================================================================================================
-- Reset the database recovery model.
--=================================================================================================
ALTER DATABASE DatabaseName SET RECOVERY FULL;
GO


--=================================================================================================
-- Log the new size of the database files
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
