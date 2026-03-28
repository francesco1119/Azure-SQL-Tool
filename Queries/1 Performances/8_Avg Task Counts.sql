-- Get Average Task Counts (run multiple times)  (Query 8) (Avg Task Counts)
-- First, create a Common Table Expression (CTE) to perform the aggregation
WITH SchedulerStats AS (
    SELECT 
        CONVERT(FLOAT, AVG(current_tasks_count)) AS AvgTaskCount,
        CONVERT(FLOAT, AVG(work_queue_count)) AS AvgWorkQueueCount,
        CONVERT(FLOAT, AVG(runnable_tasks_count)) AS AvgRunnableTaskCount,
        CONVERT(FLOAT, AVG(pending_disk_io_count)) AS AvgPendingDiskIOCount,
        GETDATE() AS SystemTime
    FROM sys.dm_os_schedulers
    WHERE scheduler_id < 255
)

-- Then use UNPIVOT on the CTE to convert columns to rows, and apply conditional logic
SELECT 
    Metric,
    Value,
    SystemTime,
    CASE 
        WHEN Metric = 'AvgTaskCount' THEN 'Avg Task Counts will be higher with lower service tiers'
        WHEN Metric = 'AvgWorkQueueCount' THEN 'Sustained values above 10 are often caused by blocking/deadlocking or other resource contention'
		WHEN Metric = 'AvgRunnableTaskCount' THEN 'Sustained values above 1 are a good sign of CPU pressure'
		WHEN Metric = 'AvgPendingDiskIOCount' THEN 'Sustained values above 1 are a sign of disk pressure'
        ELSE ''
    END AS Comment,
    'Run multiple times. Sustained values above 10 for Task/Work Queue suggest blocking or contention; above 1 for Runnable Tasks indicates CPU pressure; above 1 for Pending DiskIO indicates disk pressure' AS Info
FROM 
    (
        SELECT AvgTaskCount, AvgWorkQueueCount, AvgRunnableTaskCount, AvgPendingDiskIOCount, SystemTime
        FROM SchedulerStats
    ) p
UNPIVOT
    (Value FOR Metric IN 
        (AvgTaskCount, AvgWorkQueueCount, AvgRunnableTaskCount, AvgPendingDiskIOCount)
    ) AS unpvt
OPTION (RECOMPILE);
------

-- Sustained values above 10 suggest further investigation in that area (depending on your Service Tier)
-- Avg Task Counts will be higher with lower service tiers
-- High Avg Task Counts are often caused by blocking/deadlocking or other resource contention

-- Sustained values above 1 suggest further investigation in that area
-- High Avg Runnable Task Counts are a good sign of CPU pressure
-- High Avg Pending DiskIO Counts are a sign of disk pressure

