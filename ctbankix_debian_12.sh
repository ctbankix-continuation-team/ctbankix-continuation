#!/bin/bash

#	ctbankix-continuation
#	Copyright (C) 2025 ctbankix-continuation-team
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





# >>>>>>>>>> Konstanten und Funktionen >>>>>>>>>>
DEBIAN_VERSION="12"
KERNEL_CONFIG=.config

function resetText()				{ echo -n $(tput sgr0); }
function setTextBold()				{ echo -n $(tput bold); }
function setTextWhite()				{ echo -n $(tput setaf 7); }
function setBackgroundRed()			{ echo -n $(tput setab 1); }
function setBackgroundGreen()		{ echo -n $(tput setab 2); }
function setBackgroundYellow()		{ echo -n $(tput setab 3); }
function setBackgroundBlue()		{ echo -n $(tput setab 4); }
function setBackgroundMagenta()		{ echo -n $(tput setab 5); }
function setBackgroundCyan()		{ echo -n $(tput setab 6); }

function echoBoldWhiteOnRed ()		{ setTextBold; setTextWhite; setBackgroundRed;		echo -n $1; resetText; }
function echoBoldWhiteOnGreen ()	{ setTextBold; setTextWhite; setBackgroundGreen;	echo -n $1; resetText; }
function echoBoldWhiteOnYellow ()	{ setTextBold; setTextWhite; setBackgroundYellow;	echo -n $1; resetText; }
function echoBoldWhiteOnBlue ()		{ setTextBold; setTextWhite; setBackgroundBlue;		echo -n $1; resetText; }
function echoBoldWhiteOnMagenta ()	{ setTextBold; setTextWhite; setBackgroundMagenta;	echo -n $1; resetText; }
function echoBoldWhiteOnCyan ()		{ setTextBold; setTextWhite; setBackgroundCyan;		echo -n $1; resetText; }

function echoDateTime()				{ echoBoldWhiteOnYellow "[$(date '+%x %X')]"; }

function CheckExitCodePreviousCommand {
	if [ $? -eq 0 ]
	then
		echoBoldWhiteOnGreen "[PASS]"; echo;
	else
		echoBoldWhiteOnRed "[FAIL]"; echo;
	fi
}

# Abbruch des Skripts bei Fehlern
set -e

# <<<<<<<<<< Konstanten und Funktionen <<<<<<<<<<





# >>>>>>>>>> Dialog >>>>>>>>>>
echo
echo "Bauanleitung - Debian ${DEBIAN_VERSION} 64 Bit"
echo "====================================="
echo
echo "1. Das vorliegende Skript bitte in Debian LxQt ${DEBIAN_VERSION} 64 Bit per sudo auf der Kommandozeile/im Terminal ausfuehren."
echo "2. Nach Durchlauf des Skriptes steht ein ISO-Image (live.iso) bereit, dass auf einen USB-Stick gebracht werden muss (siehe Anleitung auf Projektseite)."
echo
read -r -p "Das habe ich verstanden. [j/N] " questionResponse
echo 
if [[ $questionResponse != [jJ] ]]
then
	exit
fi

if ! head -1 /etc/issue | grep -q "Debian GNU/Linux ${DEBIAN_VERSION}" || ! [ $(getconf LONG_BIT) == '64' ]
then
	echo "Sie benutzen die falsche Debian-Version. Bitte Debian ${DEBIAN_VERSION} 64 Bit verwenden."
	exit
fi
# <<<<<<<<<< Dialog <<<<<<<<<<





# >>>>>>>>>> Kernelbau >>>>>>>>>>

# Quelltext-Paketquelle hinzufügen/aktivieren
apt-get update

# Benoetigte Pakete zum Bauen installieren
apt-get -y install build-essential fakeroot libncurses-dev xz-utils libssl-dev flex libelf-dev bison bc bison rsync debhelper live-build

