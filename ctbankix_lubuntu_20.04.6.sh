#!/bin/bash

#	ctbankix-continuation
#	Copyright (C) 2023 ctbankix-continuation-team
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
UBUNTU_VERSION="20.04.6"
KERNEL_CONFIG_FOLDER=debian.hwe-5.15/config
KERNEL_CONFIG=$KERNEL_CONFIG_FOLDER/config.common.ubuntu
KERNEL_CONFIG_ANNOTATIONS=$KERNEL_CONFIG_FOLDER/annotations

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
echo "Bauanleitung - Lubuntu ${UBUNTU_VERSION} 64 Bit"
echo "====================================="
echo
echo "1. Das vorliegende Skript bitte in (L)Ubuntu ${UBUNTU_VERSION} 64 Bit per sudo auf der Kommandozeile/im Terminal ausfuehren."
echo "2. Nach Durchlauf des Skriptes steht ein ISO-Image (live.iso) bereit, dass auf einen USB-Stick gebracht werden muss."
echo "  a) Den USB-Stick (min. 4 GB, besser 8 GB) entsprechend (eine Partition, FAT32) formatieren (bspw. mithilfe der Anwendung 'Laufwerke')."
echo "  b) Das Bootflag des Sticks setzen (bspw. mithilfe der Anwendung 'GParted')."
echo "  c) Das ISO-Image (live.iso) mithilfe der Anwendung 'UNetbootin' auf den Stick bringen (PS: Der Startmedienersteller ermoeglicht keine volle Funktionalitaet des bankix-Systems)."
echo
read -r -p "Das habe ich verstanden. [j/N] " questionResponse
echo 
if [[ $questionResponse != [jJ] ]]
then
	exit
fi

if ! head -1 /etc/issue | grep -q "Ubuntu ${UBUNTU_VERSION}" || ! [ $(getconf LONG_BIT) == '64' ]
then
	echo "Sie benutzen die falsche (L)Ubuntu-Version. Bitte (L)Ubuntu ${UBUNTU_VERSION} 64 Bit verwenden."
	exit
fi
# <<<<<<<<<< Dialog <<<<<<<<<<





# >>>>>>>>>> Kernelbau >>>>>>>>>>

# Quelltext-Paketquelle hinzufügen/aktivieren
add-apt-repository -s "deb http://de.archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-updates main"
apt-get update

# Benoetigte Pakete zum Bauen installieren
apt-get -y build-dep linux
apt-get -y install git fakeroot libncurses-dev gawk flex bison openssl llvm libssl-dev dkms zstd libelf-dev libudev-dev libpci-dev libiberty-dev autoconf systemtap-sdt-dev libzstd-dev libbabeltrace-dev libperl-dev binutils-dev python3-dev clang

# Quellcode des Kernels auschecken und in Verzeichnis wechseln
mkdir -p kernel
cd kernel/
apt-get source linux-image-unsigned-$(uname -r)
cd linux-*/



# >>>>> Quellcode anpassen >>>>>
sed -i '/^static inline unsigned int ata_dev_enabled(const struct ata_device \*dev)/{N;N;N;s/return ata_class_enabled(dev->class);/return dev->class == ATA_DEV_ATAPI;/}' include/linux/libata.h

sed -i '/^CONFIG_BLK_DEV_NVME/d' $KERNEL_CONFIG
sed -i '/^CONFIG_NVME_/d' $KERNEL_CONFIG
sed -i '/^# CONFIG_NVME_/d' $KERNEL_CONFIG

cat >> $KERNEL_CONFIG << EOF
# CONFIG_BLK_DEV_NVME is not set
# CONFIG_NVME_FC is not set
# CONFIG_NVME_RDMA is not set
# CONFIG_NVME_TARGET is not set
# CONFIG_NVME_TCP is not set
EOF

