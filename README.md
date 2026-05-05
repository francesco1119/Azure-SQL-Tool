# Azure SQL Tool

A PowerShell-based diagnostic and analysis tool for Azure SQL databases. It authenticates to Azure, lets you pick a category of SQL queries, filters targets by subscription/server/database, executes the queries, and exports the results to Excel or CSV files.

---

## Prerequisites

- **PowerShell** with the following modules:
  - `Az` (Azure PowerShell)
  - `SqlServer`
  - `ImportExcel`

> **Note:** The script automatically checks for these modules at startup and installs any that are missing. No manual setup required.

- Permissions to read Azure SQL resources in the target subscriptions
- A `Results\` folder in the same directory as the script

---

## Usage Example

```powershell
# Run from the root of the project
& '.\Azure SQL Tool.ps1'
```

```
Welcome to AzureSQLTool
What do you want to do? Choose a number
1 Performances
2 Quick Investigation
3 Perfect Tuning
4 AUTO_SHRINK
5 Custom Queries
Enter your choice (1-5): 1
Choose a Subscription (you can use wildcard *): Production*
Choose a Server (you can use wildcard *): sql-prod-*
Choose a Database (you can use wildcard *): *
```

Results will be saved to the `Results\` folder.

---

## Task Selection Menu

You are presented with five categories to choose from:

| # | Category | Description |
|---|----------|-------------|
| 1 | Performances | Performance-related diagnostics (I/O, buffer, indexes, wait stats, query stats, etc.) |
| 2 | Quick Investigation | Blocking detection, lock waits, geo-replication status, resumable index rebuilds, etc. |
| 3 | Perfect Tuning | Evaluates whether Azure SQL databases can be downgraded to a lower service tier |
| 4 | AUTO_SHRINK | Checks if AUTO_SHRINK is enabled on databases |
| 5 | compatibility_level | Queries related to database compatibility level analysis |
| 6 | Custom Queries | Ad hoc queries (plan cache analysis, duplicate indexes, missing indexes, etc.) |