# Quellcode des Kernels auschecken und in Verzeichnis wechseln
mkdir -p kernel
cd kernel/
apt-get source linux-image-$(uname -r)-unsigned
cd linux-*/

# >>>>> Quellcode und Compile-Options anpassen >>>>>
sed -i '/^static inline unsigned int ata_dev_enabled(const struct ata_device \*dev)/{N;N;N;s/return ata_class_enabled(dev->class);/return dev->class == ATA_DEV_ATAPI;/}' include/linux/libata.h

make olddefconfig

scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --set-str SYSTEM_TRUSTED_KEYS ""

sed -i '/CONFIG_BLK_DEV_NVME/d' $KERNEL_CONFIG
sed -i '/CONFIG_NVME_/d' $KERNEL_CONFIG
sed -i '/CONFIG_DEBUG_INFO/d' $KERNEL_CONFIG

cat >> $KERNEL_CONFIG << EOF
# CONFIG_BLK_DEV_NVME is not set
# CONFIG_NVME_RDMA is not set
# CONFIG_NVME_FC is not set
# CONFIG_NVME_TCP is not set
# CONFIG_NVME_TARGET is not set

CONFIG_DEBUG_INFO_NONE=y
# CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT is not set
# CONFIG_DEBUG_INFO_DWARF4 is not set
# CONFIG_DEBUG_INFO_DWARF5 is not set
EOF
# <<<<< Quellcode und Compile-Options <<<<<



# >>>>> Kernel bauen >>>>>
echo; echoDateTime; echo -n " "; echoBoldWhiteOnCyan "Kernel-Build Start"; echo; echo;

make clean
make bindeb-pkg -j$((`nproc`+1)) LOCALVERSION=-ctbankix

echo; echoDateTime; echo -n " "; echoBoldWhiteOnCyan "Kernel-Build Ende"; echo; echo;
cd ../../
# <<<<< Kernel bauen <<<<<

# <<<<<<<<<< Kernelbau <<<<<<<<<<





# >>>>>>>>>> Live-Build-System bauen >>>>>>>>>>
apt-get -y install 

mkdir -p live-build
cd live-build

LIVE_BUILD_ADDITIONAL_PACKAGES_FILE=config/package-lists/desktop.list.chroot

# clean
rm -f $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE
lb clean

# live build Konfiguration
lb config --distribution bookworm --memtest none --bootappend-live "boot=live components locales=de_DE.UTF-8 keyboard-layouts=de"

# Pakete
echo tasksel sddm-theme-debian-elarun sddm lxqt-core >> $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE
echo system-config-printer >> $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE
echo tasksel xorg xserver-xorg-video-all xserver-xorg-input-all desktop-base >> $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE
echo xdg-utils fonts-symbola avahi-daemon libnss-mdns anacron eject iw alsa-utils sudo firefox-esr >> $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE
echo manpages-de wngerman ingerman aspell-de >> $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE
echo firefox-esr-l10n-de mythes-de hyphen-de hunspell-de-de >> $LIVE_BUILD_ADDITIONAL_PACKAGES_FILE

# Build
lb build

cd ..
# <<<<<<<<<< Live-Build-System bauen <<<<<<<<<<





# >>>>>>>>>> System bauen >>>>>>>>>>

# Debug-Ausgaben fuer den restlichen Teil des Skripts aktivieren
export PS4='$(CheckExitCodePreviousCommand)\n\n$(echoDateTime) $(echoBoldWhiteOnMagenta "LN: ${LINENO}") $(setTextBold)$(setTextWhite)$(setBackgroundCyan)${BASH_COMMAND}$(resetText)\n'
set -x

# Benoetigte Pakete installieren und aktuelles Lubuntu-ISO herunterladen
apt-get -y install build-essential debootstrap squashfs-tools genisoimage syslinux-common syslinux-utils

# Mounten und Verzeichnisse kopieren
mount -o loop live-build/live-image-amd64.hybrid.iso /mnt/

