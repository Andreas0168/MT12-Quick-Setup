Here is a setup tool for the Radiomaster MT12 to quickly setup the most of your RC-Car and save this for every truck and more.
If you like that you can support me with a donation via PayPal to a.kassner@live.de.
To download it click on MT12 Quick Setup.7z

# MT12 Quick Setup

Ein professionelles **Lua-Skript** für die RadioMaster MT12 Fernsteuerung, speziell optimiert für RC-Cars. Das Skript ersetzt die Standardanzeigen durch ein fahrzeugspezifisches Dashboard und bietet umfangreiche Einstellungs- und Tuning-Möglichkeiten direkt über die MT12.

## 🚀 Hauptfunktionen

* **RC-Car Optimiertes Dashboard**: Alle fahrrelevanten Telemetrie- und Statusdaten im typischen RC-Design.
* **5-seitiges Hauptmenü**: Schneller Wechsel zwischen verschiedenen Telemetrie- und Analyse-Anzeigen.
* **Umfangreiches Einstellungs-Untermenü (7 Seiten)**: Volle Kontrolle über Fahrhilfen und Setups (u. a. ABS und Gyro-Lenkung für den **Radiolink R6FG** Empfänger).
* **Modell- & Tool-Untermenü (3 Seiten)**: Einfaches Laden/Speichern von Modellen, ein integrierter Lap-Timer sowie eine LED-Steuerung.

## 🎛️ Menüstruktur & Seitenübersicht

### 1. Hauptmenü (5 Seiten)
* Übersichtliche Displays für Telemetrie, Geschwindigkeit, Spannungen und Fahrdaten im RC-Car-Stil.

### 2. Einstellungs-Untermenü (7 Seiten)
* **ABS-Konfiguration**: Feineinstellung von Pulsweite, Frequenz und Bremstrommel-Verhalten.
* **Gyro-Lenkung**: Direkte Kontrolle der Kreisel-Empfindlichkeit für Empfänger wie den **Radiolink R6FG**.
* *Sowie 5 weitere Seiten für Servowege, Expo-Kurven, Trimmungen und modellspezifische Setups.*

### 3. Modell- & Utility-Untermenü (3 Seiten)
* **Modell-Management**: Schnelles Laden, Speichern und Sichern deiner Fahrzeugprofile.
* **Lap-Timer**: Leistungsstarker Rundenzähler für bis zu **999 Runden** inklusive Bestzeiten-Anzeige.
* **LED-Steuerung**: Anpassung der Lichteffekte der MT12.

## 🛠️ Installation

1. Verbinde die RadioMaster MT12 per USB mit dem PC (im SD-Karten-Modus) oder entnehme die MicroSD-Karte.
2. Kopiere die Skriptdateien in den folgenden Ordner auf der SD-Karte:
   ```text
   /SCRIPTS/TELEMETRY/
   ```
3. Trenne die Verbindung sicher und starte die MT12 neu.

## 📖 Nutzung

1. Gehe in den **Modelleinstellungen** der MT12 auf die Registerkarte **Telemetry** (Telemetrie).
2. Scrolle nach unten zu den **Screeneinstellungen** (Bildschirme).
3. Wähle einen freien Slot, ändere den Typ auf **Script** und wähle `QSETUP` aus.
4. Kehre zum Hauptbildschirm zurück und halte die **TELE**-Taste gedrückt, um das Lua-Skript zu starten.
5. Nutze das Drehrad und die Tasten der MT12, um zwischen dem Hauptmenü und den Untermenüs zu navigieren.

## 📝 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert – siehe die [LICENSE](LICENSE)-Datei für Details.
