# IDE
1. Download / Install Xtext IDE: http://www.eclipse.org/Xtext/download.html
2. Import this project into workspace
3. Run GeneratorMain passing path to csv file as main argument

# Counties geometries from OpenStreetMap
http://www.overpass-turbo.eu
```
[timeout:3600];
area["name"="Sachsen-Anhalt"];

rel(area)[boundary=administrative][admin_level=8]["de:amtlicher_gemeindeschluessel"];out geom;
```
