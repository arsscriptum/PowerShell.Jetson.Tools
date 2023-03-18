    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [String]$Path="$PSScriptRoot\apt-errors.log"
    )

# ------------------------------------
# Loader
# ------------------------------------
function Invoke-ParseErrorLogs {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path
    )

    try{
        $List = Get-Content $Path
        $PackageList = [System.Collections.ArrayList]::new()
        ForEach($line in $List){
            if($line -match "warning"){
                $first = $line.IndexOf("'") + 1
                $last  = $line.LastIndexOf("'")
                $len = $last - $first
                $pkgname = $line.SubString($first, $len)
                [void]$PackageList.Add($pkgname)
            }
        }
        $PackageList | sort -Descending
    }catch{
        Write-Error $_
    }
}



$script = @"

#!/bin/sh

scriptinit=/home/gp/scripts/includes/function_helpers.sh

if [ -d "$scriptinit" ]; then
        echo "ERROR : could not find dependency $scriptinit"
        exit 1;
else
        . $scriptinit
        setup_log "sourcing $scriptinit"
fi


maininclude=/home/gp/scripts/includes/function_helpers.sh

if [ -d "$maininclude" ]; then
        echo "ERROR : could not find dependency $maininclude"
        exit 1;
else
        . $maininclude
        setup_log "sourcing $maininclude"
fi

setup_log "reinstall group"

startdatestr=``date``
export STARTEDDATE="`$startdatestr"
export TOTALAPPS=1807
export UPDATEDAPPS=0

"@



function Invoke-GenerateCodeFromLogs {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [String]$Path="$PSScriptRoot\apt-errors.log"
    )

     Write-Verbose "reseting output folder"
    $null = Remove-Item "$PSScriptRoot\out" -Recurse -Force -ErrorAction Ignore
    $null = New-Item "$PSScriptRoot\out" -ItemType directory -Force -ErrorAction Ignore

     Write-Verbose "parsing logs from $Path"
    $l = Invoke-ParseErrorLogs -Path $Path
    $num = 0

     Write-Verbose "creating command list"
    ForEach($t in $l){
        $num++
        $cmd = "invoke_reinstall `"$t`""
        Add-Content -Path "$PSScriptRoot\out\commands.txt" -Value $cmd
    }

     Write-Verbose "$num commands from parsed logs"

    Write-Verbose "reseting output folder"
    $null = New-Item "$PSScriptRoot\out\reinstall_group.sh" -ItemType file -Force -ErrorAction Ignore
    $allcmds = Get-Content "$PSScriptRoot\out\commands.txt"

    Write-Verbose "create reinstall full script $PSScriptRoot\out\reinstall_group.sh"
    Add-Content -Path "$PSScriptRoot\out\reinstall_group.sh" -Value $script
    Add-Content -Path "$PSScriptRoot\out\reinstall_group.sh" -Value $allcmds
}


Invoke-GenerateCodeFromLogs $Path

Write-Host "Update the JETSON reinstall_group.sh?" -f DarkRed
$a = Read-Host "(y/N)?"

if($a -eq 'y'){
    $spath = "C:\Users\gp\jetson\scripts\reinstall_group.sh"

    if(test-path $spath){
        remove-item -path $spath -force -ea ignore | out-null
        copy-item "$PSScriptRoot\out\reinstall_group.sh" $spath -Force -Verbose
    }

    Push-Location "C:\Users\gp\jetson\scripts"
    git status
}