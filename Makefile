.PHONY: help doctor devices run run-chrome run-android analyze test format clean \
	build-apk build-appbundle build-web pub-get \
	docker-build docker-analyze \
	satur-api-check env

.DEFAULT_GOAL := help

# Toolchain (user-local, no sudo)
FLUTTER_ROOT ?= $(HOME)/development/flutter
ANDROID_HOME ?= $(HOME)/Android/Sdk
ANDROID_SDK_ROOT ?= $(ANDROID_HOME)
export FLUTTER_ROOT ANDROID_HOME ANDROID_SDK_ROOT
export PATH := $(FLUTTER_ROOT)/bin:$(ANDROID_HOME)/cmdline-tools/latest/bin:$(ANDROID_HOME)/cmdline-tools/latest-2/bin:$(ANDROID_HOME)/platform-tools:$(PATH)

# API: sibling Sylius project (no local DB in this repo)
# Host / Chrome: localhost:5051
# Android emulator: 10.0.2.2:5051
API_BASE_URL ?= http://localhost:5051
API_BASE_URL_ANDROID_EMU ?= http://10.0.2.2:5051

DART_DEFINE_API = --dart-define=API_BASE_URL=$(API_BASE_URL)
DART_DEFINE_API_EMU = --dart-define=API_BASE_URL=$(API_BASE_URL_ANDROID_EMU)

help:
	@echo "Satur App (Flutter) — targets"
	@echo ""
	@echo "  make doctor          Flutter doctor"
	@echo "  make devices         Lista urządzeń"
	@echo "  make pub-get         flutter pub get"
	@echo "  make analyze         Analiza statyczna"
	@echo "  make test            Testy"
	@echo "  make format          Formatowanie Dart"
	@echo "  make run             flutter run (domyślne urządzenie)"
	@echo "  make run-chrome      Chrome + API localhost:5051"
	@echo "  make run-android     Emulator/device + API 10.0.2.2:5051"
	@echo "  make build-apk       Release APK"
	@echo "  make build-appbundle Release App Bundle (Play)"
	@echo "  make build-web       Release web"
	@echo "  make clean           flutter clean"
	@echo "  make satur-api-check Ping API z projektu satur (:5051)"
	@echo "  make docker-build    Build APK w Dockerze (bez lokalnego Gradle cache)"
	@echo "  make docker-analyze  Analyze w kontenerze Flutter"
	@echo ""
	@echo "API_BASE_URL=$(API_BASE_URL)"
	@echo "Brak lokalnej bazy — backend: ../satur (Sylius) na porcie 5051."

doctor:
	flutter doctor -v

devices:
	flutter devices
	@echo ""
	flutter emulators || true

pub-get:
	flutter pub get

analyze: pub-get
	flutter analyze

test: pub-get
	flutter test

format:
	dart format lib test

run: pub-get
	flutter run $(DART_DEFINE_API)

run-chrome: pub-get
	flutter run -d chrome $(DART_DEFINE_API)

run-android: pub-get
	flutter run $(DART_DEFINE_API_EMU)

build-apk: pub-get
	flutter build apk --release $(DART_DEFINE_API)

build-appbundle: pub-get
	flutter build appbundle --release $(DART_DEFINE_API)

build-web: pub-get
	flutter build web --release $(DART_DEFINE_API)

clean:
	flutter clean

satur-api-check:
	@echo "Checking http://localhost:5051 ..."
	@curl -sS -o /dev/null -w "HTTP %{http_code}\n" --connect-timeout 3 http://localhost:5051/ \
		|| (echo "API niedostępne. W ../satur: make up  (web na :5051)"; exit 1)

env:
	@echo "FLUTTER_ROOT=$(FLUTTER_ROOT)"
	@echo "ANDROID_HOME=$(ANDROID_HOME)"
	@echo "API_BASE_URL=$(API_BASE_URL)"
	@flutter --version | head -3

# --- Docker (NO database) — tylko tooling / CI-like build ---

docker-build:
	docker compose run --rm flutter flutter build apk --release $(DART_DEFINE_API)

docker-analyze:
	docker compose run --rm flutter flutter analyze
