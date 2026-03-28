SELECT sch.name AS SchemaName
	,o.name AS ObjectName
	,i.name AS IndexName
	,o.type_desc AS ObjectType
	,-- Added this column to show the type of the object
	i.type_desc AS IndexType
	,-- Added column to show the type of the index
	MAX(s.row_count) AS 'Rows'
	,SUM(s.reserved_page_count) * 8.0 / (1024 * 1024) AS 'GB'
	,(8 * 1024 * SUM(s.reserved_page_count)) / MAX(s.row_count) AS 'Bytes/Row'
	,'Search for the biggest tables and the biggest Bytes/Row' AS Description
FROM sys.dm_db_partition_stats s
JOIN sys.indexes i ON s.object_id = i.object_id
	AND s.index_id = i.index_id
JOIN sys.objects o ON i.object_id = o.object_id
JOIN sys.schemas sch ON o.schema_id = sch.schema_id
WHERE s.index_id > 0
GROUP BY sch.name
	,o.name
	,i.name
	,o.type_desc -- Need to group by this as well since it's now part of the SELECT clause
	,i.type_desc
HAVING SUM(s.row_count) > 0
ORDER BY GB DESC
	,o.name
	,'Bytes/Row';-- Corrected order by syntax for clarity
