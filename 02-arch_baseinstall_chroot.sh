#!/bin/bash
## INSTALLATION ARCH LINUX - BASE CHROOT
## SYSTEMD INIT - LUKS - BTRFS - UKI - SECURE BOOT
## ./arch_baseinstall_chroot.sh
## By Joan https://github.com/joan31/

set -e

log() {
    echo -e "\e[1;32m[✔] $1 \e[0m"
}

log_step() {
    echo -e "\e[1;34m[➡] $1 \e[0m"
}

log_warn() {
    echo -e "\e[1;33m[⚠] $1 \e[0m"
}

log_error() {
    echo -e "\e[1;31m[✖] $1 \e[0m"
}

# Configuration du clavier
log_step "Configuration du clavier ⌨️"
echo "KEYMAP=fr" > /etc/vconsole.conf
echo "FONT=lat9w-16" >> /etc/vconsole.conf
log "Clavier configuré en français ✅"

# Configuration locale
log_step "Configuration locale 🌍"
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf
echo "LC_MESSAGES=en_US.UTF-8" >> /etc/locale.conf
log "Fichier locale.conf mis à jour ✅"

# Activation des locales
log_step "Activation des locales 🛠️"
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(fr_FR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
log "Locales générées avec succès ✅"

# Activation du verrouillage numérique en tty
log_step "Activation du verrouillage numérique 🔢"
mkdir -p /etc/systemd/system/getty@.service.d
echo "[Service]" > /etc/systemd/system/getty@.service.d/activate-numlock.conf
echo "ExecStartPre=/bin/sh -c 'setleds -D +num < /dev/%I'" \
>> /etc/systemd/system/getty@.service.d/activate-numlock.conf
log "NumLock activé au démarrage ✅"

# Configuration du nom de la machine
log_step "Configuration du nom de la machine 🏠"
echo "lianli-arch" > /etc/hostname
log "Hostname défini à lianli-arch ✅"

# Configuration des hôtes
log_step "Configuration des hôtes 🖧"
cat <<EOF >> /etc/hosts
127.0.0.1           localhost
::1                 localhost
192.168.1.101       lianli-arch.zenitram        lianli-arch
EOF
log "Fichier hosts mis à jour ✅"

# Configuration du fuseau horaire
log_step "Configuration du fuseau horaire 🕰️"
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
log "Fuseau horaire défini à Europe/Paris ✅"

# Configuration mkinitcpio
log_step "Configuration de mkinitcpio ⚙️"
sed -i 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems)/' /etc/mkinitcpio.conf
log "mkinitcpio configuré ✅"

# Configuration systemd-cryptsetup pour l'initramfs
log_step "Configuration de systemd-cryptsetup 🔐"
echo "cryptarch     UUID=$(lsblk -dno UUID /dev/nvme0n1p2)      none        tpm2-device=auto,password-echo=no,x-systemd.device-timeout=0,timeout=0,no-read-workqueue,no-write-workqueue,discard" \
> /etc/crypttab.initramfs
log "crypttab.initramfs mis à jour ✅"

# Configuration de la ligne de commande du noyau
log_step "Configuration de la ligne de commande du noyau 🚀"
mkdir -p /etc/cmdline.d
echo "root=/dev/mapper/cryptarch rootfstype=btrfs rootflags=subvol=@ ro loglevel=3" > /etc/cmdline.d/01-root.conf
echo "zswap.enabled=1 zswap.max_pool_percent=20 zswap.zpool=zsmalloc zswap.compressor=zstd zswap.accept_threshold_percent=90" > /etc/cmdline.d/02-zswap.conf
log "Ligne de commande du noyau définie ✅"

# Configuration du preset mkinitcpio pour générer UKI 🛠️
log_step "Configuration du preset mkinitcpio pour UKI 🚀"
sed -i \
    -e "s/^PRESETS=('default' 'fallback')/PRESETS=('default')/" \
    -e "s/^default_image=/#default_image=/" \
    -e "s/^#default_uki=/default_uki=/" \
    -e "s/^#default_options=/default_options=/" \
    -e "s/^fallback_image=/#fallback_image=/" \
    -e "s/^fallback_options=/#fallback_options=/" \
    /etc/mkinitcpio.d/linux.preset
log "Preset mkinitcpio configuré avec succès ✅"

# Ajout de la clé LUKS au TPM2
log_step "Ajout de la clé LUKS au TPM2 🔑"
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
log "Clé LUKS enregistrée dans le TPM2 ✅"

# Configuration Secure Boot
log_step "Configuration de Secure Boot 🛡️"
sbctl create-keys
sbctl enroll-keys -m
log "Secure Boot configuré et clés enregistrées ✅"

# Génération de l'image du noyau
log_step "Génération de l'image du noyau 🏗️"
mkdir -p /efi/EFI/Linux
mkinitcpio -p linux
log "Image du noyau générée avec succès ✅"

# Création de l'entrée EFI
log_step "Création et ordonnancement des entrées EFI ⚙️"
efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Arch Linux" --loader /EFI/Linux/arch-linux.efi --unicode
log "Entrée EFI créée avec succès ✅"

