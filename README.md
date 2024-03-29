# ctbankix-continuation

## Motivation: Weiterführung des ehemaligen Projekts _ctbankix_.

Dieses Projekt möchte das mittlerweile beendete Projekt _ctbankix_ weiterführen. Bereitgestellt wird dazu ein Shell-Skript, mit dem ein neues Live-System erzeugt werden kann. Bitte folgen Sie den Hinweisen im Shell-Skript am Anfang sowie der unten beschriebenen Bauanleitung.


## Neueste Updates

### 18.05.2023
Update auf die Version 20.04.6 mit angepasstem 5.15er-Kernel und einigen kleineren Änderungen. Da der Aufwand für die 22.04er LTS-Version sehr groß ist (Snap entfernen, neues Bootsystem, ...), pflegen wir die 20.04er Version weiter. Da akutell keine 20.04.6er ISO-Datei seitens Lubuntu bereitgestellt wird, müssen wir den Umweg über die 20.04.5er ISO-Datei gehen (siehe Beschreibung unten).

### 26.03.2022
Update auf die neue Version 20.04.4 mit angepasstem 5.13er-Kernel und einigen kleineren Änderungen.

### 16.02.2022
Unter [Releases](https://github.com/ctbankix-continuation-team/ctbankix-continuation/releases) werden durch die CI/CD-Pipeline gebaute ISO-Images wöchentlich bereitgestellt. Diese kann man herunterladen und entsprechend der unten stehenden Anleitung auf einen USB-Stick ablegen, von wo sie gestartet werden können. Das ist so sicher, wie man der Github-Pipeline eben vertraut.

### 06.02.2022
Die aktuelle Version basiert auf Lubuntu 20.04.3 und behebt einige Fehler der Vorversion. Das alte Firefox-Profil von `ctbankix` wird nicht weiterentwickelt. Es stehen zwei neue Profile zur Verfügung, die auf den Einstellungen des [user.js-Projekts von pyllyukko](https://github.com/pyllyukko/user.js) beruhen. Da Ubuntu nur noch das aktuelle ISO-Image von Lubuntu auf seinen CD-Image-Servern bereithält, wird voraussichtlich zu jedem neuen Release von LUbuntu (also auch Point-Releases) ein neues Skript hier zur Verfügung gestellt.


## Bauanleitung

### Build-System bereitstellen

1. VirtualBox (und ggf. Extension Pack) installieren
2. Virtuelle Maschine aufsetzen (64-Bit Linux, 50GB Festplattenplatz, min. 4GB RAM, aktive Netzwerkverbindung per NAT) und darin [Lubuntu 64 Bit 20.04.5](http://cdimage.ubuntu.com/lubuntu/releases/20.04/release/lubuntu-20.04.5-desktop-amd64.iso) installieren.
3. System updaten und neustarten
4. Gasterweiterungen installieren

### Live-System innerhalb des Build-Systems bauen

Die Konsole öffnen (<kbd>CTRL</kbd>+<kbd>ALT</kbd>+<kbd>T</kbd>).

Ein neues Verzeichnis anlegen, in dem das Live-System gebaut wird, und dahin hineinwechseln.

```shell
lubuntu@lubuntu:~$ mkdir build
lubuntu@lubuntu:~$ cd build
```

Das Build-Skript herunterladen, startbar machen und per sudo ausführen.

```shell
lubuntu@lubuntu:~$ wget https://github.com/ctbankix-continuation-team/ctbankix-continuation/raw/master/ctbankix_lubuntu_20.04.6.sh
lubuntu@lubuntu:~$ chmod +x ctbankix_lubuntu_20.04.6.sh
lubuntu@lubuntu:~$ sudo ./ctbankix_lubuntu_20.04.6.sh
```

### Erzeugte ISO-Datei auf einen USB-Stick kopieren

Unetbootin innerhalb des Build-Systems installieren.

```shell
sudo add-apt-repository ppa:gezakovacs/ppa
sudo apt-get update
sudo apt-get install unetbootin 
```

Den USB-Stick an den PC anstecken und über das USB-Symbol von VirtualBox (rechts unten) in das Gastsystem einbinden.

Unetbootin über das Menü (unter Systemwerkzeuge) starten, auf Abbilddatei öffnen gehen und das ISO-Image (unter _Computer_ im Verzeichnis /home/< individueller Benutzer >/build/live.iso) auswählen.  Anschließend unter Typ _USB-Laufwerk_ und das Laufwerk (meist /dev/sdX) einstellen, danach mit _OK_ bestätigen.

## Danksagung

Viel Dank gebührt der Community im [heise Forum](https://www.heise.de/forum/c-t/Kommentare-zu-c-t-Artikeln/Sicheres-Online-Banking-mit-Bankix/forum-31485/). Herzlichen Dank für Pull-Requests auch an:

* [Michael Kaufmann](https://github.com/mkauf)




