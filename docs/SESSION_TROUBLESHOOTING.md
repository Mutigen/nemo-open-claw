# NemoClaw Setup Session – Fehler & Lösungen (Windows + WSL)

Dieses Dokument fasst die wichtigsten Probleme aus der lokalen Einrichtung zusammen und enthält die funktionierenden Lösungen.

## Ziel

Vollständiges lokales OpenClaw + NemoClaw Setup auf Windows mit WSL2 (Ubuntu), ohne GPU.

## Architektur (funktionierender Endzustand)

- Host: Windows 10/11
- Docker: Docker Desktop (Linux Engine)
- Linux-Umgebung: WSL2 Ubuntu
- OpenShell + NemoClaw: in Ubuntu installiert und ausgeführt
- Lokale Inferenz ohne Cloud: Ollama auf Host, erreichbar über `host.docker.internal`

---

## Fehlerbild 1: `&&` in PowerShell schlägt fehl

### Symptom

`&&` wird als ungültiges Trennzeichen gemeldet.

### Ursache

PowerShell 5.1 unterstützt `&&` nicht wie Bash.

### Lösung

PowerShell-kompatibel trennen:

```powershell
git clone <repo>; cd <repo>; npm install
```

---

## Fehlerbild 2: `nemoclaw`/`openshell` nicht gefunden

### Symptom

CommandNotFound für `nemoclaw` oder `openshell`.

### Ursache

CLI wurde in anderem Kontext installiert (Windows vs. WSL), PATH nicht konsistent.

### Lösung

- OpenShell in Ubuntu installieren.
- NemoClaw in Ubuntu installieren.
- Setup-Befehle ebenfalls in Ubuntu ausführen.

---

## Fehlerbild 3: OpenShell Install-Script in PowerShell

### Symptom

`OPENSHELL_VERSION=vX sh` oder `sh`-Aufruf fehlschlägt.

### Ursache

Unix-Syntax wurde in PowerShell ausgeführt.

### Lösung

Install-Script in WSL/Ubuntu ausführen, nicht in reinem PowerShell-Kontext.

---

## Fehlerbild 4: Docker läuft, aber WSL sieht keinen Docker-Zugriff

### Symptom

In Ubuntu: Docker nicht erreichbar oder Hinweis auf fehlende WSL Integration.

### Ursache

Docker Desktop Engine/Integration war nicht stabil oder nicht korrekt aktiv.

### Lösung

- Docker Desktop starten.
- Engine-Status prüfen (`docker version`).
- Gateway bei Bedarf neu erstellen (`openshell gateway start --recreate`).

---

## Fehlerbild 5: `https://127.0.0.1:8080` im Browser „Zugriff verweigert"

### Symptom

Gateway-URL im Browser nicht nutzbar.

### Ursache

OpenShell läuft standardmäßig mit mTLS (Client-Zertifikat erforderlich).

### Lösung

Das ist erwartetes Verhalten. Zugriff über CLI/konfigurierte Clients, nicht per nacktem Browser.

---

## Fehlerbild 6: Onboarding fragt NVIDIA API Key

### Symptom

`No GPU detected — will use cloud inference` und API-Key Prompt.

### Ursache

Standardpfad ohne GPU ist NVIDIA Cloud Inference.

### Lösung

Alternative lokal ohne Cloud:

- Ollama lokal bereitstellen
- NemoClaw auf `local-ollama` non-interactive konfigurieren

---

## Fehlerbild 7: Gateway Health sporadisch „unhealthy"

### Symptom

`openshell gateway start` endet gelegentlich mit Health-Fehler.

### Ursache

Transientes Cluster-/Pod-Startup Verhalten.

### Lösung

Robuster Retry:

```bash
openshell gateway start --name nemoclaw --recreate
openshell status
```

Wenn `Connected`, dann mit Onboarding fortfahren.

---

## Empfohlener robuster Ablauf

1. Docker Desktop sicher starten, `docker version` prüfen.
2. OpenShell + NemoClaw in Ubuntu installieren.
3. Gateway stets per `--recreate` hochfahren.
4. Für No-GPU ohne Cloud: Ollama bereitstellen und `local-ollama` verwenden.
5. Nach Setup immer verifizieren:
   - `nemoclaw status`
   - `openshell status`
   - `nemoclaw list`

---

## Anmerkung

Die Skripte unter `bootstrap/` in diesem Repo kapseln diese Learnings in einen wiederholbaren, interaktiven Setup-Prozess mit Installationsfreigaben durch den Nutzer.
