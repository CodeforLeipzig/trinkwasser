# Visualisierung von Trinkwasserqualität
Dies ist ein Fork des OpenData Projektes ["Trinkwasser"](http://opendatalab.de/projects/trinkwasser/) des [OKLab Heinbronn](http://codefor.de/heilbronn/). Die Webanwendung visualisert der Inhaltsstoffe des in den Komunen angebotenen Trinkwassers. Zusätzlich kann das angebotene Trinkwasser mit verschiedenen Mineralwassern verglichen werden. 

Dieses Fork entstand in einem Workshop zum [OpenDataDay 2017](http://opendataday.org/).

Das Projekt ist in der aktuellen Version unter https://trinkwasser.leipzig.codefor.de/ abrufbar.

# Lizenz und Datenquelle
Der Programmcode steht wie das Orginalprojekt unter der MIT-Lizenz. Die Tinkwasserdaten wurden uns hingegen von der OEWA Wasser und Abwasser GmbH (oewa.de) zum Zweck der Visualiserung zur Verfügung gestellt. Diese Daten stehen *nicht* unter der MIT-Lizenz, da sie (noch) Eigentum der OEWA sind. 

Es wird daran gearbeitet die Daten ebenfalls unter einer freien Lizenz zu veröffentlichen.

# Anleitung zum selber bauen
## Statische Seite generieren
1. NodeJS und npm installieren.
2. Mit `npm install` die fehlenden Pakete nachinstallieren.
3. Grunt global installieren mit `npm install -g grunt`.Grunt wird zwingend benötigt, da es die Webseite generiert.
4. `grunt` aufrufen, damit die Webseite gebaut wird. Im Anschluss existiert unter *dist* die fertige statische Seite. 

## Format der zu visualisierenden Daten

# Mögliche Erweiterungen
* Karte mit Standorten wo Messwerte vorhanden sind
* GefahrenHeatmap pro Inhaltsstoff
* Livedatenanbindung (nicht statische Daten verwenden)
* Preis pro mm^3 Leitungswasser
* Ist das dieses Wasser geeignet für diese Bevölkerungsgruppe (Babys, Senioren)
