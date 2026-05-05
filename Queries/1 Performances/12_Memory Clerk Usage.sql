-- Adapted from Glenn Berry's Azure SQL Database Diagnostic Information Queries
-- Copyright (C) Glenn Berry. Non-commercial use only. Credit must be given.
-- https://glennsqlperformance.com/resources/

-- Memory Clerk Usage for instance  (Query 12) (Memory Clerk Usage)
-- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)
SELECT TOP (10) 
    mc.[type] AS [Memory Clerk Type],
    CAST((SUM(mc.pages_kb) / 1024.0) AS DECIMAL(15, 2)) AS [Memory Usage (MB)],
    CASE 
        WHEN mc.[type] = 'MEMORYCLERK_SQLBUFFERPOOL' THEN 'was new for SQL Server 2012. It should be your highest consumer of memory'
		WHEN mc.[type] = 'CACHESTORE_SQLCP' THEN 'SQL Plans: These are cached SQL statements or batches that aren''t in stored procedures, functions and triggers. Watch out for high values for CACHESTORE_SQLCP, Enabling ''optimize for ad hoc workloads'' at the instance level can help reduce this'
		WHEN mc.[type] = 'CACHESTORE_OBJCP' THEN ' Object Plans: These are compiled plans for stored procedures, functions and triggers'
        ELSE 'https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-memory-clerks-transact-sql?view=sql-server-ver16#types'
    END AS Info
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
GROUP BY mc.[type]
ORDER BY SUM(mc.pages_kb) DESC
OPTION (RECOMPILE);
------

-- MEMORYCLERK_SQLBUFFERPOOL was new for SQL Server 2012. It should be your highest consumer of memory

-- CACHESTORE_SQLCP  SQL Plans         
-- These are cached SQL statements or batches that aren't in stored procedures, functions and triggers
-- Watch out for high values for CACHESTORE_SQLCP
-- Enabling 'optimize for ad hoc workloads' at the instance level can help reduce this


-- CACHESTORE_OBJCP  Object Plans      
-- These are compiled plans for stored procedures, functions and triggers