param([switch]$Windowed)
$root = Split-Path $PSScriptRoot -Parent
if ($IsLinux) {
    Join-Path $root 'tools/godot/Godot_v4.7.2-stable_linux.x86_64'
} elseif ($env:OS -eq 'Windows_NT') {
    $suffix = if ($Windowed) { '' } else { '_console' }
    Join-Path $root "tools/godot/Godot_v4.7.2-stable_win64${suffix}.exe"
} else {
    throw 'Only Windows x64 and Linux x64 are supported.'
}
