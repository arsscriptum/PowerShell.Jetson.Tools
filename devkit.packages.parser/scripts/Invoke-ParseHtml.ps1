[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [String]$Url
)




# ---------------------------------------------------------------
# Invoke-GenerateIndexFromHtml
#
# Tools to help creating my resources index page 
#
# Go to the JetPack archives https://developer.nvidia.com/embedded/jetpack-archive 
#
# After selecting a specific driver version, i.e https://developer.nvidia.com/embedded/linux-tegra-r214
# Download the html file 
# wget https://developer.nvidia.com/embedded/linux-tegra-r214
#
# 
# ---------------------------------------------------------------

$Script:EnableTestCode  = $True
$Script:CompareHtmlData = $False 



function Search-HtmlAnchors{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Text,
        [Parameter(Mandatory=$false)]
        [String]$Anchor="<a"
    )

    [System.Collections.ArrayList]$AnchorsList = [System.Collections.ArrayList]::new()
    $index = $Text.IndexOf("$Anchor")
    Write-Verbose "found first anchor at $index"
    if($index -eq -1){
        return $Null
    }
    [void]$AnchorsList.Add($index)
    While($true){
        $nextindex = $Text.IndexOf("$Anchor",  ($index + 1))

        if($nextindex -eq -1){
            break;
        }
        Write-Verbose "found next anchor at $nextindex"
        [void]$AnchorsList.Add($nextindex)
        $index = $nextindex
    }

    $AnchorsList
}


function Get-HtmlAnchorsErrors{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Text,
        [Parameter(Mandatory=$true,Position=1)]
        [System.Collections.ArrayList]$Positions
    )

    $ListIndex = 0
    $ListSize = $Positions.Count
    if($ListSize -eq 0){ throw "empty list"}
    [System.Collections.ArrayList]$TextErrors = [System.Collections.ArrayList]::new()
    while($True){
        $start = $Positions[$ListIndex]
        if(($ListIndex+1) -lt $ListSize){
            $end = $Positions[$ListIndex + 1]
        }else{
            $end = $Text.Length
        }
        
        $len = $end - $start

        [string]$Subset = $Text.SubString($start, 8)
        [string]$Valid = "<a href="
        
        if("$Subset" -ne "$Valid"){
            
            [PsCustomObject]$o = [PsCustomObject]@{
                start = $start 
                end  = $end
                len = $len
            }
            Write-Verbose "start $start ; end $end ; len $len"
            [void]$TextErrors.Add($o)
        }
        $ListIndex++

        if($ListIndex -ge $ListSize){
            break;
        }
    }
    $TextErrors
}

function Get-HtmlAnchorsPositions {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path
    )

    try{
        $HtmlData = Get-Content "$Path" -Raw
        $AnchorList = Search-HtmlAnchors -Text "$HtmlData"

        $AnchorListCount = $AnchorList.Count
        Write-Host "[TEST] " -n -f DarkYellow
        Write-Host "Search-HtmlAnchors returned $AnchorListCount itmes found" -f Gray
        $AnchorList
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}


