--=================================================================================================
-- Output the permissions applied to the objects in the database.
--=================================================================================================

	SELECT  
		[UserName] = CASE princ.[type] 
						WHEN 'S' THEN princ.[name]
						WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
					 END,
		[UserType] = CASE princ.[type]
						WHEN 'S' THEN 'SQL User'
						WHEN 'U' THEN 'Windows User'
					 END,  
		[DatabaseUserName] = princ.[name],       
		[Role] = null,      
		[PermissionType] = perm.[permission_name],       
		[PermissionState] = perm.[state_desc],       
		[ObjectType] = obj.type_desc,--perm.[class_desc],       
		[ObjectName] = OBJECT_NAME(perm.major_id),
		[ColumnName] = col.[name]
	FROM sys.database_principals princ -- database user
	LEFT JOIN sys.login_token ulogin on princ.[sid] = ulogin.[sid] -- Login accounts
	LEFT JOIN sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id] -- Permissions
	LEFT JOIN sys.columns col ON col.[object_id] = perm.major_id AND col.[column_id] = perm.[minor_id] -- Table columns
	LEFT JOIN sys.objects obj ON perm.[major_id] = obj.[object_id]
	WHERE 1=1
	AND princ.[type] in ('S','U')
UNION
	--List all access provisioned to a sql user or windows user/group through a database or application role
	SELECT  
		[UserName] = CASE memberprinc.[type] 
						WHEN 'S' THEN memberprinc.[name]
						WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
					 END,
		[UserType] = CASE memberprinc.[type]
						WHEN 'S' THEN 'SQL User'
						WHEN 'U' THEN 'Windows User'
					 END, 
		[DatabaseUserName] = memberprinc.[name],   
		[Role] = roleprinc.[name],      
		[PermissionType] = perm.[permission_name],       
		[PermissionState] = perm.[state_desc],       
		[ObjectType] = obj.type_desc,--perm.[class_desc],   
		[ObjectName] = OBJECT_NAME(perm.major_id),
		[ColumnName] = col.[name]
	FROM sys.database_role_members members -- Role/member associations
	JOIN sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id] -- Roles
	JOIN sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id] -- Role members (database users)
	LEFT JOIN sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid] -- Login accounts
	LEFT JOIN sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id] -- Permissions
	LEFT JOIN sys.columns col on col.[object_id] = perm.major_id AND col.[column_id] = perm.[minor_id] -- Table columns
	LEFT JOIN sys.objects obj ON perm.[major_id] = obj.[object_id]
UNION
	--List all access provisioned to the public role, which everyone gets by default
	SELECT  
		[UserName] = '{All Users}',
		[UserType] = '{All Users}', 
		[DatabaseUserName] = '{All Users}',       
		[Role] = roleprinc.[name],      
		[PermissionType] = perm.[permission_name],       
		[PermissionState] = perm.[state_desc],       
		[ObjectType] = obj.type_desc,--perm.[class_desc],  
		[ObjectName] = OBJECT_NAME(perm.major_id),
		[ColumnName] = col.[name]
	FROM sys.database_principals roleprinc -- Roles
	LEFT JOIN sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id] -- Role permissions
	LEFT JOIN sys.columns col on col.[object_id] = perm.major_id AND col.[column_id] = perm.[minor_id] -- Table columns
	JOIN sys.objects obj ON obj.[object_id] = perm.[major_id] -- All objects
WHERE 1=1
AND roleprinc.[type] = 'R' -- Only roles
AND roleprinc.[name] = 'public' -- Only public role
AND obj.is_ms_shipped = 0 -- Only objects of ours, not the MS objects
ORDER BY
princ.[Name] ASC,
OBJECT_NAME(perm.major_id) ASC,
col.[name] ASC,
perm.[permission_name] ASC,
perm.[state_desc] ASC,
obj.type_desc ASC
GO