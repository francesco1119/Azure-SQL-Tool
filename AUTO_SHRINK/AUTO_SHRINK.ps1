param(
    [Parameter()]
    [String]$subscription,
    [String]$server,
    [String]$database
)

# Connect to Azure
Connect-AzAccount

# Get Azure Access Token (we will use this to query the databases)
$access_token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
# Queries will be picked up from here
$folderPath = '.\Queries'
# Choose how to format each date ("yyyy-MM-dd") or ("yyyy-MM-dd HH:mm:ss")
$DateTime = (Get-Date).ToString("yyyy-MM-dd")
# Results directory path
$resultsPath = '.\Results'

# Ensure the results directory exists
if (-not (Test-Path -Path $resultsPath)) {
    New-Item -ItemType Directory -Path $resultsPath | Out-Null
}

# Iterate through all subscriptions
foreach ($SubscriptionName in (Get-AzSubscription | Where-Object { $_.Name -like "$subscription" })) {
    Select-AzSubscription -SubscriptionId $SubscriptionName.Id | Out-Null
    Write-Host "Let's browse into Azure Subscription: " -NoNewline
    Write-Host (Get-AzContext).Subscription.Name -ForegroundColor green

    # Iterate through all SQL servers in the subscription
    foreach ($ServerName in (Get-AzSqlServer | Where-Object { $_.ServerName -like "$server" })) {
        # Iterate through all databases on the server
        foreach ($db in (Get-AzSqlDatabase -ServerName $ServerName.ServerName -ResourceGroupName $ServerName.ResourceGroupName | Where-Object { $_.DatabaseName -like "$database" })) {
            # Skip the master database
            if ($db.DatabaseName -eq "master") {
                Continue
            }
            (Get-ChildItem $folderPath | Sort-Object {if (($i = $_.BaseName -as [int])) {$i} else {$_}} ).Foreach{
                # Run the query and output the results
                Write-Host "Running query on $($db.DatabaseName) in $($ServerName.ServerName)..."
                $csvPath = Join-Path -Path $resultsPath -ChildPath ($psitem.Name.Replace('.sql', '') + '.csv')
                Invoke-Sqlcmd -ServerInstance $ServerName.FullyQualifiedDomainName -Database $db.DatabaseName -AccessToken $access_token -InputFile $psitem.FullName | Export-Csv -Path $csvPath -Append -NoTypeInformation
                Write-Host "Executing $psitem on Server $($ServerName.FullyQualifiedDomainName) and Database $($db.DatabaseName)"
            }
        }
    }
}