mkdir iso
cp -r /mnt/.disk/ /mnt/boot/ /mnt/EFI/ iso/
mkdir iso/live

# Bereits gebautes Live-System des verwendeteten ISOs entpacken
unsquashfs -d squashfs /mnt/live/filesystem.squashfs

# Ressourcen des Build-Systems in Live-System hineinmappen
mount --bind /dev squashfs/dev
mount -t devpts devpts squashfs/dev/pts
mount -t proc proc squashfs/proc
mount -t sysfs sysfs squashfs/sys

# DNS + Paketquellen des Build-Systems nutzen, vorher Ressourcen des Live-Systems sichern
chroot squashfs/ cp -dp /etc/resolv.conf /etc/resolv.conf.original
cp /etc/resolv.conf squashfs/etc/

# Paketquellen setzen
cat > squashfs/etc/apt/sources.list << EOF
deb http://deb.debian.org/debian/ bookworm main non-free-firmware 
deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware 
deb http://security.debian.org/debian-security/ bookworm-security main non-free-firmware 
deb http://deb.debian.org/debian/ bookworm-backports main non-free-firmware 
EOF

# Locales setzen
rm -rf squashfs/usr/share/locale/
echo "de_DE.UTF-8 UTF-8" > squashfs/etc/locale.gen
chroot squashfs/ apt-get reinstall locales
chroot squashfs/ dpkg-reconfigure --frontend noninteractive locales
chroot squashfs/ update-locale LANG=de_DE.UTF-8
chroot squashfs/ select-default-wordlist --set-default='new german'

# System schlank machen
chroot squashfs/ apt-get -y purge vim* oxygen-icon-theme xscreensaver* lxqt-themes pocketsphinx-* qlipper fonts-urw-base35 gnome-accessibility-themes

# chroot squashfs/ apt-get -y purge linux-image-* linux-headers-* linux-modules-* 
chroot squashfs/ apt-get -y purge linux-image-* linux-headers-*
chroot squashfs/ apt-get -y autoremove --purge

# alle Updates einspielen
chroot squashfs/ apt-get update
chroot squashfs/ apt-get -y upgrade

# Zusaetzliche Pakete einspielen
chroot squashfs/ apt-get -y --no-install-recommends --no-install-suggests install tzdata squashfs-tools systemd-timesyncd bash-completion nm-tray nm-tray-l10n qpdfview screengrab package-update-indicator

# Zeitzone setzen
echo "TZ=Europe/Berlin" | tee squashfs/etc/environment

# Echtzeituhr: Lokalzeit anstatt UTC verwenden für Dual-Boot mit Windows
echo "0.0 0 0" > squashfs/etc/adjtime
echo "0" >> squashfs/etc/adjtime
echo "LOCAL" >> squashfs/etc/adjtime

