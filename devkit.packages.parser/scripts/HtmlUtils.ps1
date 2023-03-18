

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


function Invoke-RemoveProblematicText{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Text,
        [Parameter(Mandatory=$true,Position=1)]
        [System.Collections.ArrayList]$ErrorsList
    )
    $SortedErrorList = $ErrorList | sort -Descending -Property start

    $UpdatedText = $Text
    ForEach($o in $ErrorsList){
        $StartPos = $o.start
        $EndPos = $o.end
        $StrLen = $o.len

        $UpdatedText = $Text.Remove($StartPos-2,$StrLen-2)
    }

    $UpdatedText

}

function Invoke-ApplyTextCorrections{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Text,
        [Parameter(Mandatory=$true,Position=1)]
        [System.Collections.ArrayList]$ErrorsList
    )
    <# ====================
     WORK IN  PROGRESS
     ======================
     #>
    $UpdatedText = $Text
    ForEach($o in $ErrorsList){
        $StartPos = $o.start
        $EndPos = $o.end
        $StrLen = $o.len

        $NextIndex = $Text.IndexOf("href=`"`"", $StartPos)
        if($NextIndex -lt $EndPos){
            $RemoveStartPos = $StartPos + 2
            $RemoveEndPos = $NextIndex 
            $LenToRemove = $RemoveEndPos - $RemoveStartPos

            Write-Verbose "Ready to remove invalid string.`nRemoveStartPos $RemoveStartPos ; RemoveEndPos $RemoveEndPos ; LenToRemove $LenToRemove"

            $SuStringBefore = $Text.SubString($StartPos, 20)

            $UpdatedText = $Text.Remove($RemoveStartPos, $LenToRemove)

            $SuStringAfter = $UpdatedText.SubString($StartPos, 20)

            Write-Verbose "SuStringBefore $SuStringBefore"
            Write-Verbose "SuStringAfter  $SuStringAfter"
        }
    }

    $UpdatedText
}