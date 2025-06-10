#!/bin/bash
## ARCH LINUX INSTALLATION - BASE CHROOT
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

# Keyboard configuration
log_step "Keyboard configuration ⌨️"
echo "KEYMAP=fr" > /etc/vconsole.conf
echo "FONT=lat9w-16" >> /etc/vconsole.conf
log "Keyboard set to French ✅"

# Locale configuration
log_step "Locale configuration 🌍"
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf
echo "LC_MESSAGES=en_US.UTF-8" >> /etc/locale.conf
log "locale.conf file updated ✅"

# Enable locales
log_step "Enabling locales 🛠️"
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(fr_FR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
log "Locales successfully generated ✅"

# Enable NumLock on TTY
log_step "Enabling NumLock 🔢"
mkdir -p /etc/systemd/system/getty@.service.d
echo "[Service]" > /etc/systemd/system/getty@.service.d/activate-numlock.conf
echo "ExecStartPre=/bin/sh -c 'setleds -D +num < /dev/%I'" \
>> /etc/systemd/system/getty@.service.d/activate-numlock.conf
log "NumLock enabled at boot ✅"

# Hostname configuration
log_step "Setting hostname 🏠"
echo "lianli-arch" > /etc/hostname
log "Hostname set to lianli-arch ✅"

# Hosts configuration
log_step "Hosts configuration 🖧"
cat <<EOF >> /etc/hosts
127.0.0.1           localhost
::1                 localhost
192.168.1.101       lianli-arch.zenitram        lianli-arch
EOF
log "Hosts file updated ✅"

# Timezone configuration
log_step "Timezone configuration 🕰️"
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
log "Timezone set to Europe/Paris ✅"

# mkinitcpio configuration
log_step "Configuring mkinitcpio ⚙️"
sed -i 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems)/' /etc/mkinitcpio.conf
log "mkinitcpio configured ✅"

# systemd-cryptsetup config for initramfs
log_step "Configuring systemd-cryptsetup 🔐"
echo "cryptarch     UUID=$(lsblk -dno UUID /dev/nvme0n1p2)      none        tpm2-device=auto,password-echo=no,x-systemd.device-timeout=0,timeout=0,no-read-workqueue,no-write-workqueue,discard" \
> /etc/crypttab.initramfs
log "crypttab.initramfs updated ✅"

# Kernel command line configuration
log_step "Kernel command line configuration 🚀"
mkdir -p /etc/cmdline.d
echo "root=/dev/mapper/cryptarch rootfstype=btrfs rootflags=subvol=@ ro loglevel=3" > /etc/cmdline.d/01-root.conf
echo "zswap.enabled=1 zswap.max_pool_percent=20 zswap.zpool=zsmalloc zswap.compressor=zstd zswap.accept_threshold_percent=90" > /etc/cmdline.d/02-zswap.conf
log "Kernel command line set ✅"

# mkinitcpio preset for UKI
log_step "Configuring mkinitcpio preset for UKI 🚀"
sed -i \
    -e "s/^PRESETS=('default' 'fallback')/PRESETS=('default')/" \
    -e "s/^default_image=/#default_image=/" \
    -e "s/^#default_uki=/default_uki=/" \
    -e "s/^#default_options=/default_options=/" \
    -e "s/^fallback_image=/#fallback_image=/" \
    -e "s/^fallback_options=/#fallback_options=/" \
    /etc/mkinitcpio.d/linux.preset
log "mkinitcpio preset configured successfully ✅"

# Add LUKS key to TPM2
log_step "Adding LUKS key to TPM2 🔑"
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
log "LUKS key enrolled in TPM2 ✅"

# Secure Boot configuration
log_step "Secure Boot configuration 🛡️"
sbctl create-keys
sbctl enroll-keys -m
log "Secure Boot configured and keys enrolled ✅"

# Kernel image generation
log_step "Generating kernel image 🏗️"
mkdir -p /efi/EFI/Linux
mkinitcpio -p linux
log "Kernel image generated successfully ✅"

# EFI entry creation
log_step "Creating and ordering EFI entries ⚙️"
efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Arch Linux" --loader /EFI/Linux/arch-linux.efi --unicode
log "EFI entry created successfully ✅"

