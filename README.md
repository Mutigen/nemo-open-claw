# OpenClaw + NemoClaw Local Bootstrap (Windows/WSL)

Dieses Repo enthält einen interaktiven Setup-Flow, der den kompletten lokalen Startprozess automatisiert:

- Prüft fehlende Abhängigkeiten
- Fragt vor Installationen nach Zustimmung
- Installiert/prüft Docker, WSL, OpenShell, NemoClaw
- Führt Onboarding für Cloud oder Local-Ollama aus
- Verifiziert den Endzustand

## Schnellstart

## Variante A (CMD)

```bat
launch-setup.cmd
```

## Variante B (PowerShell)

```powershell
.\bootstrap\setup.ps1
```

## Nützliche Optionen

```powershell
# lokaler Modus (ohne Cloud-Key)
.\bootstrap\setup.ps1 -InferenceMode local-ollama

# Cloud-Modus
.\bootstrap\setup.ps1 -InferenceMode cloud

# ohne Nachfragen
.\bootstrap\setup.ps1 -InferenceMode local-ollama -AutoApprove

# nur Abhängigkeiten, kein Onboarding
.\bootstrap\setup.ps1 -SkipOnboard
```

## Was dokumentiert wurde

Die Session mit Fehlern/Lösungen ist in [docs/SESSION_TROUBLESHOOTING.md](docs/SESSION_TROUBLESHOOTING.md) dokumentiert.

## Hinweise

- Für Cloud-Modus wird `NVIDIA_API_KEY` benötigt.
- Für Local-Ollama wird ein lokales Modell genutzt; CPU-only ist möglich, aber langsamer.
- OpenShell-Gateway auf `https://127.0.0.1:8080` ist mTLS-geschützt und nicht als normale Browser-UI gedacht.
