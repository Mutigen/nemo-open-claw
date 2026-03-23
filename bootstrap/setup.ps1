param(
  [ValidateSet('local-ollama', 'cloud')]
  [string]$InferenceMode = 'local-ollama',
  [string]$SandboxName = 'my-assistant',
  [string]$InstallDrive = 'F',
  [switch]$AutoApprove,
  [switch]$SkipOnboard
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
  Write-Host ''
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Confirm-Action([string]$Message) {
  if ($AutoApprove) { return $true }
  $answer = Read-Host "$Message [y/N]"
  return $answer -match '^(y|yes)$'
}

function Test-Command([string]$Name) {
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-WingetPackage([string]$CheckCommand, [string]$PackageId, [string]$Label, [string]$Location = '') {
  if (Test-Command $CheckCommand) {
    Write-Host "  OK: $Label vorhanden"
    return
  }
  if (-not (Confirm-Action "  $Label fehlt. Jetzt installieren?")) {
    throw "$Label wird benötigt. Abbruch auf Nutzerwunsch."
  }
  if ($Location) {
    winget install $PackageId --accept-package-agreements --accept-source-agreements --location $Location
  } else {
    winget install $PackageId --accept-package-agreements --accept-source-agreements
  }
}

function Invoke-WSL([string]$Cmd) {
  & wsl -d Ubuntu bash -lc $Cmd
}

Write-Host 'NemoClaw Bootstrap Setup' -ForegroundColor Green
Write-Host "Mode: $InferenceMode"
Write-Host "Sandbox: $SandboxName"
Write-Host "InstallDrive: ${InstallDrive}:  (neue Programme + Ollama-Modelle)"

Write-Step 'Host-Abhängigkeiten prüfen'
if (-not (Test-Command 'winget')) {
  throw 'winget ist nicht verfügbar. Bitte App Installer aktivieren.'
}

Ensure-WingetPackage -CheckCommand 'docker' -PackageId 'Docker.DockerDesktop' -Label 'Docker Desktop'
Ensure-WingetPackage -CheckCommand 'wsl' -PackageId 'Microsoft.WSL' -Label 'WSL'
Ensure-WingetPackage -CheckCommand 'git' -PackageId 'Git.Git' -Label 'Git' -Location "${InstallDrive}:\Git"

if ($InferenceMode -eq 'local-ollama') {
  # winget-Registry ist die zuverlaessigste Quelle (unabhaengig von PATH oder Laufstatus)
  $wingetOut = (winget list --id Ollama.Ollama 2>&1) | Out-String
  $ollamaApiOk = $false
  try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing; $ollamaApiOk = $true } catch {}
  $ollamaExePaths = @(
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama app.exe",
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe",
    "${InstallDrive}:\Ollama\ollama app.exe",
    "${InstallDrive}:\Ollama\ollama.exe"
  )
  $ollamaInstalled = $ollamaApiOk -or
    ($wingetOut -match 'Ollama') -or
    (Test-Command 'ollama') -or
    ($null -ne ($ollamaExePaths | Where-Object { Test-Path $_ } | Select-Object -First 1))
  if (-not $ollamaInstalled) {
    if (-not (Confirm-Action "  Ollama fehlt. Auf ${InstallDrive}: installieren?")) {
      throw 'Ollama wird benoetigt. Abbruch auf Nutzerwunsch.'
    }
    winget install Ollama.Ollama --accept-package-agreements --accept-source-agreements --location "${InstallDrive}:\Ollama"
  } else {
    Write-Host '  OK: Ollama vorhanden'
  }
}

Write-Step 'Docker starten und prüfen'
try {
  docker version | Out-Null
} catch {
  if (Confirm-Action '  Docker Engine nicht erreichbar. Docker Desktop starten?') {
    $dockerExe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
    if (Test-Path $dockerExe) {
      Start-Process $dockerExe
      Start-Sleep -Seconds 15
    }
  }
}
docker version | Out-Null
Write-Host '  OK: Docker Engine erreichbar'

Write-Step 'WSL Ubuntu pruefen'
$prevEnc = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
$distroList = (wsl --list --quiet 2>&1) | Out-String
[Console]::OutputEncoding = $prevEnc
if ($distroList -notmatch 'Ubuntu') {
  if (-not (Confirm-Action "  Ubuntu-WSL fehlt. Mit 'wsl --install -d Ubuntu' installieren?")) {
    throw 'Ubuntu-WSL wird benoetigt.'
  }
  wsl --install -d Ubuntu | Out-Null
  throw 'Ubuntu wurde installiert. Bitte Windows neu starten und Setup erneut ausfuehren.'
}
wsl --set-default Ubuntu | Out-Null
Write-Host '  OK: Ubuntu verfuegbar'

Write-Step 'Ubuntu-Basisabhängigkeiten prüfen/installieren'
$missingTools = @()
foreach ($t in @('curl', 'git', 'python3', 'node', 'npm')) {
  $found = (Invoke-WSL "command -v $t 2>/dev/null").Trim()
  if (-not $found) { $missingTools += $t }
}
if ($missingTools.Count -gt 0) {
  Write-Host "  Fehlende Ubuntu-Tools: $($missingTools -join ', ')"
  if (-not (Confirm-Action '  apt-Pakete installieren? (benoetigt WSL sudo-Passwort)')) {
    throw 'Ubuntu-Abhaengigkeiten abgebrochen.'
  }
  Invoke-WSL 'sudo apt-get update -q'
  Invoke-WSL 'sudo apt-get install -y curl git python3 python3-pip nodejs npm'
} else {
  Write-Host '  OK: Ubuntu-Basisabhaengigkeiten vorhanden'
}

Write-Step 'OpenShell in Ubuntu prüfen/installieren'
$openShellCheck = (Invoke-WSL 'if command -v openshell >/dev/null 2>&1; then echo yes; else echo no; fi').Trim()
if ($openShellCheck -ne 'yes') {
  if (-not (Confirm-Action '  openshell fehlt. Jetzt installieren?')) {
    throw 'openshell wird benötigt.'
  }
  Invoke-WSL 'curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | OPENSHELL_VERSION=v0.0.12 sh'
}

Write-Step 'NemoClaw in Ubuntu prüfen/installieren'
$nemoclawCheck = (Invoke-WSL 'if command -v nemoclaw >/dev/null 2>&1; then echo yes; else echo no; fi').Trim()
if ($nemoclawCheck -ne 'yes') {
  if (-not (Confirm-Action '  nemoclaw fehlt. Jetzt installieren?')) {
    throw 'nemoclaw wird benötigt.'
  }
  Invoke-WSL 'npm install -g git+https://github.com/NVIDIA/NemoClaw.git'
}

if ($InferenceMode -eq 'local-ollama') {
  Write-Step 'Lokale Ollama-Inferenz vorbereiten'

  # Ollama-Modelle auf $InstallDrive: speichern - nur setzen wenn noch auf C:
  $existingModels = [Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
  if ([string]::IsNullOrWhiteSpace($existingModels) -or $existingModels -like 'C:\*') {
    $modelsPath = "${InstallDrive}:\OllamaModels"
    if (-not (Test-Path $modelsPath)) { New-Item -ItemType Directory -Path $modelsPath | Out-Null }
    [Environment]::SetEnvironmentVariable('OLLAMA_MODELS', $modelsPath, 'User')
    $env:OLLAMA_MODELS = $modelsPath
    Write-Host "  OK: OLLAMA_MODELS gesetzt auf $modelsPath"
  } else {
    $env:OLLAMA_MODELS = $existingModels
    Write-Host "  OK: Ollama-Modelle bereits auf ${InstallDrive}: -> $existingModels (unveraendert)"
  }
  Write-Host '  Hinweis: Docker-Daten (Images/Volumes) koennen in Docker Desktop manuell auf F: verschoben werden.'

  $ollamaAppPaths = @(
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama app.exe",
    "${InstallDrive}:\Ollama\ollama app.exe"
  )
  try {
    $null = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing
    Write-Host '  OK: Ollama API erreichbar'
  } catch {
    $appExe = $ollamaAppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($appExe -and (Confirm-Action '  Ollama API nicht erreichbar. Ollama App starten?')) {
      Start-Process $appExe
      Start-Sleep -Seconds 5
    }
  }

  if (Confirm-Action '  Kleines CPU-Modell qwen2.5:0.5b jetzt ziehen?') {
    $ollamaCli = @(
      "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe",
      "${InstallDrive}:\Ollama\ollama.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $ollamaCli) { $ollamaCli = 'ollama' }
    $tagsJson = (Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing).Content | ConvertFrom-Json
    if ($tagsJson.models | Where-Object { $_.name -match 'qwen2.5:0.5b' }) {
      Write-Host '  OK: Modell qwen2.5:0.5b bereits vorhanden'
    } else {
      & $ollamaCli pull qwen2.5:0.5b
    }
  }
}

if (-not $SkipOnboard) {
  Write-Step 'Onboarding ausführen'
  & "$PSScriptRoot\onboard.ps1" -InferenceMode $InferenceMode -SandboxName $SandboxName -InstallDrive $InstallDrive -AutoApprove:$AutoApprove
}

Write-Step 'Fertig'
Write-Host 'Bootstrap abgeschlossen.' -ForegroundColor Green
