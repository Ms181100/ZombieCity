# Lahn-Infection – Unity Android

Eigenständiger Neubau nach dem GDD: Third-Person Story-Survival in Mittelhessen.

## Enthaltenes Grundgerüst

- Unity Input System für Touch und Bluetooth-Gamepads
- Bewegung, Sprint, Ducken, Ausweichen, Kamera und Auto-Aim
- Zombie-Zustandsmaschine für Schlurfer, Renner und Wächter
- ereignisbasiertes Lärmsystem ohne Physik-Suche in jedem Frame
- Rasterinventar mit Gewicht, Stapeln und Haltbarkeit
- ScriptableObject-Items und Werkbank-/Mobile-Crafting
- Blutung, Knochenbruch und Infektionsstatus
- komplette Zustandsfolge der Mission „Das letzte Signal“
- Loot-, Tür-, Generator-, Funk-, Bett- und Ablenkungs-Interaktionen
- lokale Safehouse-Spielstände mit atomarem Dateiaustausch
- URP und AI Navigation als Paketabhängigkeiten
- automatisch erzeugte spielbare Android-Prototypszene
- Touch-Bewegung, Wischkamera, Schießen, Nachladen und Treffer
- drei sicht- und spielbar unterschiedliche Zombieklassen
- prozedurale Testgeräusche für Schuss, Treffer und Nachladen
- deutsche B49-Testumgebung mit Apotheke und Feuerwehr

## Unity-Version

Ziel: Unity 6 LTS, URP, Android Build Support, neues Input System.

## Prototyp starten

Das Projekt in Unity 6 öffnen. Beim ersten Import erzeugt das Editor-Skript automatisch
`Assets/LahnInfection/Scenes/LahnInfectionPrototype.unity`, trägt sie in die Build Settings ein
und setzt App-Name, Paketkennung, Querformat und Android-Mindestversion. Danach Play drücken.

## Nächste Projektstufe

Die erste spielbare Mission „Das letzte Signal“ wird als eigene Szene aufgebaut:
Keller → B49 → Apotheke → Feuerwehrwache. Danach folgen UI-Prefabs,
Savehouse-Speicherung, Waffen, Loot und Android-Build-Pipeline.
