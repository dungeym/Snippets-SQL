
IF EXISTS(SELECT * FROM sys.procedures WHERE [name] = 'uspxFileUsage')
BEGIN
	DROP PROCEDURE dbo.uspxFileUsage
	PRINT 'DROP PROCEDURE dbo.uspxFileUsage'
END
GO

CREATE PROCEDURE dbo.uspxFileUsage
AS 
BEGIN

	SELECT
		[Name] = f.name	    
		,[File Size (MB)] = ((f.size * 8) / 1024.00)
		,[Space Used (MB)] = CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0
		,[Free Space (MB)] = ((f.size * 8) / 1024.00) - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0
		,[Used (%)] = (CONVERT(DECIMAL(25,4), (CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0) / ((f.size * 8) / 1024.00))) *100
		,[Max Size (MB)] = CASE 
			WHEN f.max_size = 0 THEN 'Fixed'
			WHEN f.max_size = -1 THEN 'Unlimited'
			ELSE CONVERT(NVARCHAR(25), ((f.max_size * 8.00) / 1024.00))
			END
		,[Auto Grow] = CASE 
			WHEN f.growth = 0 THEN 'None'
			WHEN f.is_percent_growth = 1 THEN CONVERT(NVARCHAR(25), f.growth) + ' %'
			WHEN f.is_percent_growth = 0 THEN CONVERT(NVARCHAR(25), CONVERT(INT,((f.growth * 8) / 1024.00))) + ' MB'
			ELSE NULL
			END
		,[Path] = f.physical_name
		-- ,f.*
	FROM sys.database_files AS f;
	
END
GO

GRANT EXEC ON dbo.uspxFileUsage TO PUBLIC;