# Modifizierten Kernel einspielen
cp kernel/linux-image-*-ctbankix_*.deb squashfs/
chroot squashfs/ ls | chroot squashfs/ grep .deb | chroot squashfs/ tr '\n' ' ' | chroot squashfs/ xargs dpkg -i
chroot squashfs/ apt-get -f -y install
rm squashfs/*.deb

# apt-Pinning um das Einspielen ungepatchter Kernel zu verhindern
cat > squashfs/etc/apt/preferences << EOF
Package: linux-image*
Pin: origin *.debian.org
Pin-Priority: -1

Package: linux-headers*
Pin: origin *.debian.org
Pin-Priority: -1

Package: linux-modules*
Pin: origin *.debian.org
Pin-Priority: -1

Package: linux-lts*
Pin: origin *.debian.org
Pin-Priority: -1

Package: linux-generic*
Pin: origin *.debian.org
Pin-Priority: -1
EOF

# Microcodes + Tools nachinstallieren, die durch das Entfernen der linux*-Pakete verloren gegangen sind
chroot squashfs/ apt-get -y install firmware-linux amd64-microcode intel-microcode iucode-tool thermald

# APT + Software-Center aufrauemen
chroot squashfs/ apt-get -y check
chroot squashfs/ apt-get -y autoremove --purge
chroot squashfs/ apt-get -y clean
rm -rf squashfs/var/lib/apt/lists/


# >>>>> Firefox-Profile einrichten >>>>>

# Plugins nachladen
wget -O squashfs/usr/lib/firefox-esr/browser/extensions/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi https://addons.mozilla.org/firefox/downloads/latest/noscript/
wget -O squashfs/usr/lib/firefox-esr/browser/extensions/uBlock0@raymondhill.net.xpi https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/

# TODO: eigene Search einbinden
# rm -rf squashfs/usr/lib/firefox/distribution/searchplugins/locale/

# Firefox-Profile im Ordner squashfs/etc/skel/ erzeugen
FIREFOX_DIR=squashfs/etc/skel/.mozilla/firefox
FIREFOX_DIR_MAXIMUM_HARDENED_PROFILE=$FIREFOX_DIR/maximumHardened.default
FIREFOX_DIR_RELAXED_HARDENED_PROFILE=$FIREFOX_DIR/relaxedHardened.default

mkdir -p $FIREFOX_DIR_MAXIMUM_HARDENED_PROFILE
mkdir -p $FIREFOX_DIR_RELAXED_HARDENED_PROFILE

# Maximal und benutzbar (relaxed) gehaertetes Profil nach 'pyllyukko' anlegen
wget -P $FIREFOX_DIR_MAXIMUM_HARDENED_PROFILE https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js
wget -P $FIREFOX_DIR_RELAXED_HARDENED_PROFILE https://raw.githubusercontent.com/pyllyukko/user.js/relaxed/user.js

# Lokalisierung auf 'DE' aendern
find $FIREFOX_DIR -name "user.js" -exec sed -i -e 's/^user_pref("browser.search.countryCode",.*/user_pref("browser.search.countryCode","DE");/' {} +
find $FIREFOX_DIR -name "user.js" -exec sed -i -e 's/^user_pref("browser.search.region",.*/user_pref("browser.search.region","DE");/' {} +
find $FIREFOX_DIR -name "user.js" -exec sed -i -e 's/^user_pref("intl.accept_languages",.*/user_pref("intl.accept_languages","de-de,en");/' {} +

cat > $FIREFOX_DIR/profiles.ini << EOF
[General]
StartWithLastProfile=0

[Profile0]
Name=Benutzbar Gehaertet
IsRelative=1
Path=relaxedHardened.default

[Profile1]
Name=Maximal Gehaertet
IsRelative=1
Path=maximumHardened.default
EOF
# <<<<< Firefox-Profile einrichten <<<<<



# >>>>> Boot-Menue >>>>>

