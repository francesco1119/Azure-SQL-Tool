/**
Find Indexes Not In Use
https://web.archive.org/web/20130507090210/http://sqlserverpedia.com/wiki/Find_Indexes_Not_In_Use
**/

SELECT o.name
	,indexname = i.name
	,i.index_id
	,reads = user_seeks + user_scans + user_lookups
	,writes = user_updates
	,rows = (
		SELECT SUM(p.rows)
		FROM sys.partitions p
		WHERE p.index_id = s.index_id
			AND s.object_id = p.object_id
		)
	,CASE 
		WHEN s.user_updates < 1
			THEN 100
		ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
		END AS reads_per_write
	,'DROP INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) AS 'drop statement'
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON i.index_id = s.index_id
	AND s.object_id = i.object_id
INNER JOIN sys.objects o ON s.object_id = o.object_id
INNER JOIN sys.schemas c ON o.schema_id = c.schema_id
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
	AND s.database_id = DB_ID()
	AND i.type_desc = 'nonclustered'
	AND i.is_primary_key = 0
	AND i.is_unique_constraint = 0
	AND (
		SELECT SUM(p.rows)
		FROM sys.partitions p
		WHERE p.index_id = s.index_id
			AND s.object_id = p.object_id
		) > 10000
ORDER BY reads
