-- Adapted from Glenn Berry's Azure SQL Database Diagnostic Information Queries
-- Copyright (C) Glenn Berry. Non-commercial use only. Credit must be given.
-- https://glennsqlperformance.com/resources/

-- Get some key table properties (Query 41) (Table Properties)
SELECT OBJECT_NAME(t.[object_id]) AS [ObjectName]
	,p.[rows] AS [Table Rows]
	,p.index_id
	,p.data_compression_desc AS [Index Data Compression]
	,t.create_date
	,t.lock_on_bulk_load
	,t.is_replicated
	,t.has_replication_filter
	,t.is_tracked_by_cdc
	,t.lock_escalation_desc
	,t.is_filetable
	,t.is_memory_optimized
	,t.durability_desc
	,t.temporal_type_desc
	,t.is_remote_data_archive_enabled
	,t.is_external -- new for SQL Server 2016
	,'Gives you some good information about your tables. Too many table rows? Too many indexes per table? ' AS Info
FROM sys.tables AS t WITH (NOLOCK)
INNER JOIN sys.partitions AS p WITH (NOLOCK) ON t.[object_id] = p.[object_id]
WHERE OBJECT_NAME(t.[object_id]) NOT LIKE N'sys%'
ORDER BY p.[rows] DESC
	,p.index_id DESC
	------
	-- Gives you some good information about your tables
	-- is_memory_optimized and durability_desc were new in SQL Server 2014
	-- temporal_type_desc, is_remote_data_archive_enabled, is_external are new in SQL Server 2016
	-- sys.tables (Transact-SQL)
	-- https://bit.ly/2Gk7998
