$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$engine = & "$PSScriptRoot/Get-GodotPath.ps1"
& $engine --headless --path (Join-Path $root 'game') --script res://scripts/write_build_info.gd --log-file (Join-Path $root 'artifacts/build-info.log')
if ($LASTEXITCODE -ne 0) { throw 'Build identity generation failed.' }
if (Select-String -LiteralPath (Join-Path $root 'artifacts/build-info.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Godot reported build identity errors.' }
