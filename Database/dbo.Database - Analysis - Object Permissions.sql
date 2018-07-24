
--=================================================================================================
-- Output the permissions applied to the objects in the database.
--=================================================================================================

DECLARE @ObjectName NVARCHAR(255)
--SET @ObjectName = 'MySpecifcObjectName'

SELECT
	cte.ObjectType 
	,cte.ObjectName
	,cte.PermissionType 
	,cte.PermissionState 
	,cte.UserName 
	,cte.UserType 
	,cte.DatabaseUserName 
	,cte.[Role]
FROM 
(
		-- Collate access information provide directly
		SELECT
			UserName = CASE principal.[type] 
				WHEN 'S' THEN principal.name
				WHEN 'U' THEN token.name COLLATE Latin1_General_CI_AI
				END
			,UserType = CASE principal.[type]
				WHEN 'S' THEN 'SQL User'
				WHEN 'U' THEN 'Windows User'
				ELSE principal.[type]
				END
			,DatabaseUserName = principal.name
			,[Role] = NULL
			,PermissionType = permission.permission_name
			,PermissionState = permission.state_desc
			,ObjectType = obj.type_desc
			,ObjectName = OBJECT_NAME(permission.major_id)
			,ColumnName = col.name
		FROM sys.database_principals principal 
		LEFT JOIN sys.login_token token ON principal.sid = token.sid -- Login accounts
		LEFT JOIN sys.database_permissions permission ON permission.grantee_principal_id = principal.principal_id -- Permissions
		LEFT JOIN sys.columns col ON col.[object_id] = permission.major_id AND col.column_id = permission.minor_id -- Table columns
		LEFT JOIN sys.objects obj ON permission.major_id = obj.[object_id]
		WHERE 1=1
		AND principal.[type] in ('S','U')
	UNION
		--List all access provisioned to a sql user or windows user/group through a database or application role
		SELECT
			UserName = CASE memberPrincipal.[type] 
				WHEN 'S' THEN memberPrincipal.name
				WHEN 'U' THEN token.name COLLATE Latin1_General_CI_AI
				END
			,UserType = CASE memberPrincipal.[type]
				WHEN 'S' THEN 'SQL User'
				WHEN 'U' THEN 'Windows User'							
				ELSE principal.[type]
				END 
			,DatabaseUserName = memberPrincipal.name
			,[Role] = principal.name
			,PermissionType = permission.permission_name
			,PermissionState = permission.state_desc
			,ObjectType = obj.type_desc
			,ObjectName = OBJECT_NAME(permission.major_id)
			,ColumnName = col.name
		FROM sys.database_role_members members 
		JOIN sys.database_principals principal ON principal.principal_id = members.role_principal_id 
		JOIN sys.database_principals memberPrincipal ON memberPrincipal.principal_id = members.member_principal_id 
		LEFT JOIN sys.login_token token ON memberPrincipal.sid = token.sid 
		LEFT JOIN sys.database_permissions permission ON permission.grantee_principal_id = principal.principal_id 
		LEFT JOIN sys.columns col ON col.[object_id] = permission.major_id AND col.column_id = permission.minor_id 
		LEFT JOIN sys.objects obj ON permission.major_id = obj.[object_id]
	UNION
		--List all access provisioned to the public role, which everyone gets by default
		SELECT
			UserName = '{All Users}'
			,UserType = '{All Users}' 
			,DatabaseUserName = '{All Users}'
			,[Role] = principal.name
			,PermissionType = permission.permission_name
			,PermissionState = permission.state_desc
			,ObjectType = obj.type_desc
			,ObjectName = OBJECT_NAME(permission.major_id)
			,ColumnName = col.name
		FROM sys.database_principals principal 
		LEFT JOIN sys.database_permissions permission ON permission.grantee_principal_id = principal.principal_id 
		LEFT JOIN sys.columns col ON col.[object_id] = permission.major_id AND col.column_id = permission.minor_id 
		JOIN sys.objects obj ON obj.[object_id] = permission.major_id 
	WHERE 1=1
	AND principal.[type] = 'R'			-- Only roles.
	AND principal.name = 'public'		-- Only public role.
	AND obj.is_ms_shipped = 0			-- Only objects that are ours (not the Mcirosoft objects).
) AS cte
WHERE 1=1
AND (@ObjectName IS NULL OR cte.ObjectName = @ObjectName)
ORDER BY cte.ObjectType ASC, cte.ObjectName ASC, cte.PermissionType ASC, cte.PermissionState ASC
GO


