#Install-Module -Name powershell-yaml -Scope CurrentUser -Force
Import-Module (Join-Path $PSScriptRoot '../AzPipelineDocWriter.psd1' -Resolve) -Force #-Verbose

Get-Command -Module powershell-yaml