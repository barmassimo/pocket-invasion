param([switch]$Download)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/Bootstrap.ps1"
$version = '4.7.2-stable'
$archive = Join-Path $root "artifacts/Godot_v${version}_export_templates.tpz"
$url = "https://github.com/godotengine/godot-builds/releases/download/$version/Godot_v${version}_export_templates.tpz"
# Official release asset SHA-256, checked 2026-11-13.
$expected = 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011'
$templateDir = Join-Path $root 'tools/godot/editor_data/export_templates/4.7.2.stable'
$manifest = Join-Path $templateDir 'windows-sha256.json'
$files = @('windows_release_x86_64.exe', 'windows_release_x86_64_console.exe', 'windows_debug_x86_64.exe', 'windows_debug_x86_64_console.exe')
if (Test-Path -LiteralPath $manifest) {
    $hashes = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    foreach ($file in $files) {
        $path = Join-Path $templateDir $file
        if (!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hashes.$file) {
            throw "Existing Windows template differs from the verified installation: $file. Nothing replaced."
        }
    }
} else {
    if (!(Test-Path -LiteralPath $archive)) {
        if (!$Download) { throw 'Windows templates are missing. Run Export-Windows.ps1 -Download once.' }
        New-Item -ItemType Directory -Force (Split-Path $archive -Parent) | Out-Null
        Invoke-WebRequest -Uri $url -OutFile $archive
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) { throw 'Template archive SHA-256 mismatch. Nothing extracted.' }
    foreach ($file in $files) {
        if (Test-Path -LiteralPath (Join-Path $templateDir $file)) { throw "Unverified template already exists: $file. Nothing replaced." }
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        New-Item -ItemType Directory -Force $templateDir | Out-Null
        $hashes = @{}
        foreach ($file in $files) {
            $entry = $zip.GetEntry("templates/$file")
            if ($null -eq $entry) { throw "Missing template in official archive: $file" }
            $path = Join-Path $templateDir $file
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $path, $false)
            $hashes[$file] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        }
        $hashes | ConvertTo-Json | Set-Content -LiteralPath $manifest
    } finally { $zip.Dispose() }
}
$outputDir = Join-Path $root 'artifacts/windows'
New-Item -ItemType Directory -Force $outputDir | Out-Null
$engine = & "$PSScriptRoot/Get-GodotPath.ps1"
& "$PSScriptRoot/Write-BuildInfo.ps1"
& $engine --headless --path (Join-Path $root 'game') --log-file (Join-Path $root 'artifacts/windows-export.log') --export-release Windows (Join-Path $outputDir 'PocketInvasion.exe')
if ($LASTEXITCODE -ne 0) { throw "Windows export failed with exit code $LASTEXITCODE. See artifacts/windows-export.log." }
if (Select-String -LiteralPath (Join-Path $root 'artifacts/windows-export.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Godot reported export errors. See artifacts/windows-export.log.' }
foreach ($file in @('PocketInvasion.exe', 'PocketInvasion.pck')) {
    $path = Join-Path $outputDir $file
    if (!(Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -eq 0) { throw "Export output missing or empty: $file" }
}
& "$PSScriptRoot/Write-DistributionNotices.ps1" -OutputDir $outputDir -Platform Windows
Write-Host "Windows build exported to $outputDir"

