
IF EXISTS(SELECT * FROM sys.objects WHERE type IN ('FN', 'TF') AND [name] = 'fnConvertTicksToDateTime')
BEGIN
	DROP FUNCTION [dbo].[fnConvertTicksToDateTime]
	PRINT 'DROPPED FUNCTION [dbo].[fnConvertTicksToDateTime]'
END
GO

CREATE FUNCTION dbo.fnConvertTicksToDateTime (@Ticks BIGINT)      
RETURNS DATETIME
AS
BEGIN
	-- A Tick (from C#) represents the number of 100-nanosecond intervals that have elapsed since 12:00:00 midnight, January 1, 0001
	-- So a single tick represents one hundred nanoseconds or one ten-millionth of a second. 
	-- There are 10,000 ticks in a millisecond.
	-- 634925952000000000 is the number of Ticks between [1900-01-01 00:00:00] and [2013-01-01 00:00:00]
	
	-- Re-base the @Ticks to [2013-01-01 00:00:00]
	-- Divide to convert to milliseconds, then seconds
	-- Add the seconds [2013-01-01 00:00:00] to get the DateTime that the @Ticks represents
	RETURN DATEADD(s, ((((@Ticks - 634925952000000000) / 10000) / 1000) ), CONVERT(DATETIME, '2013-01-01 00:00:00', 120))

END 
GO