# Swap configuration
log_step "Configuring swap 💤"
echo "vm.swappiness=20" > /etc/sysctl.d/99-swappiness.conf
echo "swap    /.swap/swapfile       /dev/urandom        swap,cipher=aes-xts-plain64,sector-size=4096" > /etc/crypttab
echo "/dev/mapper/swap      none        swap        defaults    0 0" >> /etc/fstab
log "Swap configured ✅"

# Enable multilib and pacman config
log_step "Pacman configuration 📦"
sed -i \
    -e "s/^#NoExtract   =/NoExtract   = etc\/cron.daily\/snapper etc\/cron.hourly\/snapper/" \
    -e "s/^#Color/Color/" \
    -e "/^Color/a ILoveCandy" \
    -e "s/^ParallelDownloads = [0-9]\+/ParallelDownloads = 10/" \
    -e "s/^#\[multilib\]/[multilib]/" \
    -e "s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/" \
    /etc/pacman.conf
log "Pacman configured ✅"

# Network configuration 🌐
log_step "Wired network configuration 📡"
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
log "Wired network configured correctly ✅"

# Install required packages 📦
log_step "Installing essential packages 🔧"
pacman -Syy --noconfirm bluez snapper pacman-contrib reflector
log "Packages installed successfully ✅"

# NTP configuration 🕰️
log_step "Configuring NTP servers for time sync ⏳"
sed -i \
    -e '/^NTP=/c\NTP=0.fr.pool.ntp.org 1.fr.pool.ntp.org 2.fr.pool.ntp.org 3.fr.pool.ntp.org' \
    -e 's/^#FallbackNTP=/FallbackNTP=/' \
    /etc/systemd/timesyncd.conf
log "NTP servers configured ✅"

# NVMe rules 🚀
log_step "Configuring scheduler for NVMe disks 💽"
echo 'ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-schedulers.rules
log "NVMe rules successfully applied ✅"

# DNS stub resolver config 🌍
log_step "Configuring DNS stub resolver 🔗"
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
log "DNS stub resolver configured ✅"

# Reflector configuration 🇫🇷🇩🇪🇳🇱
log_step "Reflector configuration for countries 🇫🇷🇩🇪🇳🇱"
sed -i 's/^# --country France,Germany/--country France,Germany,Netherlands/' /etc/xdg/reflector/reflector.conf
log "Reflector configuration applied ✅"

# Enable systemd services
log_step "Enabling systemd services 🛠️"
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable bluetooth.service
systemctl enable systemd-timesyncd.service
systemctl enable paccache.timer
systemctl enable reflector.timer
systemctl mask systemd-gpt-auto-generator
log "Services enabled ✅"

# Sudo configuration
elog_step "Sudo configuration 🔑"
sed -i 's/^# \(%wheel ALL=(ALL) ALL\)/\1/' /etc/sudoers
log "Sudo configured ✅"

# Build optimization 🛠️
log_step "Build optimization for better performance 🚀"

# Update /etc/makepkg.conf
log_step "Updating compile options in /etc/makepkg.conf 📝"
sed -i \
    -e 's|^CFLAGS="-march=x86-64 -mtune=generic|CFLAGS="-march=native|' \
    -e 's|^#MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|' \
    -e 's|^#BUILDDIR=.*|BUILDDIR=/tmp/makepkg|' \
    /etc/makepkg.conf
log "makepkg.conf optimized ✅"

# Rust compilation optimization
log_step "Rust compilation optimization 🦀"
sed -i \
    -e 's|^RUSTFLAGS=".*|RUSTFLAGS="-C opt-level=2 -C target-cpu=native"|' \
    /etc/makepkg.conf.d/rust.conf
log "Rust configuration optimized ✅"

# Disable HDMI audio
log_step "Disabling HDMI audio 🎧"
echo "blacklist snd_hda_intel" > /etc/modprobe.d/blacklist.conf
log "HDMI audio disabled ✅"

# Disable webcam mic
log_step "Disabling webcam microphone 📹"
echo 'SUBSYSTEM=="usb", DRIVER=="snd-usb-audio", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="085c", ATTR{authorized}="0"' > /etc/udev/rules.d/90-blacklist-webcam-sound.rules
log "Webcam microphone disabled ✅"

# Set root password
log_step "Setting root password 🔑"
passwd root
log "Root password set ✅"

# Exit chroot
log_step "Exiting chroot 🚪"
log "Installation successfully completed 🎉"
exit
