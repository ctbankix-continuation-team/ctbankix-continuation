#!/bin/bash

#	ctbankix-continuation
#	Copyright (C) 2018 ctbankix-continuation-team
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU Affero General Public License as
#	published by the Free Software Foundation, either version 3 of the
#	License, or (at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU Affero General Public License for more details.
#
#	You should have received a copy of the GNU Affero General Public License
#	along with this program.  If not, see <https://www.gnu.org/licenses/>.

echo
echo "Bauanleitung"
echo "============"
echo
echo "1. Das vorliegende Skript bitte in (L)Ubuntu 18.04 32 Bit per sudo auf der Kommandozeile/im Terminal ausfuehren."
echo "2. Nach Durchlauf des Skriptes steht ein ISO-Image (live.iso) bereit, dass auf einen USB-Stick gebracht werden muss."
echo "  a) Den USB-Stick (min. 2 GB, besser 4 GB) entsprechend (eine Partition, FAT32) formatieren (bspw. mithilfe der Anwendung 'Laufwerke')."
echo "  b) Das Bootflag des Sticks setzen (bspw. mithilfe der Anwendung 'GParted')."
echo "  c) Das ISO-Image (live.iso) mithilfe der Anwendung 'UNetbootin' auf den Stick bringen (PS: Der Startmedienersteller ermoeglicht keine volle Funktionalitaet des bankix-Systems)."
echo
read -r -p "Das habe ich verstanden. [j/N] " questionResponse
echo 
if [[ $questionResponse != [jJ] ]]
then
	exit
fi

if ! head -1 /etc/issue | grep -q 'Ubuntu 18.04 LTS' || ! [ $(getconf LONG_BIT) == '32' ]
then
	echo "Sie benutzen die falsche (L)Ubuntu-Version. Bitte (L)Ubuntu 18.04 32 Bit verwenden."
	exit
fi

set -o xtrace

#### Kernel bauen #### BEGIN ####

# Kernel-Verzeichnis anlegen, benoetigte Pakete einspielen, Kernel-Quellcode herunterladen

mkdir kernel
cd kernel

# Quelltext-Paketquelle hinzufügen/aktivieren
add-apt-repository -s "deb http://de.archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-updates main"
apt-get update

apt-get -y install fakeroot
apt-get -y build-dep linux-image-$(uname -r)
apt-get source linux-image-$(uname -r)

cd $(ls -d */ | grep linux-)

### Patchen

sed -i '/^static inline unsigned int ata_dev_enabled(const struct ata_device \*dev)/{N;N;N;s/return ata_class_enabled(dev->class);/return dev->class == ATA_DEV_ATAPI;/}' include/linux/libata.h

sed -i '/^CONFIG_BLK_DEV_NVME/d' debian.master/config/config.common.ubuntu
sed -i '/^CONFIG_NVME_/d' debian.master/config/config.common.ubuntu

cat >> debian.master/config/i386/config.common.i386 << EOF
# CONFIG_BLK_DEV_NVME is not set
# CONFIG_NVME_FC is not set
# CONFIG_NVME_RDMA is not set
# CONFIG_NVME_TARGET is not set
EOF

sed -i "/^CONFIG_BLK_DEV_NVME/ s/'m'/'n'/g" debian.master/config/annotations

# Kernel bauen

fakeroot debian/rules clean
skipabi=true skipmodule=true fakeroot debian/rules binary-indep
skipabi=true skipmodule=true fakeroot debian/rules binary-perarch
skipabi=true skipmodule=true fakeroot debian/rules binary-generic

cd ../../

#### Kernel bauen #### END ######


#### Return-Values der Bash-Kommandos auswerten #### BEGIN #####

function CHECK {
	#if [ ${PIPESTATUS[0]} -ne 0 ]
	if [ $? -eq 0 ]
	then
		echo $(tput bold)$(tput setaf 2)[PASS]$(tput sgr0)
	else
		echo $(tput bold)$(tput setaf 1)[FAIL]$(tput sgr0)
	fi
}
export PS4='$(CHECK)\n\n$(tput bold)$(tput setaf 7)$(tput setab 4)+ (${BASH_SOURCE}:${LINENO}):$(tput sgr0) '

#### Return-Values der Bash-Kommandos auswerten #### END #######


#### System bauen #### BEGIN ####

apt-get -y install build-essential debootstrap squashfs-tools genisoimage syslinux-common syslinux-utils
wget -c -N -P source http://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-desktop-i386.iso
wget -c -N -P source http://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-desktop-amd64.iso

mount -o loop source/lubuntu-18.04-desktop-amd64.iso /mnt/
mkdir iso
cp -r /mnt/.disk/ /mnt/boot/ /mnt/EFI/ iso/
mkdir iso/casper
umount /mnt

