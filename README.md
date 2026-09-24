# Satur App — Flutter (v1 klient)

Aplikacja mobilna Satur. Zakres: `docs/PODSUMOWANIE_ZAKRESU_V1.md`.  
Backend: projekt **`../satur`** (Sylius) — **bez lokalnej bazy** w tym repo.

## Wymagania (już w home, bez sudo)

| Narzędzie | Ścieżka |
|-----------|---------|
| Flutter 3.47+ stable | `~/development/flutter` |
| Android SDK 36 | `~/Android/Sdk` |
| Chrome | systemowy (web) |
| Docker | systemowy (opcjonalny build CI) |

PATH jest dopisany w `~/.bashrc` (blok `satur-app flutter`). Nowa terminala albo:

```bash
source ~/.bashrc
```

## Quick start

```bash
make doctor          # Android + Chrome powinny być OK
make pub-get
make run-chrome      # szybki podgląd UI
make satur-api-check # wymaga: w ../satur → make up (port 5051)
```

Android (emulator / telefon):

```bash
make run-android     # API → http://10.0.2.2:5051
```

## Make targets

`make help` — pełna lista. Najważniejsze: `run-chrome`, `run-android`, `analyze`, `test`, `build-apk`, `docker-build`.

## API

- Brak MySQL/Postgres w `docker-compose.yml`.
- Domyślnie `API_BASE_URL=http://localhost:5051` (web Satur).
- Przekazywane przez `--dart-define=API_BASE_URL=...`.

## Docker

Tylko tooling (obraz Flutter). Bez bazy. Codzienny development = Flutter na hostcie.

```bash
make docker-analyze
make docker-build
```

## Co świadomie pominięte

- **Linux desktop toolchain** (clang/cmake/ninja) — niepotrzebne przy priorytecie Android; wymagałoby `apt`/sudo.
- Emulator AVD — nie zainstalowany (duży download). Możesz dodać później albo użyć fizycznego telefonu / Chrome.
