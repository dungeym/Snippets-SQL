SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnGetDateTime')
BEGIN
	DROP FUNCTION [dbo].[fnGetDateTime]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnGetDateOnly')
BEGIN
	DROP FUNCTION [dbo].[fnGetDateOnly]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnGetDateOnlyAsInt')
BEGIN
	DROP FUNCTION [dbo].[fnGetDateOnlyAsInt]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnStringHashCode')
BEGIN
	DROP FUNCTION [dbo].[fnStringHashCode]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnParseStringToTable')
BEGIN
	DROP FUNCTION [dbo].[fnParseStringToTable]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnLogFileInfo')
BEGIN
	DROP FUNCTION [dbo].[fnLogFileInfo]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnIsWorkingDay')
BEGIN
	DROP FUNCTION [dbo].[fnIsWorkingDay]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnRowCount')
BEGIN
	DROP FUNCTION [dbo].[fnRowCount]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnOffsetWorkingDay')
BEGIN
	DROP FUNCTION [dbo].[fnOffsetWorkingDay]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnGetFirstDayOfMonth')
BEGIN
	DROP FUNCTION [dbo].[fnGetFirstDayOfMonth]
END
GO
IF EXISTS (SELECT 1 from INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND SPECIFIC_NAME = 'fnGetLastDayOfMonth')
BEGIN
	DROP FUNCTION [dbo].[fnGetLastDayOfMonth]
END
GO
CREATE FUNCTION [dbo].[fnGetDateTime] (@Date DATETIME, @Time NVARCHAR(12))
RETURNS DATETIME
AS
BEGIN
   /* This FUNCTION glues together a given date (datetime type) and time (nvarchar) value
   * disregarding the time in the datetime type
   *
   * EXAMPLE: select dbo.fnGetDateTime(getdate(), '17:00')
   */
	RETURN CONVERT(DATETIME, CONVERT(NVARCHAR(12), GETDATE(), 106) + ' ' + @Time)
END
GO
CREATE FUNCTION [dbo].[fnGetDateOnly](@DateWithTime DATETIME)
	RETURNS DATETIME
AS
BEGIN
   /* This FUNCTION strips out the time value for a given datetime type
   * by casting to a date type and back again
   *
   * EXAMPLE: select dbo.fnGetDateOnly(getdate())
   */
	RETURN CAST(CAST(@DateWithTime AS DATE) AS DATETIME)
END
go
CREATE FUNCTION [dbo].[fnGetDateOnlyAsInt](@DateWithTime DATETIME)
	RETURNS INT
AS
BEGIN
   /* This FUNCTION returns a datetime type as a yyyymmdd formated
   *  field as an integer type
   *
   *  EXAMPLE: select dbo.fnGetDateOnly(getdate())
   */
	RETURN CONVERT(NVARCHAR(8), @DateWithTime, 112)
END
GO
CREATE FUNCTION [dbo].[fnStringHashCode](@Input NVARCHAR(MAX)) RETURNS INT
WITH RETURNS NULL ON NULL INPUT   
BEGIN
  /* This FUNCTION is equivalent to java.lang.String's hashCode method.
   * SQL Server doesn't support arithmetic overflow, which is central to the 
   * published Java algorithm, so we need to perform all operations against
   * a longer data type and explicitly truncate overflow after every 
   * arithmetic operation that modIFies @HashCode. The overflow check is
   * simply to mask the result to 32 bits and check IF the number is larger
   * than (2 ^ 31) - 1. IF the check detects overflow, we subtract (2 ^ 32).
   *
   * EXAMPLE: select dbo.fnStringHashCode('Hi There')
   */
  DECLARE @Index INT, @HashCode BIGINT
  SET @Index = 1
  SET @HashCode = 0
  WHILE @Index <= LEN(@Input)
  BEGIN
    SET @HashCode = (31 * @HashCode) & 0xFFFFFFFF
    IF @HashCode > 2147483647
    BEGIN
      SET @HashCode = @HashCode - 4294967296
    END
    
    SET @HashCode = (@HashCode + UNICODE(SUBSTRING(@Input, @Index, 1))) & 0xFFFFFFFF
    IF @HashCode > 2147483647
    BEGIN
      SET @HashCode = @HashCode - 4294967296
    END
    
    SET @Index = @Index + 1
  END
  RETURN @HashCode
