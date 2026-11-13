param([switch]$Editor, [long]$Seed = -1)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/Bootstrap.ps1"
$engine = Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64.exe'
$arguments = @('--path', (Join-Path $root 'game'))
if ($Editor) { $arguments += '--editor' }
if ($Seed -ge 0) { $arguments += @('--', "--seed=$Seed") }
& $engine @arguments
