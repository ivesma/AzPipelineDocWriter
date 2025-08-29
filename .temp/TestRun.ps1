Import-Module (Join-Path $PSScriptRoot '../AzPipelineDocWriter.psd1' -Resolve) -Force -Verbose
Import-Module PSDocs

$cmds = Get-Command -Module PSDocs,AzPipelineDocWriter
$cmds