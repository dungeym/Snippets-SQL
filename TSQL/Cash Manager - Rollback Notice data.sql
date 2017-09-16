--=================================================================================================
-- Delete notice-related information from AFTER the initial tblSentMessage row is created.
--=================================================================================================
DECLARE @Notice_id INT = 83

SELECT 'tblNotice', * 
FROM dbo.tblNotice WITH (NOLOCK)
WHERE 1=1
AND ID = @Notice_id


SELECT 'tblSentMessage', * 
FROM dbo.tblSentMessage WITH (NOLOCK)
WHERE 1=1
AND KeyID = @Notice_id
AND TypeID IN (11, 12)

-- UPDATE dbo.tblSentMessage SET StatusID = 1, RetryAttempt = 0, MessageGuid = NEWID() WHERE id = 24075588
-- DELETE dbo.tblSentMessageXml WHERE MessageID = 24075588


-- SELECT 'tblDistributionChannel', * 
DELETE
FROM dbo.tblDistributionChannel
WHERE 1=1
AND DistributionID IN (SELECT id FROM dbo.tblDistribution WITH (NOLOCK) WHERE KeyID = @Notice_id)


-- SELECT 'tblDistributionChannelInformation', * 
DELETE
FROM dbo.tblDistributionChannelInformation
WHERE 1=1
AND DistributionID IN (SELECT id FROM dbo.tblDistribution WITH (NOLOCK) WHERE KeyID = @Notice_id)


-- SELECT 'tblDistributionDocument', * 
DELETE
FROM dbo.tblDistributionDocument
WHERE 1=1
AND DistributionID IN (SELECT id FROM dbo.tblDistribution WITH (NOLOCK) WHERE KeyID = @Notice_id)


-- SELECT 'tblDistributionEmail', * 
DELETE
FROM dbo.tblDistributionEmail
WHERE 1=1
AND DistributionID IN (SELECT id FROM dbo.tblDistribution WITH (NOLOCK) WHERE KeyID = @Notice_id)


-- SELECT 'tblWorkflowStatus', * 
DELETE
FROM dbo.tblWorkflowStatus
WHERE 1=1
AND DistributionID IN (SELECT DistributionGUID FROM dbo.tblDistribution WITH (NOLOCK) WHERE KeyID = @Notice_id)


-- SELECT 'tblDocumentGenerationStatus', * 
DELETE
FROM dbo.tblDocumentGenerationStatus
WHERE 1=1
AND SentMessageID IN (SELECT id FROM dbo.tblSentMessage WITH (NOLOCK) WHERE KeyID = @Notice_id AND TypeID IN (11, 12))


-- SELECT 'tblDistribution', * 
DELETE
FROM dbo.tblDistribution 
WHERE 1=1
AND KeyID = @Notice_id