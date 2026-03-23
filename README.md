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

## Ollama Cloud Integration

Falls dein PC nicht genug Speicher/Rechenleistung für stärkere lokale Modelle hat:

### 1. API-Key einrichten

Registriere dich bei [Ollama Cloud](https://ollama.com/login) und generiere einen API-Key.

### 2. OpenShell Provider erstellen

```powershell
wsl -d Ubuntu bash -lc "
openshell provider create --name ollama-cloud --type openai \
  --credential 'OPENAI_API_KEY=<DEIN_API_KEY>' \
  --config 'OPENAI_BASE_URL=https://ollama.com/v1'
"
```

**Wichtig**: 
- Basis-URL ist `https://ollama.com/v1` (NICHT `api.ollama.com`)
- Modellnamen verwenden Doppelpunkt: z. B. `qwen3-coder:480b`

### 3. Inferenz-Route umstellen

```powershell
wsl -d Ubuntu bash -lc "
openshell inference set --no-verify --provider ollama-cloud --model qwen3-coder:480b
"
```

### 4. Verfügbare Cloud-Modelle

Listing (mit gültigem API-Key):

```bash
curl -s https://ollama.com/v1/models \
  -H "Authorization: Bearer <DEIN_API_KEY>" | python3 -m json.tool
```

Beliebte Modelle:
- `qwen3-coder:480b` — StarCode für Code-Aufgaben (schnell, ~500 Milliarden Parameter)
- `qwen3.5:397b` — Allzweck-Modell (stark)
- `mistral-large-3:675b` — Sehr großes Modell
- `gemini-3-flash-preview` — Google Gemini kompatibel

### 5. Test

```bash
# direkt zum Ollama Cloud API
curl https://ollama.com/v1/chat/completions \
  -H "Authorization: Bearer <DEIN_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3-coder:480b","messages":[{"role":"user","content":"2+2"}],"max_tokens":20}'
```

Erwartung: `"2 + 2 = 4"` (oder ähnliche Antwort), **keine** `unauthorized` Fehler.

---

## Troubleshooting

Die Session mit Fehlern/Lösungen ist in [docs/SESSION_TROUBLESHOOTING.md](docs/SESSION_TROUBLESHOOTING.md) dokumentiert.

Häufige Ursachen:

- Port `8080` belegt → alten Gateway/Sandbox-Prozess bereinigen
- Onboarding stoppt bei NIM-Key → für lokalen Betrieb `ollama-local` nutzen
- WSL kann Ollama nicht erreichen → Ollama auf Host prüfen und Route validieren
- Cloud-API antwortet 301 Redirect → Basis-URL prüfen (sollte `https://ollama.com/v1` sein)
- Cloud-API antwortet "model not found" → Modellnamen mit Doppelpunkt prüfen (z. B. `qwen3-coder:480b`)

## Sicherheit / Hinweise

- **Ollama Cloud API-Key**: In `openshell provider` Konten gespeichert. Nicht in Versionskontrolle committen.
- **Local-Ollama** ist ohne Cloud-Key nutzbar; CPU-only ist möglich, aber langsamer.
- **OpenShell Gateway** (`https://127.0.0.1:8080`) ist mTLS-geschützt und keine normale Browser-UI.

---

## Zusammenfassung der aktuellen Konfiguration

Nach erfolgreichem Onboarding sollte folgendes laufen:

| Komponente | Status | Details |
|-----------|--------|---------|
| Windows Ollama | läuft | Host: `http://127.0.0.1:11434` |
| Docker Desktop | läuft | v29.2.1 (WSL VHDX auf `F:\Docker`) |
| OpenShell Gateway | läuft | `https://127.0.0.1:8080`, mTLS |
| Sandbox `my-assistant` | ready | Model: `qwen3-coder:480b`, Provider: `ollama-cloud` |
| NemoClaw CLI | funktioniert | WSL: `/home/levan/nemoclaw` |

Inferenz läuft über Ollama Cloud, komplexe Aufgaben sind jetzt möglich ohne lokal Speicher zu überlasten!
