# OpenClaw + NemoClaw Local Bootstrap (Windows/WSL)

Dieses Repo automatisiert den lokalen Betrieb von OpenClaw/NemoClaw auf Windows + WSL2.

Der Setup-Flow übernimmt:

- Dependency-Checks (Docker, WSL, OpenShell, NemoClaw, Ollama)
- geführte Installation mit Bestätigung
- Onboarding für Cloud oder lokale Inferenz
- Verifikation des Endzustands

## Architektur (kurz)

- **Windows Host**: Docker Desktop, Ollama, Persistenz (z. B. auf `F:`)
- **WSL2 (Ubuntu)**: NemoClaw/OpenShell CLI, Onboarding und Steuerung
- **OpenShell Gateway**: lokale Orchestrierung, Sandbox-Lifecycle
- **Sandbox (`my-assistant`)**: isolierte Laufumgebung für OpenClaw Agent
- **Inference Route**: Provider/Model-Routing (z. B. `ollama-local` + `qwen2.5:0.5b`)

## Schnellstart

### Variante A (CMD)

```bat
launch-setup.cmd
```

### Variante B (PowerShell)

```powershell
.\bootstrap\setup.ps1
```

## Setup-Optionen

```powershell
# lokaler Modus (ohne Cloud-Key)
.\bootstrap\setup.ps1 -InferenceMode local-ollama

# Cloud-Modus
.\bootstrap\setup.ps1 -InferenceMode cloud

# ohne Nachfragen
.\bootstrap\setup.ps1 -InferenceMode local-ollama -AutoApprove

# nur Abhängigkeiten, kein Onboarding
.\bootstrap\setup.ps1 -SkipOnboard

# Install-Ziellaufwerk explizit setzen (Standard ist F)
.\bootstrap\setup.ps1 -InstallDrive F
```

## Betrieb nach erfolgreichem Onboarding

```powershell
# Status (Gateway + Sandbox)
wsl -d Ubuntu bash -lc "openshell status; echo '---'; nemoclaw list"

# Detailstatus der Default-Sandbox
wsl -d Ubuntu bash -lc "nemoclaw my-assistant status"

# Mit der Sandbox verbinden
wsl -d Ubuntu bash -lc "nemoclaw my-assistant connect"
```

## Verifikation der aktiven Engine

```powershell
# Aktive Inferenz-Route im Gateway
wsl -d Ubuntu bash -lc "openshell inference get"

# Erwartung im lokalen Betrieb:
# Provider: ollama-local
# Model:    qwen2.5:0.5b (oder dein gewähltes Modell)
```

## Speicherlayout (aktuelles Ziel: F:)

Dieses Setup ist auf minimale Last für `C:` ausgelegt:

- Ollama Installation: `F:\Ollama`
- Ollama Modelle: `F:\Ollama\models`
- Docker WSL Disk: `F:\Docker\wsl\disk\docker_data.vhdx`
- Junction auf C: bleibt kompatibel zu Docker Desktop

## Modell wechseln (stärkeres Modell)

Empfohlener Ablauf:

1. Modell lokal ziehen
2. Inferenz-Route auf das Modell setzen
3. Smoke-Test ausführen

Beispiel:

```powershell
# 1) Modell ziehen (kann je nach Größe dauern)
& "F:\Ollama\ollama.exe" pull qwen2.5:7b

# 2) Route umstellen
wsl -d Ubuntu bash -lc "openshell inference set --no-verify --provider ollama-local --model qwen2.5:7b"

# 3) Prüfen
wsl -d Ubuntu bash -lc "openshell inference get"
```

Hinweis: Größere Modelle erhöhen RAM/CPU-Last deutlich. Bei CPU-only Betrieb zuerst mit `7b` testen, dann schrittweise erhöhen.

## Troubleshooting

Die Session mit Fehlern/Lösungen ist in [docs/SESSION_TROUBLESHOOTING.md](docs/SESSION_TROUBLESHOOTING.md) dokumentiert.

Häufige Ursachen:

- Port `8080` belegt → alten Gateway/Sandbox-Prozess bereinigen
- Onboarding stoppt bei NIM-Key → für lokalen Betrieb `ollama-local` nutzen
- WSL kann Ollama nicht erreichen → Ollama auf Host prüfen und Route validieren

## Sicherheit / Hinweise

- Cloud-Modus benötigt `NVIDIA_API_KEY`.
- Local-Ollama ist ohne Cloud-Key nutzbar; CPU-only ist möglich, aber langsamer.
- OpenShell-Gateway (`https://127.0.0.1:8080`) ist mTLS-geschützt und keine normale Browser-UI.
