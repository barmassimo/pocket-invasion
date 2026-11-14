param([Parameter(Mandatory = $true)][string]$Tag, [switch]$Package)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if ($Tag -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
    throw 'Expected a stable release tag vMAJOR.MINOR.PATCH, without leading zeros.'
}
$project = Get-Content -LiteralPath (Join-Path $root 'game/project.godot') -Raw
if ($project -notmatch '(?m)^config/version="([^"]+)"' -or "v$($Matches[1])" -cne $Tag) {
    throw 'The tag must match application/config/version in game/project.godot. Prepare the version and changelog before tagging.'
}
$commit = & git -C $root rev-parse --verify HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot read HEAD.' }
$tagCommit = & git -C $root rev-parse --verify "refs/tags/${Tag}^{commit}"
if ($LASTEXITCODE -ne 0 -or $tagCommit -cne $commit) { throw 'HEAD must be the existing release tag commit.' }
$state = & git -C $root status --porcelain --untracked-files=normal
if ($LASTEXITCODE -ne 0 -or $state) { throw 'Release builds require a clean working tree.' }
if (!$Package) { return }
$destination = Join-Path $root 'artifacts/release'
if (Test-Path -LiteralPath $destination) { throw 'Release package directory already exists. Use a fresh checkout to avoid stale assets.' }
New-Item -ItemType Directory -Path $destination | Out-Null
foreach ($platform in @('web', 'windows')) {
    $outputDir = Join-Path $root "artifacts/$platform"
    $required = @('LICENSE.txt', 'GODOT_LICENSE.txt', 'THIRD_PARTY_NOTICES.txt', 'DISTRIBUTION.txt', 'build-info.json')
    $required += if ($platform -eq 'web') { @('index.html', 'index.js', 'index.wasm', 'index.pck', 'licenses.html', 'web.config') } else { @('PocketInvasion.exe', 'PocketInvasion.pck') }
    foreach ($name in $required) {
        $file = Get-Item -LiteralPath (Join-Path $outputDir $name)
        if ($file.PSIsContainer -or $file.Length -eq 0) { throw "Missing or empty $platform output: $name" }
    }
    if ((Get-FileHash -LiteralPath (Join-Path $outputDir 'LICENSE.txt')).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root 'LICENSE')).Hash) {
        throw "$platform GPL copy differs from the source license."
    }
    $identity = Get-Content -LiteralPath (Join-Path $outputDir 'build-info.json') -Raw | ConvertFrom-Json
    if ($identity.version -cne $Tag.Substring(1) -or $identity.commit -cne $commit -or $identity.modified -isnot [bool] -or $identity.modified) {
        throw "$platform build identity does not match the clean release commit."
    }
    if ($platform -eq 'web' -and !(Get-Content -LiteralPath (Join-Path $outputDir 'index.html') -Raw).Contains('id="distribution-licenses"')) {
        throw 'Web license link is missing.'
    }
    $archive = Join-Path $destination "PocketInvasion-$Tag-$platform.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($outputDir, $archive)
}
$lines = Get-ChildItem -LiteralPath $destination -Filter '*.zip' | Sort-Object Name | ForEach-Object {
    "{0}  {1}" -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $_.Name
}
$lines | Set-Content -LiteralPath (Join-Path $destination 'SHA256SUMS.txt') -Encoding ascii
Write-Host "Verified and packaged $Tag at $commit."
