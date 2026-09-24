# CI / reproducible Android builds — no local DB.
# Day-to-day development uses host Flutter (see Makefile).
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Keep image lean; project is mounted at runtime via compose.
USER root
RUN flutter config --no-analytics && flutter precache --android
USER flutter

CMD ["flutter", "doctor"]
