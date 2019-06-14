function Write-Log {
    [CmdletBinding(DefaultParameterSetName="Default")]
    param (
        [string]
        $msg = $null
    )
    $now=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss");
    Write-Output ("{0} [{1}] {2}" -f $now,$pid,$msg);
}

Export-ModuleMember -Function *
