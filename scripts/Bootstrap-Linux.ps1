param([switch]$Download)
$ErrorActionPreference = 'Stop'
if (!$IsLinux -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') {
    throw 'This bootstrap requires Linux x64 and PowerShell 7.'
}
$root = Split-Path $PSScriptRoot -Parent
$version = '4.7.2-stable'
$name = "Godot_v${version}_linux.x86_64"
$archive = Join-Path $root "artifacts/$name.zip"
$url = "https://github.com/godotengine/godot-builds/releases/download/$version/$name.zip"
# Official GitHub release asset digest, verified 2026-11-14:
# https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable
$expected = 'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4'
$engineDir = Join-Path $root 'tools/godot'
$engine = Join-Path $engineDir $name
if (!(Test-Path -LiteralPath $archive)) {
    if (!$Download) { throw "Place the official ZIP at $archive or use -Download explicitly." }
    New-Item -ItemType Directory -Force (Split-Path $archive -Parent) | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) {
    throw 'Archive SHA-256 mismatch. Nothing extracted or executed.'
}
# Derive the binary hash from the authenticated archive, also on offline reuse.
$zip = [IO.Compression.ZipFile]::OpenRead($archive)
try {
    $entry = $zip.GetEntry($name)
    if ($null -eq $entry) { throw 'Engine missing from the verified archive.' }
    $stream = $entry.Open()
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $binaryHash = [Convert]::ToHexString($sha.ComputeHash($stream)) }
    finally { $stream.Dispose(); $sha.Dispose() }
    if (Test-Path -LiteralPath $engine) {
        if ((Get-FileHash -LiteralPath $engine -Algorithm SHA256).Hash -ne $binaryHash) {
            throw 'Existing engine differs from the verified binary. Nothing replaced.'
        }
        if (!(Test-Path -LiteralPath (Join-Path $engineDir '_sc_'))) { throw 'Existing environment is missing _sc_.' }
        Write-Host 'Verified local Linux Godot 4.7.2; reusing environment.'
        return
    }
    if ((Test-Path -LiteralPath $engineDir) -and (Get-ChildItem -LiteralPath $engineDir -Force | Select-Object -First 1)) {
        throw 'Engine directory is not empty. Nothing replaced.'
    }
    New-Item -ItemType Directory -Force $engineDir | Out-Null
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $engine, $false)
} finally { $zip.Dispose() }
if ((Get-FileHash -LiteralPath $engine -Algorithm SHA256).Hash -ne $binaryHash) {
    throw 'Extracted binary SHA-256 mismatch. Nothing executed.'
}
New-Item -ItemType File (Join-Path $engineDir '_sc_') | Out-Null
& chmod u+x $engine
if ($LASTEXITCODE -ne 0) { throw 'Cannot make Godot executable.' }
Write-Host 'Verified and prepared Linux Godot 4.7.2 in self-contained mode.'
