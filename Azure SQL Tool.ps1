# Check and install required modules
$requiredModules = @("Az", "SqlServer", "ImportExcel")
foreach ($module in $requiredModules) {
    if (-not (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)) {
        Write-Host "Module '$module' not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name $module -AllowClobber -Scope CurrentUser -Force
        Write-Host "Module '$module' installed successfully." -ForegroundColor Green
    }
}

# Wrapper around Invoke-Sqlcmd with retry logic for Serverless databases waking up
function Invoke-SqlcmdWithRetry {
    param(
        [hashtable]$Params,
        [int]$MaxRetries = 3,
        [int]$RetryWaitSeconds = 30
    )
    $serverlessErrors = @(
        "Connection Timeout Expired",
        "not currently available",
        "Please retry the connection"
    )
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            return Invoke-Sqlcmd @Params -ConnectionTimeout 120
        } catch {
            $msg = $_.Exception.Message
            $isServerless = $serverlessErrors | Where-Object { $msg -like "*$_*" }
            if ($isServerless -and $attempt -lt $MaxRetries) {
                Write-Host "  Database is waking up (Serverless). Waiting $RetryWaitSeconds seconds before retry $attempt/$($MaxRetries - 1)..." -ForegroundColor Yellow
                Start-Sleep -Seconds $RetryWaitSeconds
            } else {
                throw
            }
        }
    }
}

# Authenticate to Azure
try {
    Update-AzConfig -LoginExperienceV2 Off | Out-Null
    Connect-AzAccount | Out-Null # Prompts for interactive login but suppresses the output
} catch {
    Write-Host "Login cancelled or failed. Exiting." -ForegroundColor Red
    exit
}

Write-Host "Welcome to AzureSQLTool" -ForegroundColor Cyan

# Task selection menu
Write-Host "What do you want to do? Choose a number"
$options = @("1 Performances", "2 Quick Investigation", "3 Perfect Tuning", "4 AUTO_SHRINK", "5 compatibility_level", "6 Custom Queries")
$options | ForEach-Object { Write-Host $_ }
$choice = Read-Host "Enter your choice (1-6)"

