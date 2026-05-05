-- Adapted from Glenn Berry's Azure SQL Database Diagnostic Information Queries
-- Copyright (C) Glenn Berry. Non-commercial use only. Credit must be given.
-- https://glennsqlperformance.com/resources/

-- Get total buffer usage by database for current instance  (Query 6) (Total Buffer Usage by Database)
-- This make take some time to run on a busy instance
WITH AggregateBufferPoolUsage
AS (
	SELECT DB_NAME(database_id) AS [Database Name]
		,CAST(COUNT_BIG(*) * 8 / 1024.0 AS DECIMAL(15, 2)) AS [CachedSize]
		,COUNT(page_id) AS [Page Count]
		,AVG(read_microsec) AS [Avg Read Time (microseconds)]
	FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
	GROUP BY DB_NAME(database_id)
	)
SELECT ROW_NUMBER() OVER (
		ORDER BY CachedSize DESC
		) AS [Buffer Pool Rank]
	,[Database Name]
	,CAST(CachedSize / SUM(CachedSize) OVER () * 100.0 AS DECIMAL(5, 2)) AS [Buffer Pool Percent]
	,[Page Count]
	,CachedSize AS [Cached Size (MB)]
	,[Avg Read Time (microseconds)]
	,'Tells you how much memory (in the buffer pool) is being used by each database on the instance' AS Info
FROM AggregateBufferPoolUsage
ORDER BY [Buffer Pool Rank]
OPTION (RECOMPILE);
	------
	-- Tells you how much memory (in the buffer pool) 
	-- is being used by each database on the instance
