param([ValidateRange(1024, 65535)][int]$Port = 8060)
$ErrorActionPreference = 'Stop'
$root = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/web'
if (!(Test-Path -LiteralPath (Join-Path $root 'index.html'))) { throw 'Run scripts/Export-Web.ps1 first.' }
# Loopback-only static server for local testing; no runtime installation or URL ACL needed.
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$types = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript'; '.wasm' = 'application/wasm'; '.pck' = 'application/octet-stream'; '.png' = 'image/png'; '.svg' = 'image/svg+xml' }
$listener.Start()
Write-Host "Open http://127.0.0.1:$Port/ in a desktop browser. Ctrl+C stops the server."
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 5000
            $stream = $client.GetStream()
            $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
            $request = $reader.ReadLine()
            while ($null -ne ($line = $reader.ReadLine()) -and $line.Length -gt 0) { }
            $status = '404 Not Found'
            $mime = 'text/plain'
            $data = [Text.Encoding]::UTF8.GetBytes('Not found')
            $method = ''
            if ($request -match '^(GET|HEAD) (/[^ ]*) HTTP/1\.[01]$') {
                $method = $Matches[1]
                $name = ($Matches[2] -split '\?', 2)[0].TrimStart('/')
                if ($name -eq '') { $name = 'index.html' }
                if ($name -match '^[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+$') {
                    $path = Join-Path $root $name
                    if (Test-Path -LiteralPath $path -PathType Leaf) {
                        $data = [IO.File]::ReadAllBytes($path)
                        $status = '200 OK'
                        $mime = $types[[IO.Path]::GetExtension($path)]
                        if (!$mime) { $mime = 'application/octet-stream' }
                    }
                }
            }
            $header = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 $status`r`nContent-Type: $mime`r`nContent-Length: $($data.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n")
            $stream.Write($header, 0, $header.Length)
            if ($method -ne 'HEAD') { $stream.Write($data, 0, $data.Length) }
            Write-Host "$status $request"
        } catch [IO.IOException] {
            Write-Warning 'Client disconnected or request timed out.'
        } finally { $client.Dispose() }
    }
} finally { $listener.Stop() }