# Validate user choice
if ($choice -match '^[1-6]$') {
    $selectedFolder = $options[$choice - 1]
    $folderPath = ".\Queries\$selectedFolder"

    # Sub-menu for AUTO_SHRINK option
    $autoShrinkAction = $null
    if ($choice -eq '4') {
        Write-Host "What do you want to do?"
        Write-Host "1 Check AUTO_SHRINK status"
        Write-Host "2 Enable AUTO_SHRINK"
        $autoShrinkChoice = Read-Host "Enter your choice (1-2)"
        if ($autoShrinkChoice -eq '1') {
            $autoShrinkAction = 'AUTO_SHRINK_Check'
        } elseif ($autoShrinkChoice -eq '2') {
            Write-Host "WARNING: This will enable AUTO_SHRINK on all matching databases." -ForegroundColor Yellow
            $confirm = Read-Host "Are you sure? (yes/no)"
            if ($confirm -ne 'yes') {
                Write-Host "Operation cancelled." -ForegroundColor Red
                exit
            }
            $autoShrinkAction = 'AUTO_SHRINK_Enable'
        } else {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit
        }
    }

    # Sub-menu for compatibility level option
    $compatAction = $null
    if ($choice -eq '5') {
        Write-Host "What do you want to do?"
        Write-Host "1 Check compatibility level"
        Write-Host "2 Update compatibility level to 160"
        $compatChoice = Read-Host "Enter your choice (1-2)"
        if ($compatChoice -eq '1') {
            $compatAction = '1_Check_Compatibility_Level'
        } elseif ($compatChoice -eq '2') {
            Write-Host "WARNING: This will update the compatibility level to 160 on all matching databases." -ForegroundColor Yellow
            $confirm = Read-Host "Are you sure? (yes/no)"
            if ($confirm -ne 'yes') {
                Write-Host "Operation cancelled." -ForegroundColor Red
                exit
            }
            $compatAction = '2_Update_Compatibility_Level_160'
        } else {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit
        }
    }

    # User inputs for subscription and server with wildcard support
    $subscriptionPattern = Read-Host "Choose a Subscription (you can use wildcard *)"
    $serverPattern = Read-Host "Choose a Server (you can use wildcard *)"

    # Database pattern input only for options other than 3
    if ($choice -ne '3') {
        $databasePattern = Read-Host "Choose a Database (you can use wildcard *)"
    }

    # Retrieve and validate Azure access token
    try {
        $access_token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
        if (-not $access_token) {
            Write-Host "Failed to retrieve access token: The token is null or empty." -ForegroundColor Red
            exit
        }
    } catch {
        Write-Host "Failed to retrieve access token: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }

    # Choose how to format each date ("yyyy-MM-dd")
    $DateTime = (Get-Date).ToString("yyyy-MM-dd")

    # Set error action preference to stop to handle errors proactively
    $ErrorActionPreference = 'Stop'

    # Select and iterate through matching subscriptions
    $matchingSubscriptions = Get-AzSubscription | Where-Object { $_.Name -like $subscriptionPattern }
    if (-not $matchingSubscriptions) {
        Write-Host "No subscriptions found matching '$subscriptionPattern'." -ForegroundColor Red
        exit
    }

    $matchingSubscriptions | ForEach-Object {
        $subscription = $_.Name
        Select-AzSubscription -SubscriptionName $subscription | Out-Null
        Write-Host "Browsing Azure Subscription: $subscription" -ForegroundColor Green

        # Iterate through matching servers
        $matchingServers = Get-AzSqlServer | Where-Object { $_.ServerName -like $serverPattern }
        if (-not $matchingServers) {
            Write-Host "  No servers found matching '$serverPattern' in subscription '$subscription'." -ForegroundColor Yellow
        }
        $matchingServers | ForEach-Object {
            $ServerName = $_
            Write-Host "Working on Server: $($ServerName.ServerName)" -ForegroundColor Cyan
            
            if ($choice -eq '3') {
                # Initialize the CSV file
                $csvPath = ".\Results\Perfect_Tuning.csv"
				if (-Not (Test-Path ".\Results")) {
					New-Item -Path ".\Results" -ItemType Directory | Out-Null
				}
				if (-Not (Test-Path $csvPath)) {
					New-Item -Path $csvPath -ItemType File | Out-Null
				}

                # Iterate through queries in the DB Tier Down folder and run on master database
                Get-ChildItem $folderPath -File | 
                    Sort-Object {[regex]::Replace($_.BaseName, '\D', '') -as [int]} | 
                    ForEach-Object {
                        Write-Host "Running query on master database in $($ServerName.ServerName)..."
                        try {
                            $results = Invoke-SqlcmdWithRetry -Params @{ ServerInstance = $ServerName.FullyQualifiedDomainName; Database = "master"; AccessToken = $access_token; InputFile = $_.FullName }
                            $results | Export-Csv -Path $csvPath -Append -NoTypeInformation
                            Write-Host "Query executed and results appended to Perfect_Tuning.csv for Server $($ServerName.FullyQualifiedDomainName)"
                        } catch {
                            Write-Host "Error executing query $($_.BaseName) on master database: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
            } else {
                # Iterate through matching databases for other options
                $matchingDatabases = Get-AzSqlDatabase -ServerName $ServerName.ServerName -ResourceGroupName $ServerName.ResourceGroupName |
                    Where-Object { $_.DatabaseName -like "$databasePattern" -and $_.DatabaseName -ne "master" }
                if (-not $matchingDatabases) {
                    Write-Host "  No databases found matching '$databasePattern' on server '$($ServerName.ServerName)'." -ForegroundColor Yellow
                }
                $matchingDatabases | ForEach-Object {
                    $db = $_
                    Write-Host "Querying $($db.DatabaseName)" -ForegroundColor DarkYellow

                    # Execute queries — for options 4 and 5 run only the selected file
                    Get-ChildItem $folderPath -File |
                        Where-Object { ($choice -ne '4' -or $_.BaseName -eq $autoShrinkAction) -and ($choice -ne '5' -or $_.BaseName -eq $compatAction) } |
                        Sort-Object {[regex]::Replace($_.BaseName, '\D', '') -as [int]} |
                        ForEach-Object {
                            $queryName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
                            $worksheetName = if ($queryName.Length -gt 31) { $queryName.Substring(0, 31) } else { $queryName }
                            $timeStamp = Get-Date -Format "HH:mm:ss"
                            Write-Host "Executing query: $queryName at $timeStamp"
                            try {
                                $taskName = $selectedFolder -replace '^\d+\s', '' # Clean up the task name for the filename
                                $result = Invoke-SqlcmdWithRetry -Params @{ ServerInstance = $ServerName.FullyQualifiedDomainName; Database = $db.DatabaseName; AccessToken = $access_token; InputFile = $_.FullName }
                                $excelPath = ".\Results\$taskName`_$($db.DatabaseName)_$DateTime.xlsx"
                                $result | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Export-Excel -Path $excelPath -WorksheetName $worksheetName -AutoSize
                            } catch {
                                $errorMessage = if ($_.Exception.Message) { $_.Exception.Message } else { "An unknown error occurred." }
                                Write-Host "Error executing query $queryName on Database $($db.DatabaseName): $errorMessage" -ForegroundColor Red
                            }
                        }
                }
            }
        }
    }
} else {
    Write-Host "Invalid choice. Please restart the script and select a valid option (1-6)." -ForegroundColor Red
}
