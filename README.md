# ctbankix-continuation

## Motivation: Weiterführung des ehemaligen Projekts _ctbankix_.

Dieses Projekt möchte das mittlerweile beendete Projekt _ctbankix_ weiterführen. Bereitgestellt wird dazu ein Shell-Skript, mit dem ein neues Live-System erzeugt werden kann. Bitte folgen Sie den Hinweisen im Shell-Skript am Anfang sowie der unten beschriebenen Bauanleitung.

## Neueste Updates

Seit Anfang August 2020 steht ein Skript für die 64-Bit-Version von Lubuntu 20.04.x zur Verfügung. Dieses wird perspektivisch das Skript für die 32-Bit-Version von Lubuntu 18.04.x ersetzen, weil seitens Lubuntu keine 32-Bit-Version mehr bereitgestellt wird.

## Bauanleitung

### Build-System bereitstellen

1. VirtualBox (und ggf. Extension Pack) installieren
2. Virtuelle Maschine aufsetzen (32-Bit Linux, 50GB Festplattenplatz, min. 2GB RAM, aktive Netzwerkverbindung per NAT) und darin [Lubuntu 32 Bit 18.04.4](http://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04.4-desktop-i386.iso "ISO-Image Lubuntu 18.04.4") installieren.
3. Gasterweiterungen installieren

### Live-System innerhalb des Build-Systems bauen

Die Konsole öffnen (<kbd>CTRL</kbd>+<kbd>ALT</kbd>+<kbd>T</kbd>).

Ein neues Verzeichnis anlegen, in dem das Live-System gebaut wird, und dahin hineinwechseln.

```shell
lubuntu@lubuntu:~$ mkdir build
lubuntu@lubuntu:~$ cd build
```

Das Build-Skript herunterladen, startbar machen und per sudo ausführen.

```shell
lubuntu@lubuntu:~$ wget https://github.com/ctbankix-continuation-team/ctbankix-continuation/raw/master/ctbankix-continuation_Lubuntu_32_18.04.4.sh
lubuntu@lubuntu:~$ chmod +x ctbankix-continuation_Lubuntu_32_18.04.4.sh
lubuntu@lubuntu:~$ sudo ./ctbankix-continuation_Lubuntu_32_18.04.4.sh
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




