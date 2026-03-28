SELECT @@SERVERNAME AS ServerName
	,name
	,is_auto_shrink_on
FROM sys.databases
WHERE name <> 'master'
