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
$manifest = Join-Path $templateDir 'web-sha256.json'
$files = @('web_nothreads_release.zip', 'web_nothreads_debug.zip')
if (Test-Path -LiteralPath $manifest) {
    $hashes = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    foreach ($file in $files) {
        $path = Join-Path $templateDir $file
        if (!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hashes.$file) {
            throw "Existing Web template differs from the verified installation: $file. Nothing replaced."
        }
    }
} else {
    if (!(Test-Path -LiteralPath $archive)) {
        if (!$Download) { throw 'Web templates are missing. Run Export-Web.ps1 -Download once.' }
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
$outputDir = Join-Path $root 'artifacts/web'
New-Item -ItemType Directory -Force $outputDir | Out-Null
$engine = Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path (Join-Path $root 'game') --log-file (Join-Path $root 'artifacts/web-export.log') --export-release Web (Join-Path $outputDir 'index.html')
if ($LASTEXITCODE -ne 0) { throw "Web export failed with exit code $LASTEXITCODE. See artifacts/web-export.log." }
if (Select-String -LiteralPath (Join-Path $root 'artifacts/web-export.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Godot reported export errors. See artifacts/web-export.log.' }
foreach ($file in @('index.html', 'index.js', 'index.wasm', 'index.pck')) {
    $path = Join-Path $outputDir $file
    if (!(Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -eq 0) { throw "Export output missing or empty: $file" }
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'web.config') -Destination (Join-Path $outputDir 'web.config') -Force
Write-Host "Web build exported to $outputDir"