# Bereits gebautes Live-System des verwendeteten ISOs entpacken
mount -o loop source/lubuntu-18.04-desktop-i386.iso /mnt/
unsquashfs -d squashfs /mnt/casper/filesystem.squashfs

# Ressourcen des Build-Systems in Live-System hineinmappen
mount --bind /dev squashfs/dev
mount -t devpts devpts squashfs/dev/pts
mount -t proc proc squashfs/proc
mount -t sysfs sysfs squashfs/sys

# DNS + Paketquellen des Build-Systems nutzen, vorher Ressourcen des Live-Systems sichern
chroot squashfs/ cp -dp /etc/resolv.conf /etc/resolv.conf.original
chroot squashfs/ cp -dp /etc/apt/sources.list /etc/apt/sources.list.original
cp /etc/resolv.conf squashfs/etc/
cp /etc/apt/sources.list squashfs/etc/apt/

# Locales setzen
chroot squashfs/ locale-gen de_DE.UTF-8

# System schlank machen
chroot squashfs/ apt-get -y purge pidgin* abiword* transmission* gnumeric* xfburn* mtpaint simple-scan* sylpheed* audacious* guvcview fonts-noto-cjk ubiquity* mplayer language-pack* lvm2 gparted apport whoopsie blue* btrfs* cryptsetup evolution* gdebi* genisoimage xul-ext-ubufox firefox-locale-*
chroot squashfs/ apt-get -y purge linux-image-* linux-headers-* linux-modules-*
chroot squashfs/ apt-get -y autoremove --purge

# alle Updates einspielen
chroot squashfs/ apt-get update
#chroot squashfs/ apt-get -y dist-upgrade
chroot squashfs/ apt-get -y upgrade

# Zusaetzliche Pakete einspielen
chroot squashfs/ apt-get -y install tzdata language-pack-de firefox-locale-de squashfs-tools cups network-manager-openconnect-gnome wswiss wngerman language-pack-gnome-de wogerman

# Zeitzone setzen
echo "Europe/Berlin" | tee squashfs/etc/timezone
rm squashfs/etc/localtime
chroot squashfs/ ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
chroot squashfs/ dpkg-reconfigure --frontend noninteractive tzdata

# Modifizierten Kernel einspielen
cp kernel/linux-headers*.deb kernel/linux-image*.deb kernel/linux-modules*.deb squashfs/
chroot squashfs/ ls | chroot squashfs/ grep .deb | chroot squashfs/ tr '\n' ' ' | chroot squashfs/ xargs dpkg -i
chroot squashfs/ apt-get -f -y install
rm squashfs/*.deb

# APT + Software-Center aufrauemen
chroot squashfs/ apt-get -y check
chroot squashfs/ apt-get -y autoremove --purge
chroot squashfs/ apt-get -y clean
rm squashfs/var/cache/lsc_packages.db

# Firefox-Profil im Ordner source/skel erzeugen
mkdir -p source/skel/.mozilla/firefox/ctbankix.default
mkdir -p source/skel/.mozilla/firefox/besondersGehaertetesProfil.default

# Plugins nachladen
wget -O squashfs/usr/lib/firefox-addons/extensions/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi https://addons.mozilla.org/firefox/downloads/latest/noscript/
wget -O squashfs/usr/lib/firefox-addons/extensions/https-everywhere@eff.org.xpi https://addons.mozilla.org/firefox/downloads/latest/https-everywhere/
rm -rf squashfs/usr/lib/firefox/distribution/searchplugins/locale/

# Besonders gehaertetes Profil nach 'pyllyukko' anlegen
wget -O source/skel/.mozilla/firefox/besondersGehaertetesProfil.default/user.js https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js
sed -i -e 's/^user_pref("browser.search.countryCode",.*/user_pref("browser.search.countryCode","DE");/' source/skel/.mozilla/firefox/besondersGehaertetesProfil.default/user.js
sed -i -e 's/^user_pref("browser.search.region",.*/user_pref("browser.search.region","DE");/' source/skel/.mozilla/firefox/besondersGehaertetesProfil.default/user.js
sed -i -e 's/^user_pref("intl.accept_languages",.*/user_pref("intl.accept_languages","de-de,de");/' source/skel/.mozilla/firefox/besondersGehaertetesProfil.default/user.js

# Startpage zu den Suchmaschinen hinzufuegen
wget -O squashfs/usr/lib/firefox-addons/extensions/{20fc2e06-e3e4-4b2b-812b-ab431220cada}.xpi https://addons.mozilla.org/firefox/downloads/file/839942/startpagecom_private_search_engine-1.1.2-an+fx-linux.xpi

# Firefox-Einstellungen
cat > squashfs/usr/lib/firefox/defaults/pref/ctbankixAutoConfig.js << EOF
pref("general.config.filename", "ctbankixFirefoxConfig.cfg");
pref("general.config.obscure_value", 0);
EOF