function Initialize-HtmlData {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url
    )

    try{
        $tmppath = Join-Path "$PSScriptRoot" "tmp"
        if(-not (Test-Path -Path "$tmppath" -PathType "Container")){
            $null = New-Item "$tmppath" -ItemType directory -Force -ErrorAction Ignore
        }

        [string]$UrlBaseName = (New-Guid).Guid

        [Uri]$MyUri = $Url
        $IsUrlInvalid = (([string]::IsNullOrEmpty($($MyUri.Host))) -Or ([string]::IsNullOrEmpty($($MyUri.LocalPath))))
        if($IsUrlInvalid -eq $False){
            $UrlBaseName = $MyUri.Segments[$MyUri.Segments.Count-1]
        }

        Write-Verbose "Initialize-HtmlData"
        Write-Verbose "$Url"

        $htmldatapath = "{0}\{1}.html" -f $tmppath, $UrlBaseName
        Write-Verbose "local html file path $htmldatapath"

        if(Test-Path $htmldatapath -PathType Leaf){
            $null = Remove-Item "$htmldatapath"  -Force -ErrorAction Ignore
            Write-Verbose "deleting `"$htmldatapath`""
        }

        Write-Verbose "downloading using wget..."
        $WgetExe = (Get-Command 'wget.exe').Source 
        & "$WgetExe" "$Url" "-O" "$htmldatapath" "-o" "$ENV:TEMP\wget.log"

        #Invoke-WebRequest -Uri $Url -OutFile 

        $cnt = Get-Content $htmldatapath -Raw
        $len = $cnt.Length

        Write-Verbose "$htmldatapath $len bytes"

        $ihead = $cnt.IndexOf('</head><body')

        [int]$numchars = $len - $ihead
        Write-Verbose "cutting data $numchars chars from $ihead"
        [string]$datasection = "$cnt".SubString($ihead, $numchars).Clone()

        $inprogresspath0 = "{0}\{1}.html" -f $tmppath, "inprogress_0"
        Write-Verbose "Saving HtmlTextData in file `"$inprogresspath0`""
        Set-Content -Path "$inprogresspath0" -Value "$datasection"


        $SpecialLogString = @"

=====================================================
              New code starts here                   
=====================================================

"@
        Write-Verbose "$SpecialLogString"
        [System.Collections.ArrayList]$PositionList = [System.Collections.ArrayList]::new()
        $PositionList = Get-HtmlAnchorsPositions -Path "$inprogresspath0" 
        $PositionListCount = $PositionList.Count

        Write-Verbose "[Get-HtmlAnchorsPositions] returned a list of size $PositionListCount"

        [System.Collections.ArrayList]$HtmlErrorsList = [System.Collections.ArrayList]::new()
        [System.Collections.ArrayList]$HtmlErrorsList = Get-HtmlAnchorsErrors -Text "$datasection" -Positions $PositionList
        $HtmlErrorsListCount = $HtmlErrorsList.Count

        Write-Verbose "[Get-HtmlAnchorsErrors] returned a list of size $HtmlErrorsListCount"


        [System.Collections.ArrayList]$LogStringList = [System.Collections.ArrayList]::new()
        [string]$ListLogStr = "`n"
        $ObjId = 0
        $HtmlErrorsList | % {
            $Obj = $_ 
            $ObjId++
            $StartIdValue = $Obj.start
            $EndIdValue = $Obj.end
            $LenValue = $Obj.len

            $ListLogStr = "HtmlErrors [$ObjId]`n   - StartIdValue $StartIdValue`n   - EndIdValue $EndIdValue`n   - LenValue $LenValue"
            [void]$LogStringList.Add($ListLogStr)
        }

        $ItemsLogs = $LogStringList | Out-String
        $SpecialLogString = @"
`n=====================================================
Listing Errors Instances HtmlErrorsList                
$ItemsLogs
"@
        Write-Verbose "$SpecialLogString"

      
        Write-Verbose "Sorting HTML Errors Data Objects"

        $HtmlErrorsListSorted = $HtmlErrorsList | sort -Descending -Property start

        [System.Collections.ArrayList]$LogStringList = [System.Collections.ArrayList]::new()
        [string]$ListLogStr = "`n"
        $ObjId = 0
        $HtmlErrorsListSorted | % {
            $Obj = $_ 
            $ObjId++
            $StartIdValue = $Obj.start
            $EndIdValue = $Obj.end
            $LenValue = $Obj.len

            $ListLogStr = "HtmlErrors [$ObjId]`n   - StartIdValue $StartIdValue`n   - EndIdValue $EndIdValue`n   - LenValue $LenValue"
            [void]$LogStringList.Add($ListLogStr)
        }

        $ItemsLogs = $LogStringList | Out-String
        $SpecialLogString = @"
=====================================================
Listing Errors Instances HtmlErrorsListSorted                  
$ItemsLogs
"@
        Write-Verbose "$SpecialLogString"

        [string]$htmldata_before_filepath = "{0}\{1}.html" -f $tmppath, "DEBUG_HtmlData-Before-Remove"
        [string]$htmldata_after_filepath = "{0}\{1}.html" -f $tmppath, "DEBUG_HtmlData-After-Remove"

        [string]$HtmlTextBefore = "$datasection".Clone()
        [string]$HtmlTextAfter  = "$datasection".Clone()

        Write-Verbose "Saving HtmlTextData in variable HtmlTextBefore"

        [string]$HtmlTextBefore = "$datasection".Clone()
        [int]$HtmlTextBeforeLength = $HtmlTextBefore.Length

        [int]$ModificationNum = 
          
        [void]$LogStringList.Clear()

        [string]$ListLogStr = ""
        $HtmlErrorsListSorted | % {
            $Obj = $_ 
            $o = $_ 
            $StartIdValue = $Obj.start

            $StartPos = $o.start
            $EndPos = $o.end
            $StrLen = $o.len
            $StartPos = $StartPos - 2
            $StrLen = $StrLen - 2
            
            $ModificationNum++

            $datasection_length_before = $datasection.Length
            $datasection = "$datasection".Remove($StartPos,$StrLen).Clone()
            $datasection_length_after = $datasection.Length 

            $SpecialLogString = @"
`n-----------------------------------------------     
Modification No $ModificationNum
   - Removing $StrLen Bytes in HtmlTextData
   - HtmlTextData size is $datasection_length_before bytes before modifications.
   - Removing $StrLen bytes from HtmlData.
   - HtmlTextData size is $datasection_length_after bytes after modifications.
-----------------------------------------------
"@
            Write-Verbose "$SpecialLogString"
        }

        [string]$HtmlTextAfter = "$datasection".Clone()
        [int]$HtmlTextAfterLength = $HtmlTextAfter.Length


        Write-Verbose "Saving HtmlTextBefore in file `"$htmldata_before_filepath`""
        Set-Content -Path "$htmldata_before_filepath" -Value "$HtmlTextBefore"

        Write-Verbose "Saving HtmlTextAfter in file `"$htmldata_after_filepath`""
        Set-Content -Path "$htmldata_after_filepath" -Value "$HtmlTextAfter"

        Write-Verbose "Copying HtmlTextData in variable datasection"


        $datasection = $HtmlTextAfter.Clone()

        $datasection = $datasection.Replace("`"/embedded/","`"https://developer.nvidia.com/embedded/")
        $datasection = $datasection.Replace("embedded//","embedded/")
        $datasection = $datasection.Replace("<a target=","<a")
        $datasection = $datasection.Replace("`"_blank`"","")

        $firstdllink = $datasection.IndexOf('Quick Start Guide')
        Write-Verbose "Quick Start Guide. firstdllink $firstdllink"
        $lastdllink = $datasection.LastIndexOf('Release SHA Hashes')
        Write-Verbose "Release SHA Hashes. lastdllink $lastdllink"

        $len = $datasection.Length
        $ilinks = $datasection.LastIndexOf('<a href',$firstdllink)
        $elinks = $datasection.IndexOf('</a>',$lastdllink)
        Write-Verbose "first link index $ilinks"
        Write-Verbose "last link index $elinks"

        [int]$numchars = $elinks - $ilinks
        Write-Verbose "cutting data $numchars chars from pos[$ilinks]`nbytes before $($datasection.Length)"
        $linkssection = $datasection.SubString($ilinks, $numchars )
        Write-Verbose "bytes after $($linkssection.Length)"

        if($Script:EnableTestCode -eq $True){
            ####################### TEST BEGIN #########################
            $inprogresspath1 = "{0}\{1}.html" -f $tmppath, "inprogress_1"
            Set-Content -Path "$inprogresspath1" -Value "$linkssection"
            #Invoke-Subl "$inprogresspath1"
            
            $linkssection = $linkssection.Replace('<a href',"`n<a href")
            $linkssection = $linkssection.Replace('</a>',"</a>`n")
            $linkssection = $linkssection.Replace('</li><li>',"")
            $inprogresspath2 = "{0}\{1}.html" -f $tmppath, "inprogress_2"
            Set-Content -Path "$inprogresspath2" -Value "$linkssection"

            <#
            Start-Sleep 1

            Invoke-Subl "$inprogresspath0"
            Start-Sleep -Milliseconds 500
            Invoke-Subl "$inprogresspath1"
            Start-Sleep -Milliseconds 500
            Invoke-Subl "$inprogresspath2"
            Start-Sleep -Milliseconds 500

            if($Script:CompareHtmlData){
                $cc = "C:\Program Files\Araxis\Araxis Merge\Compare.exe"
                &"$cc" "/nowait" "/3" "$inprogresspath0" "$inprogresspath1" "$inprogresspath2" 
            }
            #>
            ####################### TEST END #########################  
        }



        Set-Content -Path "$htmldatapath" -Value "$linkssection"
        return $htmldatapath
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}


function Invoke-ParseHtmlPage {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path
    )


    [regex]$urlpattern = [regex]::new('(?<start>[/<a href=/]*)\"(?<url>[0-9a-zA-Z_\.\ /\:\"\-]*)\>*(?<name>[\-\.\ a-zA-Z0-9]*)\<*')
    try{
        $List = Get-Content "$Path"
        $LinksList = [System.Collections.ArrayList]::new()
        ForEach($line in $List){
            #Write-Verbose "proccessing line `"$line`""
            if($line -match $urlpattern){
                #Write-Verbose "regex match found!"
                $url = $Matches.url
                $name  = $Matches.name
                
                $url = $url.Trim('"')
                $url = $url.Trim()

                $o = [PsCustomObject]@{
                    Name = $name 
                    Url = $url
                }
                [void]$LinksList.Add($o)
            }
        }
        Write-Verbose "found $($LinksList.Count) objects"
        $LinksList
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}



function Invoke-GenerateIndexFromHtml {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [switch]$DebugErrors
    )

    try{

        Write-Verbose "[Invoke-GenerateIndexFromHtml] DebugErrors $DebugErrors"

        $outpath = Join-Path "$PSScriptRoot" "out"

        if(-not (Test-Path -Path "$outpath" -PathType "Container")){
            $null = New-Item "$outpath" -ItemType directory -Force -ErrorAction Ignore
        }

        $tmppath = Join-Path "$PSScriptRoot" "tmp"
        #    $null = Remove-Item "$tmppath" -Recurse -Force -ErrorAction Ignore
        if(-not (Test-Path -Path "$tmppath" -PathType "Container")){
            $null = New-Item "$tmppath" -ItemType directory -Force -ErrorAction Ignore
        }

        if($DebugErrors){
            $errorspath = Join-Path "$tmppath" "errors"
            $null = Remove-Item "$errorspath" -Recurse -Force -ErrorAction Ignore
            $null = New-Item "$errorspath" -ItemType directory -Force -ErrorAction Ignore
        }

        [Uri]$MyUri = $Url
        $Title = $MyUri.Segments[$MyUri.Segments.Count-1]
        $invalidTitle = $Title.Contains(" ")
        if($invalidTitle){ throw "title must not have spaces" }

        $Path = Initialize-HtmlData -Url $Url

        $resourcefolder = Join-Path "$outpath" "$Title"
        if((Test-Path -Path "$resourcefolder" -PathType "Container") -eq $True){
            $null = Remove-Item "$resourcefolder" -Recurse -Force -ErrorAction Ignore
        }
        $null = New-Item "$resourcefolder" -ItemType "Directory" -Force -ErrorAction Stop

        $filespath = Join-Path "$resourcefolder" "files"
        $null = New-Item "$filespath" -ItemType "Directory" -Force -ErrorAction Stop

        Write-Verbose "parsing logs from $Path"
        $ObjectsList = Invoke-ParseHtmlPage -Path "$Path"

        $indexpath = Join-Path "$resourcefolder" "README.md"
        $null = New-Item "$indexpath" -ItemType file -ErrorAction Stop
        $index = 0
        $totalitems = $ObjectsList.Count
        [int]$DataErrorCount = 0
        ForEach($obj in $ObjectsList){
         
            [string]$u = $obj.url
            [string]$n = $obj.name
            
            Write-Verbose "url $u"

            [Uri]$MyUri = $u
            
            $index++

            if($DebugErrors){
                $VariableName = "DEBUG_URL_{0:d2}" -f $index
                Write-Verbose "Set the debug variable `"$VariableName`""
                $DebugVar = New-Variable -Name "$VariableName" -Value $MyUri -Option AllScope -Visibility Public -Force -PassThru -Scope Global
            }

            [int]$SegCheck = $MyUri.Segments.Count
            Write-Verbose "SegCheck $SegCheck"
            $IsUrl_Invalid = (([string]::IsNullOrEmpty($($MyUri.Host))) -Or ([string]::IsNullOrEmpty($($MyUri.LocalPath))) -Or ($SegCheck -eq 0))
            $IsUrl_Valid = !$IsUrl_Invalid
            $filebasename = ''
            
            if($IsUrl_Valid -eq $True){
                $filebasename = $MyUri.Segments[$MyUri.Segments.Count-1]
            }else{
                $DataErrorCount++
                if(($u.LastIndexOf('/')) -ne -1){
                    $lastslashid = $u.LastIndexOf('/') + 1
                    $filebasename = $u.SubString($lastslashid)
                }
            }

            $filebasename = $filebasename.Trim()
            $fullfilename = Join-Path "$filespath" "$filebasename"
            $masterlink = "http://jetson.distrib.server/jetson/linux-tegra-r214"
            $link = "{0}/files/{1}" -f $masterlink, $filebasename

            $outlogstr = @"
detected new item [$index / $totalitems]
`tname         `"$n`"
`turl          `"$u`" 
`turl valid?   `"$IsUrl_Valid`"
`turl basename `"$filebasename`"
`tlogfile path `"$fullfilename`"
`tdownload url `"$link`"
`terrors count `"$DataErrorCount`"
"@
            Write-Output "$outlogstr" 
            
            if($DebugErrors){
                if($IsUrl_Invalid){
                    $errfile = "{0}/errors/{1:d2}-error.txt" -f $tmppath, $index
                    Set-Content "$errfile"  -Value "$outlogstr"

                    Write-Host "====================     DATA ERROR     ====================" -f DarkRed
                    Write-Host "$outlogstr" -f DarkYellow
                    Write-Host "====================     DATA ERROR     ====================" -f DarkRed
                }
            }
        }
    }catch{
        if($DebugErrors){
            Show-ExceptionDetails $_ -ShowStack
        }else{
            Write-Error "$_"
        }
    }
}


Invoke-GenerateIndexFromHtml -Url $Url -DebugErrors