@echo off
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -Command "& { $p = Join-Path $env:TEMP 'StarlingBootstrap.ps1'; (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/famousdrew/starling/main/bootstrap.ps1', $p); & $p; Remove-Item $p -ErrorAction SilentlyContinue }"
