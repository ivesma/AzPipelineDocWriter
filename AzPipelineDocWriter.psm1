# Ensure strictness
Set-StrictMode -Version Latest

$modPath = Split-Path (Get-Variable -Name 'PSCommandPath' -ValueOnly -Scope Script)
$moduleName = Get-ChildItem $modPath -Filter '*.psm1' | Select-Object -First 1 | Select-Object -ExpandProperty BaseName

$psdFile = Get-ChildItem $modPath -Recurse -Filter ('{0}.pssettings' -f $moduleName) | Select-Object -First 1
$tmpDataPath = Join-Path $psdFile.DirectoryName '.temp'
if (!(Test-Path $tmpDataPath -PathType Container)) {
    New-Item -Path $tmpDataPath -ItemType Directory
}

if ($null -eq $psdFile) {
    throw ('Unable to locate {0}.pssettings in {1}' -f $moduleName, $modPath)
}
$psData = Import-PowerShellDataFile -Path $psdFile.FullName

<# Set-Variable -Scope Global -Name ('{0}_{1}' -f $psData.GlobalRootPathVarPrefix, $moduleName) -Value $modPath
Set-Variable -Scope Global -Name 'AzDoOrganisation' -Value $psData.AzDoOrganisation
Set-Variable -Name "XlMaxRows" -Value 1048576 -Option Constant, AllScope -Force
Set-Variable -Name "XlMaxCols" -Value 256 -Option Constant, AllScope -Force #>

$exFuncNames = @()

foreach ($subFolder in (Get-ChildItem $modPath -Directory)) {
    if ($psData.IncludeScripts.Keys -notcontains $subFolder.Name) {
        Write-Host ('Skip folder: {0}' -f $subFolder.Name) -ForegroundColor Magenta
        continue
    }
    Write-Host ('Processing folder: {0}' -f $subFolder.Name) -ForegroundColor Green
    $scriptFiles = Get-ChildItem $subFolder.FullName -Recurse -Filter '*.ps1'
    foreach ($scriptFile in $scriptFiles | Where-Object { !$_.BaseName.ToLower().EndsWith('.tests') -and !$_.FullName.ToLower().EndsWith('.sb.ps1') }) {
        Write-Host ('Loading script: {0}' -f $scriptFile.FullName) -ForegroundColor Cyan
        . ($scriptFile.FullName)
        if ($psData.IncludeScripts[$subFolder.Name].isPublic) {
            $exFuncNames += $scriptFile.BaseName
        }
    }
}

Export-ModuleMember -Function ($exFuncNames | Sort-Object -Unique) -Verbose

$exFuncNames

<#
foreach ($scope in @($psData.IncludeScripts.Keys)) {
    $scriptPath = (Join-Path $modPath $scope)
    if (Test-Path $scriptPath -PathType Container) {
        Write-Verbose ('Load Script files from {0}' -f $moduleName)

        $scriptFiles = Get-ChildItem $scriptPath -Recurse -Filter '*.ps1'
        foreach ($scriptFile in $scriptFiles | Where-Object { !$_.BaseName.ToLower().EndsWith('.tests') -and !$_.FullName.ToLower().EndsWith('.sb.ps1') }) {
            . ($scriptFile.FullName)
        }

        if ($psData.IncludeScripts[$scope].isPublic) {
            Export-ModuleMember -Function ($scriptFiles | Select-Object -ExpandProperty BaseName)
        }
    }
    else {
        Write-Warning ('Folder {0} not found in {1}' -f $scope, $modPath)
    }
} #>

<#  --------------------------------------------------------------
    Validate, import and cache required modules
    --------------------------------------------------------------#>
<# foreach ($modName in $psData.ReqdModules) {
    Write-Host ('Checking Module: {0}' -f $modName)
    $iMod = Get-Module -ListAvailable -Name $modName -ErrorAction SilentlyContinue | Select-Object -Property Name, Version, Repository, Description
    if ($null -eq $iMod) {
        # Write-Host ('Module {0} not found. Try to install' -f $modName)
        $iParams = @{
            'Name'         = $modName
            'Force'        = $true
            'Scope'        = 'CurrentUser'
            'AllowClobber' = $true
            'Repository'   = 'PSGallery'
        }
        Write-Host ('Installing Module: {0}' -f $iParams.Name)
        Install-Module @iParams
    }
} #>