# Verzeichnis anlegen und Dateien aus Isolinux kopieren
mkdir iso/isolinux
cp /mnt/isolinux/boot.cat /mnt/isolinux/isolinux.bin /mnt/isolinux/*.c32 iso/isolinux/

# Boot (ohne UEFI)
# Schweiz:
# - "locale=de_DE" ersetzen durch "locale=de_CH"
# - "layoutcode=de" ersetzen durch "layoutcode=ch"
cat > iso/isolinux/isolinux.cfg << EOF
default vesamenu.c32
timeout 100
menu title c't Bankix Debian ${DEBIAN_VERSION}

label ctbankix
  menu label c't Bankix Debian ${DEBIAN_VERSION}
  kernel /live/vmlinuz
  append BOOT_IMAGE=/live/vmlinuz boot=live initrd=/live/initrd.lz fsck.mode=skip showmounts quiet splash noprompt components locales=de_DE.UTF-8 keyboard-layouts=de
    
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
set timeout=10

menuentry "c't Bankix Debian ${DEBIAN_VERSION}" {
	set gfxpayload=keep
	linux	/live/vmlinuz boot=live fsck.mode=skip showmounts quiet splash noprompt components locales=de_DE.UTF-8 keyboard-layouts=de
	initrd	/live/initrd.lz
}
EOF
# <<<<< Boot-Menue <<<<<



# >>>>> Snapshot-Funktionalitaet >>>>>
cat > squashfs/usr/sbin/BankixCreateSnapshot.sh << 'EOF'
#!/bin/bash
MOUNTPOINT=/run/live/medium
echo "Snapshot erstellen"
echo "=================="
echo
echo "1. Alle Anwendungen schließen!"
echo "2. Schreibschutzschalter am USB-Stick (sofern vorhanden) auf 'offen' stellen!"
echo
read -r -p "Snapshot jetzt erstellen? [j/N] " questionResponse
if [[ $questionResponse = [jJ] ]]
then
	echo
	sudo apt-get -y clean
	sudo blockdev --setrw $(findmnt -n -o SOURCE --mountpoint $MOUNTPOINT)
	sudo mount -o remount,rw $MOUNTPOINT
	sudo mksquashfs / $MOUNTPOINT/live/filesystem.squashfs.next -ef /excludes -wildcards -b 32768 -comp zstd -Xcompression-level 22
	sudo rm -f $MOUNTPOINT/live/filesystem.squashfs.previous
	sudo mv $MOUNTPOINT/live/filesystem.squashfs $MOUNTPOINT/live/filesystem.squashfs.previous
	sudo mv $MOUNTPOINT/live/filesystem.squashfs.next $MOUNTPOINT/live/filesystem.squashfs
	sudo sync -f $MOUNTPOINT/live/
	sudo mount -o remount,ro $MOUNTPOINT
	echo
	echo "Das System muss heruntergefahren werden! Aktivieren Sie anschließend den mechanischen Schreibschutzschalter und starten neu. Bitte Taste druecken!"
	read dummy
	sudo shutdown -P now
else
	echo
    echo "Es wurde kein Snapshot erstellt!"
    read dummy
fi
EOF
chmod +x squashfs/usr/sbin/BankixCreateSnapshot.sh

cat > squashfs/excludes << EOF
etc/mtab
home/user/.cache/*
media/*
mnt/*
proc/*
root/.cache/*
sys/*
tmp/*
var/log/*
var/lib/apt/lists/*
run/live/*
usr/lib/live/mount/*
run/user/*
EOF
# <<<<< Snapshot-Funktionalitaet <<<<<



# >>>>> Schnellstart-Icons >>>>>
mkdir squashfs/etc/skel/Desktop/
cat > squashfs/etc/skel/Desktop/BankixCreateSnapshot.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Name=Snapshot erstellen
Exec=/usr/sbin/BankixCreateSnapshot.sh
Type=Application
Terminal=true
Icon=/usr/share/icons/Adwaita/48x48/legacy/document-save.png
EOF
chmod +x squashfs/etc/skel/Desktop/BankixCreateSnapshot.desktop

cp squashfs/usr/share/applications/lxqt-config-monitor.desktop squashfs/etc/skel/Desktop/
cp squashfs/usr/share/applications/firefox-esr.desktop squashfs/etc/skel/Desktop/
# <<<<< Schnellstart-Icons <<<<<

# <<<<<<<<<< System bauen <<<<<<<<<<





# >>>>>>>>>> ISO erzeugen >>>>>>>>>>
cp squashfs/boot/initrd.img-* iso/live/initrd.lz
cp squashfs/boot/vmlinuz-* iso/live/vmlinuz

umount squashfs/dev/pts squashfs/dev squashfs/proc squashfs/sys /mnt

chroot squashfs/ mv /etc/resolv.conf.original /etc/resolv.conf

mksquashfs squashfs iso/live/filesystem.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22
genisoimage -cache-inodes -r -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o live.iso -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot iso

isohybrid -u live.iso
# <<<<<<<<<< ISO erzeugen <<<<<<<<<<
