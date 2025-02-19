# ctbankix-continuation

## Motivation: Weiterführung des ehemaligen Projekts _ctbankix_.

Dieses Projekt möchte das mittlerweile beendete Projekt _ctbankix_ weiterführen. Bereitgestellt wird dazu ein Shell-Skript, mit dem ein neues Live-System erzeugt werden kann. Bitte folgen Sie den Hinweisen im Shell-Skript am Anfang sowie der unten beschriebenen Bauanleitung.


## Neueste Updates

### 19.02.2025 "Back to the roots"
"Zurück zu den Wurzel" - so lautet das neue Release. Nachdem Canonical mit Ubuntu immer eigenwilligere Wege geht, verabschiedet sich das Projekt nunmehr von Ubuntu als Basis und nutzt zukünftig Debian (von dem Ubuntu abgeleitet ist) als Basis. In diesem Zusammenhang stehen auch neue Möglichkeiten zur Verfügung, ein minimales ISO-Image zu bauen.


## Bauanleitung

### Build-System bereitstellen

1. VirtualBox (und ggf. Extension Pack) installieren
2. Virtuelle Maschine aufsetzen (Debian 12 LxQt, 100GB Festplattenplatz, min. 8GB RAM, aktive Netzwerkverbindung per NAT) und darin [Debian 12 LxQt](https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/) installieren.
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
lubuntu@lubuntu:~$ wget https://github.com/ctbankix-continuation-team/ctbankix-continuation/raw/master/ctbankix_debian_12.sh
lubuntu@lubuntu:~$ chmod +x ctbankix_debian_12.sh
lubuntu@lubuntu:~$ sudo ./ctbankix_debian_12.sh
```

### Erzeugte ISO-Datei auf einen USB-Stick kopieren

#### USB-Stick formatieren mit `gnome-disk-utility`
- USB-Stick links auswählen und Laufwerk formatieren (über 3-Punkte-Symbol)
  - Löschen: Vorhandene Daten nicht überschreiben (Schnell)
  - Partitionierung: Kompatibel mit allen Systemen und Geräten (MBR/DOS)
- Partition erstellen (über +-Symbol)
  - Partitionsgröße: komplett
  - Datenträgername: beliebig
  - Kompatibel mit allen Systemen und Geräten (FAT)
- Zusätzliche Partitionierungseinstellungen (über Zahnrad-Symbol)
  - Partition bearbeiten: Bootfähig setzen
- Gerät notieren: bspw. /dev/sda1 und dieses dann unten bei `X` ersetzen

#### Live-Image auf USB-Stick übertragen

```bash
sudo -s
apt install syslinux syslinux-common
cp /usr/lib/syslinux/mbr/mbr.bin /dev/sdX
syslinux --install /dev/sdX1

mkdir /mnt/live-iso
mkdir /mnt/usb-stick

mount /dev/sdX1 /mnt/usb-stick/
mount -o loop live.iso /mnt/live-iso/

cp /usr/lib/syslinux/modules/bios/menu.c32 /mnt/usb-stick/
cp -a /mnt/live-iso/. /mnt/usb-stick/
sync

cat > /mnt/usb-stick/syslinux.cfg << EOF
DEFAULT loadconfig

LABEL loadconfig
  CONFIG /isolinux/isolinux.cfg
  APPEND /isolinux/
EOF

umount /mnt/usb-stick
umount /mnt/live-iso

rmdir /mnt/usb-stick/
rmdir /mnt/live-iso/
```


## Danksagung

Viel Dank gebührt der Community im [heise Forum](https://www.heise.de/forum/c-t/Kommentare-zu-c-t-Artikeln/Sicheres-Online-Banking-mit-Bankix/forum-31485/). Herzlichen Dank für Pull-Requests auch an:

* [Michael Kaufmann](https://github.com/mkauf)