END 
GO
CREATE FUNCTION [dbo].[fnParseStringToTable](@String VARCHAR(MAX), @Delimiter VARCHAR(10))  
RETURNS 
	@ParseResult table (Id INT not null identity(1, 1), Field VARCHAR(MAX))  
AS  
BEGIN  
   /* This FUNCTION parses a delimited list of "things" into 
   *  a table variable.  Very useful for passing bi lists of 
   *  id's back from websites to the database.  Very useful.
   *
   *  EXAMPLE: select * from dbo.fnParseStringToTable('Hello,World,My,Name,Is', ',')
   */
	DECLARE  
	@Pos INT,  
	@LastPos INT,  
	@Field VARCHAR(MAX),  
	@DelimiterLength INT,
	@StringLength INT
	
	SELECT @StringLength=LEN(@String), @DelimiterLength=LEN(@Delimiter)
	
	IF( @StringLength > 0 and @DelimiterLength > 0 )
	BEGIN
		SELECT @Pos = charindex(@Delimiter, @String), @LastPos = 1  
		while @Pos > 0  
		BEGIN  
			SELECT @Field = substring(@String, @LastPos, @Pos - @LastPos)  
			INSERT INTO @ParseResult (Field) values (LTRIM(RTRIM(@Field)))
			
			SELECT @LastPos = @Pos + @DelimiterLength  
			SELECT @Pos = charindex(@Delimiter, @String, @LastPos)  
		END    

		--IF delimiter is last character then add empty row
		IF @LastPos = LEN(@String) + @DelimiterLength  
		BEGIN  
			SELECT @Field = ''
			INSERT INTO @ParseResult (Field) values (LTRIM(RTRIM(@Field)))
		END   
		ELSE 
		BEGIN
			--IF still data after last delimiter then load
			IF @LastPos < @StringLength + @DelimiterLength
			BEGIN  
				SELECT @Field = SUBSTRING(@String, @LastPos, (@StringLength - @LastPos) + @DelimiterLength)  
				INSERT INTO @ParseResult (Field) values (LTRIM(RTRIM(@Field))) 
			END
		END
		
	END
  
	RETURN   
  
END 

GO
CREATE FUNCTION [dbo].[fnLogFileInfo] ( )
RETURNS @LogInfo TABLE
    (
      [Database Name] sysname ,
      [Log Reuse Wait Description] NVARCHAR(60) ,
      [Log Used %] FLOAT
    )
AS 
BEGIN
   /* This FUNCTION returns a table containing information on the log files
   *  of all DB's on the server
   *
   *  EXAMPLE: select * from dbo.fnLogFileInfo()
   */
    INSERT  @LogInfo
            SELECT  d.[name] AS [Database Name] ,
                    d.log_reuse_wait_desc AS [Log Reuse Wait Description] ,
                    [Log Used %] = CAST(pc.cntr_value AS FLOAT)
            FROM    sys.databases AS d
                    INNER JOIN sys.dm_os_performance_counters pc ON d.NAME = pc.instance_name
            WHERE   pc.counter_name = 'Percent Log Used' 
    RETURN
END      
GO
CREATE FUNCTION [dbo].[fnIsWorkingDay](@date DATETIME)
RETURNS BIT
AS
BEGIN

  /* This FUNCTION returns a bit which determines if a date falls on a Saturday or Sunday
   * or not.  If not then result = 0 else 1.  Note - it is agnostic of the server "datefirst"
   * setting, which is normally 7 (Sunday)
   *
   *  EXAMPLE: select * from dbo.fnIsWorkingDay(getdate())
   */
	DECLARE @RetVal BIT
	SELECT @RetVal = CASE WHEN @@DATEFIRST + DATEPART(WEEKDAY, @date) IN (7,8) THEN 1 ELSE 0 END
	RETURN @RetVal
