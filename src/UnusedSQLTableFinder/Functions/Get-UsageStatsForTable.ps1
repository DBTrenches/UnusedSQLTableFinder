Function Get-UsageStatsForTable {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Schema,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Table

    )
  
    $query = @"
            
    ;with TableUsage
as (select      schema_name(o.schema_id) as [Schema]
               ,object_name(i.object_id) [Table]
               ,sum(s.user_seeks) + sum(s.user_scans) + sum(s.user_lookups) as [TotalReads]
               ,sum(s.user_updates) as [TotalWrites]
               ,max(s.last_user_scan) as LastUserScan
               ,max(s.last_user_lookup) as LastUserLookup
               ,max(s.last_user_seek) as LastUserSeek
    from        sys.indexes as i with (nolock)
    join        sys.objects as o
    on          o.object_id = i.object_id

    left join   sys.dm_db_index_usage_stats as s with (nolock)
    on          i.[object_id] = s.[object_id]
    and         i.index_id = s.index_id
    and         s.database_id = db_id()
    where       objectproperty(i.[object_id], 'IsUserTable') = 1
    and         schema_name(o.schema_id) = '$Schema'
    and         object_name(i.object_id) = '$Table'
    group by    schema_name(o.schema_id)
               ,object_name(i.object_id))
select      @@SERVERNAME as ServerName
           ,concat(tu.[Schema], '.', tu.[Table]) as SchemaTable
           ,tu.[Schema]
           ,tu.[Table]
           ,tu.TotalReads
           ,tu.TotalWrites
           ,tu.LastUserScan
           ,tu.LastUserLookup
           ,tu.LastUserSeek
from        TableUsage tu
where       (
                tu.TotalReads is not null
          or    tu.TotalWrites is not null
          or    tu.LastUserScan is not null
          or    tu.LastUserLookup is not null
          or    tu.LastUserSeek is not null
            )
order by    tu.[Table] asc;
        
"@

    try {

        $UsageStats = Invoke-Sqlcmd -ServerInstance $ServerInstance -query $query -QueryTimeout 60 -Database $Database -ErrorAction Stop

        return $UsageStats
        
    }
    
    catch {
        Write-Error "Failed to retrieve table stats from Server: $ServerInstance for [$Schema - $Table]"
        Write-Error "Error Message: $_.Exception.Message"
        exit
    }

    
    
}