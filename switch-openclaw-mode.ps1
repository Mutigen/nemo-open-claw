param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("local", "cloud")]
  [string]$Mode,

  [string]$CloudApiKey
)

$ConfigPath = "C:\Users\levan\.openclaw\openclaw.json"

if (-not (Test-Path $ConfigPath)) {
  Write-Error "Config nicht gefunden: $ConfigPath"
  exit 1
}

$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

if ($Mode -eq "local") {
  $config.agents.defaults.model.primary = "ollama-local/qwen2.5:7b"
  $config.meta.lastTouchedAt = [DateTime]::UtcNow.ToString("o")
  $config | ConvertTo-Json -Depth 20 | Set-Content -Path $ConfigPath -Encoding UTF8
  Write-Host "OpenClaw-Modus aktiv: LOCAL (ollama-local/qwen2.5:7b)"
  exit 0
}

if ($Mode -eq "cloud") {
  if ([string]::IsNullOrWhiteSpace($CloudApiKey)) {
    $CloudApiKey = $env:OLLAMA_API_KEY
  }

  if ([string]::IsNullOrWhiteSpace($CloudApiKey)) {
    Write-Error "Kein Ollama Cloud API Key übergeben. Nutze -CloudApiKey oder setze OLLAMA_API_KEY."
    exit 1
  }

  $config.models.providers."ollama-cloud".apiKey = $CloudApiKey
  $config.agents.defaults.model.primary = "ollama-cloud/qwen3-coder:480b"
  $config.meta.lastTouchedAt = [DateTime]::UtcNow.ToString("o")
  $config | ConvertTo-Json -Depth 20 | Set-Content -Path $ConfigPath -Encoding UTF8
  Write-Host "OpenClaw-Modus aktiv: CLOUD (ollama-cloud/qwen3-coder:480b)"
  exit 0
}
