
IF EXISTS(SELECT * FROM sys.triggers WHERE [name] = 'trDatabaseVersion')
BEGIN
	DROP TRIGGER trDatabaseVersion ON DATABASE
	PRINT 'DROPPED TRIGGER [trDatabaseVersion] ON DATABASE'
END
GO

CREATE TRIGGER trDatabaseVersion ON DATABASE
FOR 
	DDL_TABLE_EVENTS
	,DDL_VIEW_EVENTS
	,DDL_PROCEDURE_EVENTS
	,DDL_FUNCTION_EVENTS
	,DDL_TRIGGER_EVENTS
	,DDL_INDEX_EVENTS	
	--,DDL_SCHEMA_EVENTS
	--,DDL_SYNONYM_EVENTS
	--,DDL_DATABASE_SECURITY_EVENTS
	--,DDL_FULLTEXT_CATALOG_EVENTS
	,DDL_TYPE_EVENTS
	,DDL_DEFAULT_EVENTS
	--,DDL_PARTITION_EVENTS
	--,DDL_ASSEMBLY_EVENTS
AS
BEGIN
	/*
	A trigger to monitor changes to the database and update an Extended Property with an incremented 
	version that is in keeping with the standard format used by the Phoenix Development Team.

	DDL Event Groups: http://msdn.microsoft.com/en-us/library/bb510452.aspx
	DDL Events: http://msdn.microsoft.com/en-us/library/bb522542.aspx

	Example: 4.0.14316.5
	Major: any numeric value, changes should represent a major rewrite or functional change.
	Minor: any numeric value, changes should represent a significant functional change.
	Build: automatic 2 part value, the first 2 digits are the last 2 digits of the current year, the last 3 digits represent the N'th day of the year
	Revision: automatic value, represents the N'th change of the same day as the @Build

	12112014	dungeym		initial scripting
	*/
	SET NOCOUNT ON

	-- EXEC sp_dropextendedproperty @name = N'Database Version'
	-- SELECT * FROM sys.extended_properties
	
	DECLARE @ExtendedProperty NVARCHAR(255) = 'Database Version'
	DECLARE @Major NVARCHAR(25)
	DECLARE @Minor NVARCHAR(25)
	DECLARE @Build NVARCHAR(25)
	DECLARE @Revision NVARCHAR(25)
	DECLARE @Version NVARCHAR(25) = (SELECT CONVERT(VARCHAR(12), value) FROM sys.extended_properties WITH (NOLOCK) WHERE class = 0 AND [name] = @ExtendedProperty)


	--=================================================================================================
	-- First time, extended property doesn't exist, add it
	--=================================================================================================
	IF @Version IS NULL 
	BEGIN
		EXEC sp_addextendedproperty @name = @ExtendedProperty, @value = '1.0.0.0';
		SET @Version = '1.0.0.0'
	END

	--=================================================================================================
	-- Read parts from @Version
	--=================================================================================================
	DECLARE @Start INT = 1
	DECLARE @End INT = CHARINDEX('.', @Version) 
	WHILE @Start < LEN(@Version) + 1 
	BEGIN 
		IF @End = 0 SET @End = LEN(@Version) + 1
		
		--PRINT SUBSTRING(@Version, @Start, @End - @Start)
		IF @Major IS NULL SET @Major = SUBSTRING(@Version, @Start, @End - @Start)
		ELSE IF @Minor IS NULL SET @Minor = SUBSTRING(@Version, @Start, @End - @Start)
		ELSE IF @Build IS NULL SET @Build = SUBSTRING(@Version, @Start, @End - @Start)
		ELSE IF @Revision IS NULL SET @Revision = SUBSTRING(@Version, @Start, @End - @Start)
		
		SET @Start = @End + 1
		SET @End = CHARINDEX('.', @Version, @Start)

	END 


	--=================================================================================================
	-- Increment Build/Revision
	--=================================================================================================
	DECLARE @NewBuild NVARCHAR(25) = SUBSTRING(CONVERT(NVARCHAR(4), YEAR(GETUTCDATE())), 3, 2) + CONVERT(NVARCHAR(5), DATEPART(DAYOFYEAR, GETUTCDATE()))
	IF @NewBuild != @Build
	BEGIN
		SET @Build = @NewBuild
		SET @Revision = '0'
	END
	ELSE
	BEGIN
		SET @Revision = CONVERT(NVARCHAR(25), CONVERT(INT, @Revision) + 1)
	END


	--=================================================================================================
	-- Update the property
	--=================================================================================================
	SET @Version = @Major + '.' + @Minor + '.' + @Build + '.' + @Revision
	PRINT 'Database Version: ' + @Version
	EXEC sp_updateextendedproperty @name = @ExtendedProperty, @value = @Version;

END
GO