sed -i "/^CONFIG_BLK_DEV_NVME/ s/'[ym-]'/'n'/g" $KERNEL_CONFIG_ANNOTATIONS
sed -i "/^CONFIG_NVME_/ s/'[ym-]'/'n'/g" $KERNEL_CONFIG_ANNOTATIONS
sed -i "/^CONFIG_NVME_TARGET_/ s/'[ymn]'/'-'/g" $KERNEL_CONFIG_ANNOTATIONS
sed -i "/^CONFIG_NVME_HWMON/ s/'[ymn]'/'-'/g" $KERNEL_CONFIG_ANNOTATIONS
sed -i "/^CONFIG_NVME_MULTIPATH/ s/'[ymn]'/'-'/g" $KERNEL_CONFIG_ANNOTATIONS
sed -i "/^CONFIG_BLK_CGROUP_FC_APPID/ s/'[ymn]'/'-'/g" $KERNEL_CONFIG_ANNOTATIONS
# <<<<< Quellcode anpassen <<<<<



# >>>>> Kernel bauen >>>>>
echo; echoDateTime; echo -n " "; echoBoldWhiteOnCyan "Kernel-Build Start"; echo; echo;

LANG=C fakeroot debian/rules clean
LANG=C skipabi=true skipmodule=true fakeroot debian/rules binary-indep
LANG=C skipabi=true skipmodule=true fakeroot debian/rules binary-perarch
LANG=C skipabi=true skipmodule=true fakeroot debian/rules binary-generic

echo; echoDateTime; echo -n " "; echoBoldWhiteOnCyan "Kernel-Build Ende"; echo; echo;
cd ../../
# <<<<< Kernel bauen <<<<<

# <<<<<<<<<< Kernelbau <<<<<<<<<<





# >>>>>>>>>> System bauen >>>>>>>>>>

# Debug-Ausgaben fuer den restlichen Teil des Skripts aktivieren
export PS4='$(CheckExitCodePreviousCommand)\n\n$(echoDateTime) $(echoBoldWhiteOnMagenta "LN: ${LINENO}") $(setTextBold)$(setTextWhite)$(setBackgroundCyan)${BASH_COMMAND}$(resetText)\n'
set -x

# Benoetigte Pakete installieren und aktuelles Lubuntu-ISO herunterladen
apt-get -y install build-essential debootstrap squashfs-tools genisoimage syslinux-common syslinux-utils
wget -c -N -P source https://cdimage.ubuntu.com/lubuntu/releases/focal/release/lubuntu-20.04.5-desktop-amd64.iso

# Mounten und Verzeichnisse kopieren
mount -o loop source/lubuntu-20.04.5-desktop-amd64.iso /mnt/

mkdir iso
cp -r /mnt/.disk/ /mnt/boot/ /mnt/EFI/ iso/
mkdir iso/casper

# Bereits gebautes Live-System des verwendeteten ISOs entpacken
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
chroot squashfs/ locale-gen de_CH.UTF-8

# System schlank machen
chroot squashfs/ apt-get -y purge libreoffice-* trojita* skanlite blue* quassel* transmission-* 2048-qt k3b* vlc* vim* noblenote xscreensaver* snapd fonts-noto-cjk git* oxygen-icon-theme calamares* language-pack* lvm2 apport btrfs* cryptsetup genisoimage xul-ext-ubufox

chroot squashfs/ apt-get -y purge linux-image-* linux-headers-* linux-modules-* 
chroot squashfs/ apt-get -y autoremove --purge

# alle Updates einspielen
chroot squashfs/ apt-get update
chroot squashfs/ apt-get -y upgrade

# Zusaetzliche Pakete einspielen
chroot squashfs/ apt-get -y install tzdata language-pack-de firefox-locale-de squashfs-tools cups wswiss wngerman wogerman aspell-de hunspell-de-de

# Zeitzone setzen
echo "Europe/Berlin" | tee squashfs/etc/timezone
rm squashfs/etc/localtime
chroot squashfs/ ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
chroot squashfs/ dpkg-reconfigure --frontend noninteractive tzdata

# Echtzeituhr: Lokalzeit anstatt UTC verwenden für Dual-Boot mit Windows
echo "0.0 0 0" > squashfs/etc/adjtime
echo "0" >> squashfs/etc/adjtime
echo "LOCAL" >> squashfs/etc/adjtime

