# Verteilerplanung

Prototyp einer Web-App zur Planung von Unter- und Hauptverteilungen (UV/HV).

Live: https://tobimueller0203-sudo.github.io/Verteilerplanung/

Die App ist eine einzelne Datei (`index.html`). Daten werden nur im Browser des jeweiligen Geräts gespeichert.

## Datenquellen

- `plz.json` Schweiz: GeoNames (CC BY 4.0), über das npm-Paket `swiss-zipcodes` (MIT).
- `plz.json` Deutschland: OpenStreetMap-Mitwirkende (ODbL), aufbereitet von suche-postleitzahl.org, über das npm-Paket `postleitzahlen`.
