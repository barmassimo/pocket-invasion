param([switch]$Editor, [long]$Seed = -1)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/Bootstrap.ps1"
$engine = & "$PSScriptRoot/Get-GodotPath.ps1" -Windowed
$arguments = @('--path', (Join-Path $root 'game'))
if ($Editor) { $arguments += '--editor' }
if ($Seed -ge 0) { $arguments += @('--', "--seed=$Seed") }
& $engine @arguments
