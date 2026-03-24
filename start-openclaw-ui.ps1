$serverScript = 'C:\Users\levan\.openclaw\canvas\server.js'
$serverDir  = 'C:\Users\levan\.openclaw\canvas'
$uiUrl      = 'http://127.0.0.1:8081/'

$conn = Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($conn) {
  Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500
}

Start-Process -FilePath 'node' -ArgumentList $serverScript -WorkingDirectory $serverDir -WindowStyle Minimized

Start-Sleep -Milliseconds 1500
Start-Process $uiUrl
