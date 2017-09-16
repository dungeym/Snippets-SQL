SELECT
	[Role] = l.name
	,Permission = p.state_desc
	,[Level] = p.permission_name 
FROM sys.server_permissions AS p WITH (NOLOCK)
JOIN sys.server_principals AS l WITH (NOLOCK) ON p.grantee_principal_id = l.principal_id
WHERE 1=1
AND p.permission_name = 'VIEW SERVER STATE'
