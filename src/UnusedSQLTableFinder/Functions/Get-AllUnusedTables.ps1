Function Get-AllUnusedTables {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $PrimaryServerInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Database,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $ReplicaServerInstanceList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $OutputFolderPath
    )
  
    Write-Output ""
    Write-Output "Checking table usage stats on Server:[$PrimaryServerInstance]..."

    $UnusedTables = Get-UnusedTablesOnDatabase -ServerInstance $PrimaryServerInstance -Database $Database

    Write-Output ""
    Write-Output "Found $($UnusedTables.Count) unused tables on Server:[$PrimaryServerInstance] based on table usage stats"
    Write-Output ""
    Write-Output "Checking if these tables are used on replicas..."

    $TablesWithReadActivity = @()
    foreach ($ReplicaServerInstance in $ReplicaServerInstanceList) {

        Write-Output ""
        Write-Output "Checking replica server: [$ReplicaServerInstance] - Database:[$Database] for usage"

        foreach ($table in $UnusedTables) {
            $TablesWithReadActivity += Get-UsageStatsForTable -ServerInstance $ReplicaServerInstance -Database $Database -Schema $table.Schema -Table $table.Table
        }
    }

    $TablesWithoutAnyActivity = @($UnusedTables | Where-Object { $TablesWithReadActivity.SchemaTable -notcontains $_.SchemaTable })

    Write-Output ""
    Write-Output "$($TablesWithoutAnyActivity.Count) unused tables left after ignoring tables that had read activity on replicas.."

    Write-Output ""
    Write-Output "Checking if these tables are a parent in a foreign key relationship ..."

    $ParentFKTables = @()
    foreach ($table in $TablesWithoutAnyActivity) {
        $ParentFKTables += Get-IsParentFKTable -ServerInstance $PrimaryServerInstance -Database $Database -Schema $table.Schema -Table $table.Table
    }

    $FinalList = @($TablesWithoutAnyActivity | Where-Object { $ParentFKTables.SchemaTable -notcontains $_.SchemaTable })
    
    Write-Output ""
    Write-Output "$($FinalList.Count) tables left after ignoring tables that were a parent in a foreign key relationship"

    $FullOutputPath = $OutputFolderPath + "\$($Database)_UnusedTables_$(get-date -f yyyyMMdd_HH_mm).csv"
    Write-Output ""
    Write-Output "Exporting final results to path: [$FullOutputPath]"
    $FinalList | Export-Csv -Path $FullOutputPath -NoTypeInformation

    Write-Output ""
    
}
