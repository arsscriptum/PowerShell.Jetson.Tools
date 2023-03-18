
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Quiet
    )

$Script:Verbose = !$Quiet


#===============================================================================
# Dependencies Import Script
#===============================================================================

try{
    if($Script:Verbose){
        Write-Host "[BEGIN] " -f Blue -NoNewLine
        Write-Host "importing dependencies"
    }
    $FatalError = $False
    $RootPath = (Resolve-Path "$PsScriptRoot").Path 
    $DependenciesPath = Join-Path "$RootPath" "dependencies"
    Write-Verbose "RootPath $RootPath"
    Write-Verbose "DependenciesPath $DependenciesPath"
    $AllDeps = (Get-ChildItem "$DependenciesPath" -File -Recurse).Fullname
    $AllDepsCount = $AllDeps.Count
    if($AllDepsCount -gt 0){
        ForEach($dep in $AllDeps){
            try{
                $sname = (Get-Item "$dep").Name
                . "$dep"

                if($Script:Verbose){
                    Write-Host "   [SUCCESS]  " -f DarkGreen -NoNewLine
                    Write-Host "`"$sname`" imported without errors"
                }
            }catch{
                throw "`"$sname`" import failed.`n$_"
            }
        }
    }
}catch{
    if($Script:Verbose){
        Write-Host " [FAILURE] " -n -f DarkRed
        Write-Host "$_" -f DarkYellow
    }
    throw "$_"
}
