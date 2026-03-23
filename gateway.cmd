@echo off
rem OpenClaw Gateway (v2026.3.2)
set "TMPDIR=C:\Users\levan\AppData\Local\Temp"
set "PATH=C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\iCLS\;C:\Program Files\Intel\Intel(R) Management Engine Components\iCLS\;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\DAL;C:\Program Files\Intel\Intel(R) Management Engine Components\DAL;C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\IPT;C:\Program Files\Intel\Intel(R) Management Engine Components\IPT;c:\Users\levan\AppData\Local\Programs\cursor\resources\app\bin;C:\Program Files\nodejs\;C:\Program Files\Git\cmd;C:\Users\levan\AppData\Local\Programs\Python\Launcher\;C:\Users\levan\.console-ninja\.bin;C:\Users\levan\AppData\Local\Microsoft\WindowsApps;C:\Users\levan\AppData\Local\Programs\cursor\resources\app\bin;C:\Users\levan\AppData\Roaming\npm;C:\Users\levan\AppData\Local\Programs\Microsoft VS Code\bin;C:\Users\levan\AppData\Local\Programs\Warp\bin;;C:\Users\levan\AppData\Local\Programs\Ollama"
set "OPENCLAW_GATEWAY_PORT=18789"
set "OPENCLAW_GATEWAY_TOKEN=ollama"
set "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
set "OPENCLAW_SERVICE_MARKER=openclaw"
set "OPENCLAW_SERVICE_KIND=gateway"
set "OPENCLAW_SERVICE_VERSION=2026.3.2"
"C:\Program Files\nodejs\node.exe" C:\Users\levan\AppData\Roaming\npm\node_modules\openclaw\dist\index.js gateway --port 18789