# Configuration de la swap
log_step "Configuration du swap 💤"
echo "vm.swappiness=20" > /etc/sysctl.d/99-swappiness.conf
echo "swap    /.swap/swapfile       /dev/urandom        swap,cipher=aes-xts-plain64,sector-size=4096" > /etc/crypttab
echo "/dev/mapper/swap      none        swap        defaults    0 0" >> /etc/fstab
log "Swap configuré ✅"

# Activation du dépôt multilib et configuration pacman
log_step "Configuration de pacman 📦"
sed -i \
    -e "s/^#NoExtract   =/NoExtract   = etc\/cron.daily\/snapper etc\/cron.hourly\/snapper/" \
    -e "s/^#Color/Color/" \
    -e "/^Color/a ILoveCandy" \
    -e "s/^ParallelDownloads = [0-9]\+/ParallelDownloads = 10/" \
    -e "s/^#\[multilib\]/[multilib]/" \
    -e "s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/" \
    /etc/pacman.conf
log "Pacman configuré ✅"

# Configuration du réseau 🌐
log_step "Configuration du réseau filaire 📡"
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=eno* ens* enp* eth*

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
MulticastDNS=yes

[DHCPv4]
RouteMetric=100

[IPv6AcceptRA]
RouteMetric=100
EOF
log "Réseau filaire configuré correctement ✅"

# Installation des paquets nécessaires 📦
log_step "Installation des paquets essentiels 🔧"
pacman -Syy --noconfirm bluez snapper pacman-contrib reflector
log "Paquets installés avec succès ✅"

# Configuration NTP 🕰️
log_step "Configuration des serveurs NTP pour la synchronisation de l'heure ⏳"
sed -i \
    -e '/^NTP=/c\NTP=0.fr.pool.ntp.org 1.fr.pool.ntp.org 2.fr.pool.ntp.org 3.fr.pool.ntp.org' \
    -e 's/^#FallbackNTP=/FallbackNTP=/' \
    /etc/systemd/timesyncd.conf
log "Serveurs NTP configurés ✅"

# Règles pour le NVMe 🚀
log_step "Configuration du planificateur pour les disques NVMe 💽"
echo 'ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-schedulers.rules
log "Règles NVMe appliquées avec succès ✅"

# Configuration DNS stub resolv 🌍
log_step "Configuration du DNS stub resolv 🔗"
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
log "DNS stub resolv configuré avec succès ✅"

# Configuration Reflector 🇫🇷🇩🇪🇳🇱
log_step "Configuration de Reflector pour les pays 🇫🇷🇩🇪🇳🇱"
sed -i 's/^# --country France,Germany/--country France,Germany,Netherlands/' /etc/xdg/reflector/reflector.conf
log "Configuration de Reflector appliquée ✅"

# Activation des services systemd
log_step "Activation des services systemd 🛠️"
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable bluetooth.service
systemctl enable systemd-timesyncd.service
systemctl enable paccache.timer
systemctl enable reflector.timer
systemctl mask systemd-gpt-auto-generator
log "Services activés ✅"

# Configuration sudo
elog_step "Configuration de sudo 🔑"
sed -i 's/^# \(%wheel ALL=(ALL) ALL\)/\1/' /etc/sudoers
log "Sudo configuré ✅"

# Optimisation de la compilation 🛠️
log_step "Optimisation de la compilation pour de meilleures performances 🚀"

# Configuration de /etc/makepkg.conf
log_step "Mise à jour des options de compilation dans /etc/makepkg.conf 📝"
sed -i \
    -e 's|^CFLAGS="-march=x86-64 -mtune=generic|CFLAGS="-march=native|' \
    -e 's|^#MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|' \
    -e 's|^#BUILDDIR=.*|BUILDDIR=/tmp/makepkg|' \
    /etc/makepkg.conf
log "Configuration de makepkg.conf optimisée ✅"

# Configuration de /etc/makepkg.conf.d/rust.conf
log_step "Optimisation de la compilation Rust 🦀"
sed -i \
    -e 's|^RUSTFLAGS=".*|RUSTFLAGS="-C opt-level=2 -C target-cpu=native"|' \
    /etc/makepkg.conf.d/rust.conf
log "Configuration Rust optimisée ✅"

# Désactivation audio HDMI
log_step "Désactivation de l'audio HDMI 🎧"
echo "blacklist snd_hda_intel" > /etc/modprobe.d/blacklist.conf
log "Audio HDMI désactivé ✅"

# Désactivation microphone webcam
log_step "Désactivation du microphone webcam 📹"
echo 'SUBSYSTEM=="usb", DRIVER=="snd-usb-audio", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="085c", ATTR{authorized}="0"' > /etc/udev/rules.d/90-blacklist-webcam-sound.rules
log "Microphone webcam désactivé ✅"

# Définition du mot de passe root
log_step "Définition du mot de passe root 🔑"
passwd root
log "Mot de passe root défini ✅"

# Sortie du chroot
log_step "Sortie du chroot 🚪"
log "Installation terminée avec succès 🎉"
exit