$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/Bootstrap.ps1"
$engine = Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
New-Item -ItemType Directory -Force (Join-Path $root 'artifacts') | Out-Null
& $engine --headless --path "$root/game" --editor --import --quit --log-file "$root/artifacts/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $engine --headless --path "$root/game" --script res://scripts/checks.gd --log-file "$root/artifacts/checks.log"
if ($LASTEXITCODE -ne 0) { throw 'Gameplay checks failed.' }
if (Select-String -Path "$root/artifacts/import.log", "$root/artifacts/checks.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Godot reported errors. See artifacts logs.' }
