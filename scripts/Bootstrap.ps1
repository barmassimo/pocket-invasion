param([switch]$Download)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$version = '4.7.2-stable'
$archive = Join-Path $root "artifacts/Godot_v${version}_win64.exe.zip"
$url = "https://github.com/godotengine/godot-builds/releases/download/$version/Godot_v${version}_win64.exe.zip"
# Official GitHub release asset digest, verified 2026-11-12.
$expected = '731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953'
$engineDir = Join-Path $root 'tools/godot'
$engine = Join-Path $engineDir "Godot_v${version}_win64.exe"
$engineHash = 'ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424'
$console = Join-Path $engineDir "Godot_v${version}_win64_console.exe"
$consoleHash = 'c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643'
if (Test-Path -LiteralPath $engine) {
    if ((Get-FileHash -LiteralPath $engine -Algorithm SHA256).Hash -ne $engineHash) { throw 'Existing engine differs from the verified binary. Nothing was replaced.' }
    if (!(Test-Path -LiteralPath $console) -or (Get-FileHash -LiteralPath $console -Algorithm SHA256).Hash -ne $consoleHash) { throw 'Console launcher is missing or differs from the verified binary. Nothing was replaced.' }
    if (!(Test-Path (Join-Path $engineDir '_sc_'))) { throw 'Existing environment is missing _sc_.' }
    Write-Host 'Verified local Godot 4.7.2; reusing environment.'
    exit 0
}
if (!(Test-Path -LiteralPath $archive)) {
    if (!$Download) { throw "Place the official ZIP at $archive or use -Download explicitly." }
    New-Item -ItemType Directory -Force (Split-Path $archive -Parent) | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) { throw 'Archive SHA-256 mismatch. Nothing extracted or executed.' }
if ((Test-Path $engineDir) -and (Get-ChildItem -Force $engineDir | Select-Object -First 1)) { throw 'Engine directory is not empty. Nothing replaced.' }
New-Item -ItemType Directory -Force $engineDir | Out-Null
Expand-Archive -LiteralPath $archive -DestinationPath $engineDir
if ((Get-FileHash -LiteralPath $engine -Algorithm SHA256).Hash -ne $engineHash -or (Get-FileHash -LiteralPath $console -Algorithm SHA256).Hash -ne $consoleHash) { throw 'Extracted binary SHA-256 mismatch. Nothing executed.' }
New-Item -ItemType File (Join-Path $engineDir '_sc_') | Out-Null
Write-Host 'Verified and prepared Godot 4.7.2 in self-contained mode.'
