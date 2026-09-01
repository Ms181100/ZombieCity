# Zombie City

Offline spielbarer Android-3D-Raycaster mit Touch-Steuerung.

## Steuerung

- Linker Bildschirmbereich: virtueller Stick zum Laufen
- Rechte Bildschirmhälfte ziehen: umsehen
- Roter Knopf: schießen
- Gelber Knopf: nachladen
- Nach Game Over in die Bildschirmmitte tippen: Neustart

## Bauen

Projekt in Android Studio öffnen, Gradle-Synchronisierung abwarten und **Build > Build APK(s)** wählen.
Die Debug-APK liegt danach unter `app/build/outputs/apk/debug/app-debug.apk`.

## Nur mit dem Handy: GitHub Actions

Das Projekt enthält `.github/workflows/build-apk.yml`. Nach dem Hochladen in ein
GitHub-Repository wird die APK automatisch gebaut. Unter **Actions**,
**Zombie City APK bauen** und **Artifacts** kann `ZombieCity-APK` heruntergeladen werden.
