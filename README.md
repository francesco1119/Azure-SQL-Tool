# Azure SQL Tool

A PowerShell-based diagnostic and analysis tool for Azure SQL databases. It authenticates to Azure, lets you pick a category of SQL queries, filters targets by subscription/server/database, executes the queries, and exports the results to Excel or CSV files.

---

## Prerequisites

- **PowerShell** with the following modules: `Az`, `SqlServer`, `ImportExcel`

> **Note:** The script automatically checks for these modules at startup and installs any that are missing. No manual setup required.

---

## Usage Example

```powershell
& '.\Azure SQL Tool.ps1'
```

---

## Task Selection Menu

You are presented with five categories to choose from:

| # | Category | Description |
|---|----------|-------------|
| 1 | Performances | Performance-related diagnostics (I/O, buffer, indexes, wait stats, query stats, etc.) — based on [Glenn Berry's Azure SQL Diagnostic Queries](https://glennsqlperformance.com/resources/) |
| 2 | Quick Investigation | Blocking detection, lock waits, geo-replication status, resumable index rebuilds, etc. — based on [Glenn Berry's Azure SQL Diagnostic Queries](https://glennsqlperformance.com/resources/) |
| 3 | Perfect Tuning | Evaluates whether Azure SQL databases can be downgraded to a lower service tier — based on [Microsoft DMV monitoring docs](https://learn.microsoft.com/en-us/azure/azure-sql/database/monitoring-with-dmvs?view=azuresql) |
| 4 | AUTO_SHRINK | Checks if AUTO_SHRINK is enabled on databases |
| 5 | compatibility_level | Queries related to database compatibility level analysis |
| 6 | Custom Queries | Ad hoc queries (plan cache analysis, duplicate indexes, missing indexes, etc.) |
