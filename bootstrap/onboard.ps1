param(
  [ValidateSet('local-ollama', 'cloud')]
  [string]$InferenceMode = 'local-ollama',
  [string]$SandboxName = 'my-assistant',
  [string]$InstallDrive = 'F',
  [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
  Write-Host ''
  Write-Host "==> $Message" -ForegroundColor Yellow
}

function Confirm-Action([string]$Message) {
  if ($AutoApprove) { return $true }
  $answer = Read-Host "$Message [y/N]"
  return $answer -match '^(y|yes)$'
}

function Invoke-WSL([string]$Cmd) {
  & wsl -d Ubuntu bash -lc $Cmd
}

Write-Host 'NemoClaw Onboard Runner' -ForegroundColor Green
Write-Host "Mode: $InferenceMode"
Write-Host "Sandbox: $SandboxName"

Write-Step 'Gateway stabilisieren'
Invoke-WSL 'openshell gateway start --name nemoclaw --recreate'
Invoke-WSL 'openshell status'

Write-Step 'Onboarding-Umgebung vorbereiten'

if ($InferenceMode -eq 'local-ollama') {
  # Ollama-Modelle auf F: umleiten
  $existingModels = [Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
  if (-not [string]::IsNullOrWhiteSpace($existingModels) -and $existingModels -notlike 'C:\*') {
    $env:OLLAMA_MODELS = $existingModels
  } else {
    $env:OLLAMA_MODELS = "${InstallDrive}:\OllamaModels"
  }

  $ollamaReady = $false
  try {
    $null = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing
    $ollamaReady = $true
  } catch {
    $ollamaApp = @(
      "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama app.exe",
      "${InstallDrive}:\Ollama\ollama app.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($ollamaApp) {
      Write-Host '  Starte Ollama App...'
      Start-Process $ollamaApp
      Start-Sleep -Seconds 4
      try {
        $null = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing
        $ollamaReady = $true
      } catch {}
    }
  }

  if (-not $ollamaReady) {
    throw 'Ollama API auf http://127.0.0.1:11434 nicht erreichbar.'
  }

  Write-Host '  OK: Ollama Host-API erreichbar'

  $cmd = "NEMOCLAW_NON_INTERACTIVE=1 NEMOCLAW_PROVIDER=ollama NEMOCLAW_MODEL=qwen2.5:0.5b NEMOCLAW_SANDBOX_NAME='$SandboxName' NEMOCLAW_RECREATE_SANDBOX=1 NEMOCLAW_POLICY_MODE=suggested nemoclaw onboard --non-interactive"
  Write-Step 'NemoClaw Onboarding (local-ollama)'
  Invoke-WSL $cmd
}
else {
  $apiKey = $env:NVIDIA_API_KEY
  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    if (-not (Confirm-Action 'NVIDIA_API_KEY ist nicht gesetzt. Jetzt eingeben?')) {
      throw 'Cloud-Modus ohne NVIDIA_API_KEY nicht möglich.'
    }
    $apiKey = Read-Host 'NVIDIA API Key (nvapi-...)'
  }

  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'Leerer API Key.'
  }

  $cmd = "export NVIDIA_API_KEY='$apiKey'; NEMOCLAW_NON_INTERACTIVE=1 NEMOCLAW_PROVIDER=cloud NEMOCLAW_SANDBOX_NAME='$SandboxName' NEMOCLAW_RECREATE_SANDBOX=1 NEMOCLAW_POLICY_MODE=suggested nemoclaw onboard --non-interactive"
  Write-Step 'NemoClaw Onboarding (cloud)'
  Invoke-WSL $cmd
}

Write-Step 'Verifikation'
Invoke-WSL 'nemoclaw status'
Invoke-WSL 'openshell status'
Invoke-WSL 'nemoclaw list'

Write-Host ''
Write-Host 'Onboarding abgeschlossen.' -ForegroundColor Green