cat > squashfs/usr/lib/firefox/ctbankixFirefoxConfig.cfg << EOF
// Deaktiviert den Updater
lockPref("app.update.enabled", false);
// Stellt sicher dass er tatsächlich abgestellt ist
lockPref("app.update.auto", false);
lockPref("app.update.mode", 0);
lockPref("app.update.service.enabled", false);

// Deaktiviert die Kompatbilitätsprüfung der Add-ons
// clearPref("extensions.lastAppVersion"); 

// Deaktiviert 'Kenne deine Rechte' beim ersten Start
pref("browser.rights.3.shown", true);

// Versteckt 'Was ist neu?' beim ersten Start nach jedem Update
pref("browser.startup.homepage_override.mstone","ignore");

// Stellt eine Standard-Homepage ein - Nutzer können sie ändern
// defaultPref("browser.startup.homepage", "http://home.example.com");

// Deaktiviert den internen PDF-Viewer
// pref("pdfjs.disabled", true);

// Deaktiviert den Flash zu JavaScript Converter
pref("shumway.disabled", true);

// Verhindert die Frage nach der Installation des Flash Plugins
pref("plugins.notifyMissingFlash", false);

//Deaktiviert das 'plugin checking'
//lockPref("plugins.hide_infobar_for_outdated_plugin", true);
//clearPref("plugins.update.url");

// Deaktiviert den 'health reporter'
lockPref("datareporting.healthreport.service.enabled", false);

// Disable all data upload (Telemetry and FHR)
lockPref("datareporting.policy.dataSubmissionEnabled", false);

// Deaktiviert den 'crash reporter'
lockPref("toolkit.crashreporter.enabled", false);
Components.classes["@mozilla.org/toolkit/crash-reporter;1"].getService(Components.interfaces.nsICrashReporter).submitReports = false;
EOF

cat > source/skel/.mozilla/firefox/profiles.ini << EOF
[General]
StartWithLastProfile=0

[Profile0]
Name=Bisheriges ctbankix-Profil
IsRelative=1
Path=ctbankix.default

[Profile1]
Name=Besonders Gehaertetes Profil
IsRelative=1
Path=besondersGehaertetesProfil.default
EOF

cat > source/skel/.mozilla/firefox/ctbankix.default/prefs.js << EOF
# Mozilla User Preferences

/* Do not edit this file.
 *
 * If you make changes to this file while the application is running,
 * the changes will be overwritten when the application exits.
 *
 * To make a manual change to preferences, you can visit the URL about:config
 */

user_pref("browser.cache.disk.capacity", 0);
user_pref("browser.download.useDownloadDir", false);
user_pref("browser.privatebrowsing.autostart", true);
user_pref("browser.search.update", false);
user_pref("browser.startup.homepage", "https://www.heise.de/ct/projekte/ctbankix");
user_pref("browser.startup.page", 0);
user_pref("capability.policy.maonoscript.sites", "[System+Principal] about: about:addons about:blank about:blocked about:certerror about:config about:crashes about:feeds about:home about:memory about:neterror about:plugins about:pocket-saved about:pocket-signup about:preferences about:privatebrowsing about:sessionrestore about:srcdoc about:support blob: chrome: mediasource: moz-extension: moz-safe-about: resource:");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("extensions.lastAppVersion", "50.0.2");
user_pref("network.cookie.prefsMigrated", true);
user_pref("network.predictor.cleaned-up", true);
user_pref("privacy.donottrackheader.enabled", true);
EOF

# Firefox-Profil ins Zielsystem kopieren
cp -r source/skel squashfs/etc/

