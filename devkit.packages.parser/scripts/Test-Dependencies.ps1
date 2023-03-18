
[CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Quiet
    )

$Script:Verbose = !$Quiet

#===============================================================================
# Required Dependencies Listing
#===============================================================================

$FunctionDependencies = @( 'Search-HtmlAnchors', 'Read-HtmlAnchors' )

#===============================================================================
# Dependencies Validator Script
#===============================================================================

try{
    $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
    $CurrentScriptName = $Script:MyInvocation.MyCommand.Name
    $PSScriptRootValue = 'null' ; if($PSScriptRoot) { $PSScriptRootValue = $PSScriptRoot}
    
    if($Script:Verbose){
        Write-Host "[BEGIN] " -f Blue -NoNewLine
        Write-Host "testing dependencies"
    }
    $FunctionDependencies.ForEach({
        $Function=$_
        $FunctionPtr = Get-Command "$Function" -ErrorAction Ignore
        if($FunctionPtr -eq $null){

            throw "Missing function `"$Function`". Check dependencies imports."
        }elseif($Script:Verbose){
            Write-Host "   [SUCCESS]  " -f DarkGreen -NoNewLine
            Write-Host "`"$Function`" detected"
        }
    })
}catch{
    if($Script:Verbose){
        Write-Host "   [FAILURE]  " -n -f DarkRed
        Write-Host "$_" -f DarkYellow
    }
    throw "$_"
}
