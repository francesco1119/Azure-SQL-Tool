-- �Single Used Plan Count�  Vs �> Single Used Plan Count�a
-- http://www.dharmendrakeshari.com/sql-compilation-can-prove-server-cpu/
DECLARE @singleUse FLOAT
	,@multiUse FLOAT
	,@total FLOAT

SET @singleUse = (
		SELECT COUNT(*)
		FROM sys.dm_exec_cached_plans
		WHERE cacheobjtype = 'Compiled Plan'
			AND usecounts = 1
		)
SET @multiUse = (
		SELECT COUNT(*)
		FROM sys.dm_exec_cached_plans
		WHERE cacheobjtype = 'Compiled Plan'
			AND usecounts > 1
		)
SET @total = @singleUse + @multiUse

SELECT 'Single Used Plan Count' AS Matrix
	,ROUND((@singleUse / @total) * 100, 2) [percentage_distribution_of_plan_usecount]
	,'High single-use % means plan cache bloat - consider enabling Optimize for Ad Hoc Workloads' AS Info

UNION ALL

SELECT '> Single Used Plan Count'
	,ROUND((@multiUse / @total) * 100, 2)
	,'' AS Info
