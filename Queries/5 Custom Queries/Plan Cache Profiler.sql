-- Plan Cache Profiler
-- http://www.dharmendrakeshari.com/sql-compilation-can-prove-server-cpu/
DECLARE @sumOfCacheEntries FLOAT = (SELECT COUNT(*) FROM sys.dm_exec_cached_plans);

SELECT 
    objtype, 
    ROUND((CAST(COUNT(*) AS FLOAT) / @sumOfCacheEntries) * 100, 2) AS [pc_In_Cache],
    CASE 
        WHEN objtype = 'Adhoc' THEN 'This means it''s experiencing typically single used plan'
        ELSE ''
    END AS [Description]
FROM sys.dm_exec_cached_plans p 
GROUP BY objtype 
ORDER BY [pc_In_Cache] DESC;