# Modifizierten Kernel einspielen
cp kernel/linux*headers*.deb kernel/linux-image*.deb kernel/linux-modules*.deb squashfs/
chroot squashfs/ ls | chroot squashfs/ grep .deb | chroot squashfs/ tr '\n' ' ' | chroot squashfs/ xargs dpkg -i
chroot squashfs/ apt-get -f -y install
rm squashfs/*.deb

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

# Microcodes + Tools nachinstallieren, die durch das Entfernen der linux*-Pakete verloren gegangen sind
chroot squashfs/ apt-get -y install amd64-microcode intel-microcode iucode-tool thermald

# APT + Software-Center aufrauemen
chroot squashfs/ apt-get -y check
chroot squashfs/ apt-get -y autoremove --purge
chroot squashfs/ apt-get -y clean



# >>>>> Firefox-Profile einrichten >>>>>

# Plugins nachladen
wget -O squashfs/usr/lib/firefox-addons/extensions/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi https://addons.mozilla.org/firefox/downloads/latest/noscript/
rm -rf squashfs/usr/lib/firefox/distribution/searchplugins/locale/

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
menu title c't Bankix Lubuntu ${UBUNTU_VERSION}

label ctbankix
  menu label c't Bankix Lubuntu ${UBUNTU_VERSION}
  kernel /casper/vmlinuz
  append BOOT_IMAGE=/casper/vmlinuz boot=casper initrd=/casper/initrd.lz fsck.mode=skip showmounts quiet splash noprompt -- debian-installer/locale=de_DE console-setup/layoutcode=de
  
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

menuentry "c't Bankix Lubuntu ${UBUNTU_VERSION}" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper fsck.mode=skip showmounts quiet splash noprompt -- debian-installer/locale=de_DE console-setup/layoutcode=de
	initrd	/casper/initrd.lz
}
EOF
# <<<<< Boot-Menue <<<<<



# >>>>> Snapshot-Funktionalitaet >>>>>
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
	sudo blockdev --setrw \$(findmnt -n -o SOURCE --mountpoint /cdrom)
	sudo mount -o remount,rw /cdrom
	sudo mksquashfs / /cdrom/casper/filesystem_new.squashfs -ef /excludes -wildcards -comp lz4 -Xhc
	sudo sync -d /cdrom/casper/filesystem_new.squashfs
	sudo rm -f /cdrom/filesystem_old.squashfs
	sudo mv /cdrom/casper/filesystem.squashfs /cdrom/filesystem_old.squashfs
	sudo mv /cdrom/casper/filesystem_new.squashfs /cdrom/casper/filesystem.squashfs
	sudo sync
	sudo mount -o remount,ro /cdrom
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
casper/*
cdrom/*
cow/*
etc/mtab
home/lubuntu/.cache/*
media/*
mnt/*
proc/*
rofs/*
root/.cache/*
sys/*
tmp/*
var/log/*
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
Icon=/usr/share/icons/Humanity/actions/48/document-save.svg
EOF
chmod +x squashfs/etc/skel/Desktop/BankixCreateSnapshot.desktop

cp squashfs/usr/share/applications/lxqt-config-monitor.desktop squashfs/etc/skel/Desktop/
cp squashfs/usr/share/applications/firefox.desktop squashfs/etc/skel/Desktop/
cp squashfs/usr/share/applications/upg-apply.desktop squashfs/etc/skel/Desktop/
# <<<<< Schnellstart-Icons <<<<<

# <<<<<<<<<< System bauen <<<<<<<<<<





# >>>>>>>>>> ISO erzeugen >>>>>>>>>>
cp squashfs/boot/initrd.img-* iso/casper/initrd.lz
cp squashfs/boot/vmlinuz-* iso/casper/vmlinuz

umount squashfs/dev/pts squashfs/dev squashfs/proc squashfs/sys /mnt

#mv squashfs/etc/resolv.conf.orig squashfs/etc/resolv.conf
chroot squashfs/ mv /etc/resolv.conf.original /etc/resolv.conf
chroot squashfs/ mv /etc/apt/sources.list.original /etc/apt/sources.list

mksquashfs squashfs iso/casper/filesystem.squashfs -noappend -comp lz4 -Xhc
genisoimage -cache-inodes -r -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o live.iso -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot iso

isohybrid -u live.iso

# <<<<<<<<<< ISO erzeugen <<<<<<<<<<
