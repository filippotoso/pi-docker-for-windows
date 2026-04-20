# Pi Docker Environment

Questo repository contiene gli script e il `Dockerfile` necessari per eseguire in sicurezza [pi](https://github.com/mariozechner/pi-coding-agent) all'interno di un container Docker isolato.

L'ambiente è configurato per mappare due directory chiave dal tuo sistema host all'interno del container:
1. **La directory dei sorgenti**: Il progetto su cui `pi` deve lavorare.
2. **La directory `.pi`**: La configurazione, le skill e le estensioni di `pi`.

## Prerequisiti

- [Docker](https://www.docker.com/products/docker-desktop/) installato e funzionante sul sistema.

## 1. Costruire l'immagine Docker

Prima di avviare l'ambiente, devi costruire l'immagine Docker (da eseguire solo la prima volta o quando vuoi aggiornare la versione di `pi`).

**Su Windows:**
Esegui lo script batch fornito:
```cmd
build.bat
```
Questo processo scaricherà un'immagine leggera di Node.js, installerà le dipendenze essenziali (`git`, `curl`, `jq`) e installerà l'ultima versione di `@mariozechner/pi-coding-agent` a livello globale.

## 2. Eseguire Pi

Puoi avviare l'ambiente usando lo script di avvio fornito.

```cmd
run.bat
```

## Dettagli tecnici

- **Immagine base**: `node:22-bookworm-slim`
- I sorgenti dell'host vengono montati su `/workspace` (che è la `WORKDIR` del container).
- La cartella configurazione `.pi` dell'host viene montata su `/root/.pi` all'interno del container, garantendo che le tue preferenze, le chat passate e le estensioni siano persistenti tra un'esecuzione e l'altra.
- Il container viene avviato con i flag `-it` per supportare l'interfaccia terminale interattiva (TUI) e `--rm` in modo da essere automaticamente distrutto all'uscita, mantenendo pulito il tuo sistema Docker.