END
GO
CREATE FUNCTION [dbo].[fnRowCount] ( @OBJECT_ID INT )
RETURNS INT
AS 
BEGIN
  /* This FUNCTION returns the rowcount for the given object_id
   *
   *  EXAMPLE: select dbo.fnRowCount(object_id('tblCashflow'))
   */
    DECLARE @retval INT

    SELECT  @retval = ps.row_count
    FROM    sys.dm_db_partition_stats AS ps
            INNER JOIN sys.indexes AS i ON i.[OBJECT_ID] = ps.[OBJECT_ID]
                                           AND i.index_id = ps.index_id
    WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' )
            AND OBJECTPROPERTY(i.OBJECT_ID, 'IsUserTable') = 1
            AND i.OBJECT_ID = @OBJECT_ID


    RETURN @retval
END

GO
CREATE FUNCTION  [dbo].[fnOffsetWorkingDay](@startDate DATETIME, @offSET INT )
RETURNS DATETIME
AS
BEGIN 
  /* This FUNCTION returns a datetime type which has been offset by the given integer
   * whilst taking into account working/non-working days (Sat and Sun)
   *
   *  EXAMPLE: select  dbo.fnOffsetWorkingDay(getdate(),10)
   */
	DECLARE @RETURNDate DATETIME
	DECLARE @incrementor INT

	SELECT @incrementor =
	CASE
		WHEN @offSET = 0 THEN 0
		WHEN @offSET > 0 THEN 1
		WHEN @offSET < 0 THEN -1
	END
	
	WHILE(@RETURNDate is null) 
	BEGIN
		IF( dbo.fnIsWorkingDay(@startDate) = 1 ) 
		BEGIN
			IF ( @offSET = 0 )
			BEGIN
				SET @RETURNDate =  @startDate
				break
			END
			ELSE
				SET @offSET = abs(@offset) - 1
		END	
		SELECT @startDate = DATEADD(dd,@incrementor,@startDate)
	END
	
	RETURN @RETURNDate
END
GO
CREATE FUNCTION dbo.[fnGetFirstDayOfMonth](@date DATETIME)
	RETURNS DATETIME
AS
BEGIN
  /* This FUNCTION returns a datetime type which represents the first 
   * day of the month for the given date
   *
   *  EXAMPLE: select  dbo.fnGetFirstDayOfMonth(getdate())
   */
	DECLARE @retValue DATETIME, @Month INT, @Year INT
	
	SELECT	@Month = datepart(mm, @date)
			,@Year = datepart(yy, @date)
	
	SET @retValue = 
		CONVERT (DATETIME,
			CONVERT	(NVARCHAR(8),
				CONVERT(VARCHAR(4), @Year) 
				+ CASE when @Month < 10 THEN '0' + CONVERT(VARCHAR(1), @Month)  ELSE CONVERT(VARCHAR(2), @Month) END
				+ CONVERT(NVARCHAR(2), '01')
				)
			)
			
	RETURN @retValue
END
GO
CREATE FUNCTION dbo.[fnGetLastDayOfMonth](@date DATETIME)
	RETURNS DATETIME
AS
BEGIN
  /* This FUNCTION returns a datetime type which represents the last 
   * day of the month for the given date. 
   *
   *  EXAMPLE: select  dbo.fnGetLastDayOfMonth(getdate())
   */
	DECLARE @retValue DATETIME
	
	SELECT @retValue = DATEADD(dd, -1,DATEADD(mm, DATEDIFF(m,0,@date)+1,0))
	
	RETURN @retValue
END
go