# Menue bauen
mkdir iso/isolinux
cp /mnt/isolinux/boot.cat /mnt/isolinux/isolinux.bin /mnt/isolinux/*.c32 iso/isolinux/

# Boot (ohne UEFI)
cat > iso/isolinux/isolinux.cfg << EOF
default vesamenu.c32
menu title c't Bankix Lubuntu 18.04.0

label ctbankix
  menu label c't Bankix Lubuntu 18.04.0
  kernel /casper/vmlinuz
  append BOOT_IMAGE=/casper/vmlinuz boot=casper initrd=/casper/initrd.lz showmounts quiet splash -- debian-installer/language=de console-setup/layoutcode?=de
  
label local
  menu label Betriebssystem von Festplatte starten
  localboot 0x80
EOF

# Boot (mit UEFI)
cat > iso/boot/grub/grub.cfg << EOF

if loadfont /boot/grub/font.pf2 ; then
	set gfxmode=auto
	insmod efi_gop
	insmod efi_uga
	insmod gfxterm
	terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "c't Bankix Lubuntu 18.04.0" {
	set gfxpayload=keep
	linux	/casper/vmlinuz  file=/cdrom/preseed/lubuntu.seed boot=casper showmounts quiet splash -- debian-installer/language=de console-setup/layoutcode?=de
	initrd	/casper/initrd.lz
}
EOF

# ToDo: Weglassen?
cat > iso/boot/grub/loopback.cfg << EOF
menuentry "c't Bankix Lubuntu 18.04.0" {
	set gfxpayload=keep
	linux	/casper/vmlinuz  file=/cdrom/preseed/lubuntu.seed boot=casper iso-scan/filename=${iso_path} showmounts quiet splash -- debian-installer/language=de console-setup/layoutcode?=de
	initrd	/casper/initrd.lz
}
EOF

# apt-Pinning um das Einspielen ungepatchter Kernel zu verhindern
cat > squashfs/etc/apt/preferences << EOF
Package: linux-image*
Pin: origin *.ubuntu.com
Pin-Priority: -1

Package: linux-headers*
Pin: origin *.ubuntu.com
Pin-Priority: -1

Package: linux-modules*
Pin: origin *.ubuntu.com
Pin-Priority: -1

Package: linux-lts*
Pin: origin *.ubuntu.com
Pin-Priority: -1

Package: linux-generic*
Pin: origin *.ubuntu.com
Pin-Priority: -1
EOF

cat > squashfs/excludes << EOF
casper/*
cdrom/*
cow/*
etc/mtab
home/lubuntu/.cache/*
media/*
mnt/*
proc/*
rofs/*
sys/*
tmp/*
var/log/*
var/cache/apt/archives/*
EOF

#TODO: Initramdisk bauen und an entsprechende Stelle kopieren, sobald gepatchte Kernel bereitstehen

cat > squashfs/usr/sbin/BankixCreateSnapshot.sh << EOF
#!/bin/bash
echo "Snapshot erstellen"
echo "=================="
echo
echo "1. Alle Anwendungen schließen!"
echo "2. Schreibschutzschalter am USB-Stick (sofern vorhanden) auf 'offen' stellen!"
echo
read -r -p "Snapshot jetzt erstellen? [j/N] " questionResponse
if [[ \$questionResponse = [jJ] ]]
then
	echo
	sudo apt-get -y clean
	sudo mount -o remount,rw /cdrom
	sudo rm -f /cdrom/casper/filesystem_new.squashfs
	sudo rm -f /cdrom/casper/filesystem_old.squashfs
	sudo mksquashfs / /cdrom/casper/filesystem_new.squashfs -ef /excludes -wildcards
	sudo mv /cdrom/casper/filesystem.squashfs /cdrom/casper/filesystem_old.squashfs
	sudo mv /cdrom/casper/filesystem_new.squashfs /cdrom/casper/filesystem.squashfs
	sudo sync
	sudo mount -o remount,ro /cdrom
	echo
	echo "Das System muss heruntergefahren werden! Aktivieren Sie anschließend den mechansichen Schreibschutzschalter und starten neu. Bitte Taste druecken!"
	read dummy
	sudo shutdown -P now
else
	echo
    echo "Es wurde kein Snapshot erstellt!"
    read dummy
fi
EOF
chmod +x squashfs/usr/sbin/BankixCreateSnapshot.sh

mkdir squashfs/etc/skel/Desktop/
cat > squashfs/etc/skel/Desktop/BankixCreateSnapshot.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Name=Snapshot erstellen
Exec=/usr/sbin/BankixCreateSnapshot.sh
Type=Application
Terminal=true
Icon=/usr/share/icons/Humanity/actions/48/document-save.svg
EOF
chmod +x squashfs/etc/skel/Desktop/BankixCreateSnapshot.desktop

cp /usr/share/applications/lxrandr.desktop squashfs/etc/skel/Desktop/
cp /usr/share/applications/firefox.desktop squashfs/etc/skel/Desktop/
cp /usr/share/applications/update-manager.desktop squashfs/etc/skel/Desktop/

#### System bauen #### END ######


#### Iso erzeugen #### BEGIN ####

zcat squashfs/boot/initrd.img* | lzma -9c > iso/casper/initrd.lz
cp squashfs/boot/vmlinuz* iso/casper/vmlinuz

umount squashfs/dev/pts squashfs/dev squashfs/proc squashfs/sys /mnt

#mv squashfs/etc/resolv.conf.orig squashfs/etc/resolv.conf
chroot squashfs/ mv /etc/resolv.conf.original /etc/resolv.conf
chroot squashfs/ mv /etc/apt/sources.list.original /etc/apt/sources.list

mksquashfs squashfs iso/casper/filesystem.squashfs -noappend
genisoimage -cache-inodes -r -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o live.iso -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot iso

isohybrid -u live.iso

#### Iso erzeugen #### END ######
date
echo
