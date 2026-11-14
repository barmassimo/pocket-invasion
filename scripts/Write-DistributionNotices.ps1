param(
    [Parameter(Mandatory = $true)][string]$OutputDir,
    [Parameter(Mandatory = $true)][ValidateSet('Windows', 'Web')][string]$Platform
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$dataPath = Join-Path $root 'artifacts/distribution-license-data.json'
$logPath = Join-Path $root 'artifacts/distribution-licenses.log'
& $engine --headless --path (Join-Path $root 'game') --script res://scripts/write_license_data.gd --log-file $logPath -- $dataPath
if ($LASTEXITCODE -ne 0) { throw 'Godot license data generation failed.' }
if (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Godot reported license data errors.' }
$data = Get-Content -LiteralPath $dataPath -Raw | ConvertFrom-Json
if (!$data.engine_license -or !$data.copyrights -or !$data.licenses) { throw 'Engine license data is incomplete.' }
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $OutputDir 'LICENSE.txt') -Force
[IO.File]::WriteAllText((Join-Path $OutputDir 'GODOT_LICENSE.txt'), $data.engine_license + "`n", $utf8)
$notices = [Text.StringBuilder]::new()
[void]$notices.AppendLine("Third-party notices supplied by Godot $($data.engine_version)")
[void]$notices.AppendLine('Generated from the pinned engine copyright and license tables. These tables can also list components unused by this export.')
foreach ($component in $data.copyrights) {
    [void]$notices.AppendLine("`n=== $($component.name) ===")
    foreach ($part in $component.parts) {
        [void]$notices.AppendLine('Files: ' + ($part.files -join ', '))
        foreach ($copyright in $part.copyright) { [void]$notices.AppendLine($copyright) }
        [void]$notices.AppendLine('License: ' + $part.license)
    }
}
foreach ($license in ($data.licenses.PSObject.Properties | Sort-Object Name)) {
    [void]$notices.AppendLine("`n=== License text: $($license.Name) ===")
    [void]$notices.AppendLine([string]$license.Value)
}
[IO.File]::WriteAllText((Join-Path $OutputDir 'THIRD_PARTY_NOTICES.txt'), $notices.ToString(), $utf8)
$identityPath = Join-Path $root 'game/build_info.json'
Copy-Item -LiteralPath $identityPath -Destination (Join-Path $OutputDir 'build-info.json') -Force
$identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
$project = Get-Content -LiteralPath (Join-Path $root 'game/project.godot') -Raw
if ($project -notmatch '(?m)^config/version="([^"]+)"') { throw 'Application version is missing.' }
$appVersion = $Matches[1]
$commit = if ($identity.commit) { [string]$identity.commit } else { 'unavailable' }
$distributionNotice = @"
Pocket Invasion - $appVersion ($Platform)
Copyright (C) 2026 Massimo Barbieri.

The source code, documentation and original game assets are licensed under
GNU GPL version 3 or (at your option) any later version (GPL-3.0-or-later).
This program comes WITHOUT ANY WARRANTY. You may redistribute and modify it
under the terms of the GNU GPL. See LICENSE.txt for the complete terms.

Godot Engine is distributed under the MIT license: see GODOT_LICENSE.txt.
Its third-party components retain their licenses: see THIRD_PARTY_NOTICES.txt.

Source commit: $commit
Build identity: see build-info.json.
Corresponding source: consult the source download accompanying this build's
release. GitHub Releases provide Source code (zip) and Source code (tar.gz)
archives for the release tag. These include the project assets and build scripts.
The engine and templates are standard unmodified Godot builds; project bootstrap
and export scripts record their official download URLs, versions and hashes.

When redistributing this package, preserve these notices and provide access to
the corresponding source as required by the GPL. For Web hosting, publish all
companion license files and licenses.html alongside the game.
"@
[IO.File]::WriteAllText((Join-Path $OutputDir 'DISTRIBUTION.txt'), $distributionNotice + "`n", $utf8)
if ($Platform -eq 'Web') {
    $body = [Net.WebUtility]::HtmlEncode($distributionNotice)
    $page = @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pocket Invasion - Licenses</title>
<style>body{margin:2rem auto;padding:0 1rem;max-width:60rem;background:#bdc79f;color:#253820;font:16px/1.5 monospace}pre{white-space:pre-wrap}a{color:inherit}</style></head>
<body><h1>Pocket Invasion - Licenses</h1>
<ul><li><a href="LICENSE.txt">GNU GPL version 3</a></li>
<li><a href="GODOT_LICENSE.txt">Godot Engine license</a></li>
<li><a href="THIRD_PARTY_NOTICES.txt">Third-party notices and license texts</a></li>
<li><a href="build-info.json">Build identity</a></li></ul>
<pre>$body</pre><p><a href="index.html">Back to the game</a></p></body></html>
"@
    [IO.File]::WriteAllText((Join-Path $OutputDir 'licenses.html'), $page + "`n", $utf8)
    $indexPath = Join-Path $OutputDir 'index.html'
    $html = [IO.File]::ReadAllText($indexPath)
    if (!$html.Contains('id="distribution-licenses"')) {
        if (!$html.Contains('</body>')) { throw 'Web export HTML body was not found.' }
        $link = '<a id="distribution-licenses" href="licenses.html" target="_blank" rel="noopener" style="position:fixed;right:8px;bottom:4px;z-index:2;padding:2px 4px;background:#bdc79f;color:#253820;font:11px monospace">Licenses</a>'
        [IO.File]::WriteAllText($indexPath, $html.Replace('</body>', $link + "`n</body>"), $utf8)
    }
}
foreach ($name in @('LICENSE.txt', 'GODOT_LICENSE.txt', 'THIRD_PARTY_NOTICES.txt', 'DISTRIBUTION.txt', 'build-info.json')) {
    if ((Get-Item -LiteralPath (Join-Path $OutputDir $name)).Length -eq 0) { throw "Empty distribution notice: $name" }
}
Write-Host "$Platform licensing notices written to $OutputDir"
