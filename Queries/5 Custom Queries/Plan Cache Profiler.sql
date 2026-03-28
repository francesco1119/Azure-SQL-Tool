-- Plan Cache Profiler
-- http://www.dharmendrakeshari.com/sql-compilation-can-prove-server-cpu/
DECLARE @sumOfCacheEntries FLOAT = (SELECT COUNT(*) FROM sys.dm_exec_cached_plans);

SELECT 
    objtype, 
    ROUND((CAST(COUNT(*) AS FLOAT) / @sumOfCacheEntries) * 100, 2) AS [pc_In_Cache],
    CASE 
        WHEN objtype = 'Adhoc' THEN 'This means it''s experiencing typically single used plan'
        ELSE ''
    END AS [Description],
    'High Adhoc % means plan cache bloat from single-use plans. Consider enabling Optimize for Ad Hoc Workloads at the server level.' AS Info
FROM sys.dm_exec_cached_plans p 
GROUP BY objtype 
ORDER BY [pc_In_Cache] DESC;
