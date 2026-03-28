ALTER DATABASE CURRENT SET AUTO_SHRINK ON;


SELECT
   @@SERVERNAME AS ServerName,
   name,
   is_auto_shrink_on
FROM sys.databases
where name <> 'master'