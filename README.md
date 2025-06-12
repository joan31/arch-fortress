# 🏰 Arch Fortress — Secure & Minimal Arch Linux Installer

![Linux](https://img.shields.io/badge/OS-Linux-black?style=flat-square&logo=linux&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Distro-Arch-blue?style=flat-square&logo=arch-linux)
![EFI](https://img.shields.io/badge/Firmware-EFI-white?style=flat-square&logo=rocket&logoColor=white)
![UKI](https://img.shields.io/badge/Boot-UKI-purple?style=flat-square&logo=linuxfoundation&logoColor=white)
![LUKS2 + TPM2](https://img.shields.io/badge/Encryption-LUKS2%20%2B%20TPM2-orange?style=flat-square&logo=cryptpad&logoColor=white)
![Secure Boot](https://img.shields.io/badge/Secure%20Boot-Enabled-teal?style=flat-square&logo=socket&logoColor=white)
![BTRFS](https://img.shields.io/badge/Filesystem-BTRFS-deepskyblue?style=flat-square&logo=buffer&logoColor=white)
![Systemd](https://img.shields.io/badge/Init-Systemd-slateblue?style=flat-square&logo=circle&logoColor=white)
![Zswap](https://img.shields.io/badge/Zswap-Enabled-limegreen?style=flat-square&logo=cashapp&logoColor=white)
![Snapper](https://img.shields.io/badge/Snapper-Enabled-darkslategray?style=flat-square&logo=simpleicons&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square&logo=open-source-initiative)](LICENSE)

**Arch Fortress** is a lightweight, secure, modern and efficient Arch Linux installation framework.

It aims to provide a **solid base system** for advanced users who want a clean, fully encrypted system using modern technologies — **without unnecessary components** like GRUB or classic init hooks.

> 🛡️ Built on: **EFI**, **UKI**, **LUKS2 + TPM2**, **Secure Boot**, **BTRFS**, **Systemd init**, **zswap**, **snapper**

---

## 📚 Table of Contents

- [🎯 Overview](#-overview)
- [⚙️ Features](#️-features)
- [📦 Project Structure](#-project-structure)
- [🗂️ Disk Layout & Subvolume Architecture](#️-disk-layout--subvolume-architecture)
- [🔧 Mount Options Summary](#-mount-options-summary)
- [🚀 Automatic Installation (WIP)](#-automatic-installation-wip)
- [📖 Manual Installation (Step-by-step)](#-manual-installation-step-by-step)
- [❓ FAQ](#-faq)
- [🛠 Requirements](#-requirements)
- [📜 License](#-license)
- [👤 Author](#-author)

---

## 🎯 Overview

Arch Fortress is not a distribution or a preconfigured Arch setup — it’s a **bare-metal bootstrapper** that gives you a production-ready system.
A fully modern, encrypted and bootloader-less Arch Linux installation with:

- 🧊 **BTRFS** root with subvolumes and **snapper** for snapshot management
- 🔐 **LUKS2 encryption** for root with **TPM2** auto-unlocking and passphrase fallback
- 💾 Encrypted **swap file**
- 🔁 **Direct EFI boot** via a signed **Unified Kernel Image (UKI)** — no bootloader (no GRUB, no systemd-boot)
- 💥 Full **Secure Boot** support
- 🧠 Modern `mkinitcpio` using **systemd init hooks**
- 🧵 **zswap** for compressed RAM swapping
- 🛟 Auto-backup of EFI partition in `/.efibck`

---

## ⚙️ Features

### 🔐 Security
- Full `/` system encryption with **LUKS2 + TPM2**
- Fallback passphrase support
- Secure Boot ready with signed kernels

### 🧊 Filesystem
- **BTRFS** with subvolumes:
  - `@`, `@home`, `@snapshots`, etc.
- Snapshots for root only, managed by **snapper**
- Encrypted **swap file** on BTRFS
- **zswap** enabled for better memory performance

### ⚙️ Boot Process
- **No bootloader** (no GRUB, no systemd-boot)
- EFI directly loads a **signed Unified Kernel Image (UKI)**
- UKI built with `mkinitcpio`, containing:
  - Kernel
  - Initramfs
  - Kernel cmdline

### 🧠 Init System
- `mkinitcpio` using:
  - `systemd`, `sd-vconsole`, `sd-encrypt`, `sd-shutdown`
- No legacy hooks like `udev`, `usr`, `resume`, `keymap`, `consolefont`, `encrypt`
- Faster, cleaner, future-proof boot

### 🛟 Automatic EFI Backup
- The `/efi` (ESP) is automatically backed up to `/.efibck`
- Useful for system recovery

---

## 📦 Project Structure

```
arch-fortress/
├── install.sh  # Main script to be run from the Arch ISO
├── LICENSE
└── README.md
```

---

## 🗂️ Disk Layout & Subvolume Architecture

> This is the storage layout used by **Arch Fortress**, based on a secure and flexible setup combining LUKS2, BTRFS, and EFI boot with UKI.

### 💽 Partition Table (GPT - `/dev/nvme0n1`)

| Partition        | Type              | FS    | Mount Point | Size | Description                         |
|------------------|-------------------|-------|-------------|------|-------------------------------------|
| `/dev/nvme0n1p1` | EFI System (ef00) | FAT32 | `/efi`      | 500M | EFI System Partition (boot via UKI) |
| `/dev/nvme0n1p2` | Linux LUKS (8309) | LUKS2 | (LUKS)      | ~2TB | Encrypted root volume               |

---

### 🔐 Encrypted Volume

- `/dev/nvme0n1p2` is encrypted using **LUKS2 + TPM2**
- Mapped as `/dev/mapper/cryptarch`
- Inside: **BTRFS** filesystem with multiple subvolumes

---

### 🌳 BTRFS Subvolume Layout

| Subvolume    | Mount Point               | Description                       |
|--------------|---------------------------|-----------------------------------|
| `@`          | `/`                       | Root system                       |
| `@home`      | `/home`                   | User data                         |
| `@pkg`       | `/var/cache/pacman/pkg`   | Pacman cache                      |
| `@log`       | `/var/log`                | System logs                       |
| `@tmp`       | `/var/tmp`                | Temporary files                   |
| `@srv`       | `/srv`                    | Server data                       |
| `@vms`       | `/var/lib/libvirt/images` | Virtual machines                  |
| `@games`     | `/opt/games`              | Optional game data                |
| `@swap`      | `/.swap`                  | Encrypted swapfile (e.g. 4GB)     |
| `@snapshots` | `/.snapshots`             | Snapper snapshots                 |
| `@efibck`    | `/.efibackup`             | EFI partition backups (automated) |

---

🧠 This structure is designed for:
- Granular snapshotting with `snapper`
- Easy backup & restore
- Separation of concerns (logs, cache, VMs, etc.)
- Improved performance & maintenance

---

### 🖼️ Layout Diagram

```
Disk: /dev/nvme0n1 (GPT)
┌──────────────────────────────────────────────────┐
│ Partition Table                                  │
│──────────────────────────────────────────────────│
│ /dev/nvme0n1p1   → EFI System (FAT32, 500M)      │
│                  └── Mounted at /efi             │
│                                                  │
│ /dev/nvme0n1p2   → LUKS2 Encrypted Volume (~2TB) │
│                  └── mapper/cryptarch            │
│                      └── BTRFS filesystem        │
└──────────────────────────────────────────────────┘
```

BTRFS Subvolumes (inside /dev/mapper/cryptarch):

```
┌────────────────────────────────────────────────────────────────────────┐
│ @           → /                                      ← Root filesystem │
│ @home       → /home                                                    │
│ @log        → /var/log                                                 │
│ @tmp        → /var/tmp                                                 │
│ @srv        → /srv                                                     │
│ @pkg        → /var/cache/pacman/pkg                                    │
│ @vms        → /var/lib/libvirt/images                                  │
│ @games      → /opt/games                                               │
│ @snapshots  → /.snapshots                                ← For Snapper │
│ @efibck     → /.efibackup                                ← EFI backups │
│ @log        → /var/log                                                 │
│ @swap       → /.swap                    ← Encrypted swapfile (e.g. 4G) │
└────────────────────────────────────────────────────────────────────────┘
```
Boot process:

```
[ EFI Firmware ]
    ↓
[ UKI Image (.efi) in /efi ]
    ↓
[ systemd (init) in initramfs ]
    ↓
[ Unlock LUKS via TPM2 ]
    ↓
[ Mount BTRFS subvolumes ]
    ↓
[ Boot into secure, modern Arch Fortress 🔐🛡️ ]
```

---

## 🔧 Mount Options Summary

### 📂 Mount Points and Options

| 📍 Mount Point | 💽 Device | 🗂️ Subvolume | ⚙️ Mount Options |
|---|---|---|---|
| `/` | `/dev/mapper/cryptarch` | `@` | `rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/efi` | `/dev/nvme0n1p1` | *(N/A)* | `rw,noatime,nodiratime,nodev,nosuid,noexec,fmask=0022,dmask=0022` |
| `/.swap` | `/dev/mapper/cryptarch` | `@swap` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/.snapshots` | `/dev/mapper/cryptarch` | `@snapshots` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/.efibackup` | `/dev/mapper/cryptarch` | `@efibck` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/var/log` | `/dev/mapper/cryptarch` | `@log` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/var/tmp` | `/dev/mapper/cryptarch` | `@tmp` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/var/cache/pacman/pkg` | `/dev/mapper/cryptarch` | `@pkg` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/var/lib/libvirt/images` | `/dev/mapper/cryptarch` | `@vms` | `rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/home` | `/dev/mapper/cryptarch` | `@home` | `rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/srv` | `/dev/mapper/cryptarch` | `@srv` | `rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |
| `/opt/games` | `/dev/mapper/cryptarch` | `@games` | `rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120` |

---

### 📖 Mount Options Explanation

| ⚙️ Option | 🔎 Description | 🏷️ Category |
|---|---|---|
| `rw` | Mount as read-write. | 🔧 Default |
| `noatime` | Do not update file access times (improves performance, reduces SSD writes). | 🚀 Performance |
| `nodiratime` | Do not update directory access times (even more efficient than `noatime`). | 🚀 Performance |
| `nodev` | Prevents character/block device files from being interpreted (security hardening). | 🔒 Security |
| `nosuid` | Disable set-user-ID and set-group-ID bits (security hardening). | 🔒 Security |
| `noexec` | Prevent execution of binaries on this mount (security hardening). | 🔒 Security |
| `fmask=0022` | File mask for default file permissions on FAT32 (755 for files). | 🔒 Security |
| `dmask=0022` | Directory mask for default directory permissions on FAT32 (755 for dirs). | 🔒 Security |
| `compress=zstd:3` | Use Zstandard compression (level 3: good balance between speed and compression ratio). | 💾 Performance/Storage |
| `ssd` | Optimize for SSD (disables unnecessary spinning disk optimizations). | 🚀 Performance |
| `discard=async` | Asynchronous TRIM: notify SSD of free blocks asynchronously (less I/O overhead). | 💾 Performance |
| `space_cache=v2` | Improved Btrfs space cache version 2 (better mount speed, reliability). | 🚀 Performance |
| `commit=120` | Flush changes to disk every 120s (reduces write amplification). | 💾 Performance |
| `subvol=@...` | Mount specific Btrfs subvolume. | 📂 Btrfs Feature |

---

### 🔎 Why these mount options?

These options are carefully chosen for:

- 🚀 **Performance**: optimized for SSDs and minimizing unnecessary I/O.
- 🔒 **Security**: limiting execution and device files where not needed.
- 💾 **Reliability**: with Btrfs improvements (`space_cache=v2`, `commit=120`).
- 📂 **Granular subvolume management**: easy snapshot, rollback, backup management.

---

### ✅ Quick Summary

| 🎯 Aspect | ⚙️ Strategy |
|---|---|
| SSD optimization | `ssd`, `discard=async` |
| Reduce writes | `noatime`, `nodiratime`, `commit=120` |
| Compression | `compress=zstd:3` |
| Security hardening | `nosuid`, `nodev`, `noexec` |
| Faster mounts | `space_cache=v2` |
| Granular control | Subvolumes (`@home`, `@swap`, `@log`...) |

---

**✅ READY FOR PRODUCTION 🖥️**

---

## 🚀 Automatic Installation (WIP)

> 🧪 Coming soon: Full auto-install script with configuration prompts or flags.

> ⚠️ **Secure Boot must be set to "Setup Mode" in the BIOS/UEFI before installation.**  
> This is required to enroll your own Secure Boot keys with `sbctl`.

Planned workflow:

1. Boot from Arch ISO (UEFI)
2. Download and run:
   ```bash
   curl -LO https://raw.githubusercontent.com/joan31/arch-fortress/main/install.sh
   chmod +x install.sh
   sudo ./install.sh
   ```
3. The script will:
  - Partition the disk
  - Setup encryption, filesystems, mount points
  - Install base system
  - Chroot
  - Generate and sign UKI, configure EFI boot entries

---

## 📖 Manual Installation (Step-by-step)

> 🧠 For advanced users or educational purposes.

> ⚠️ **Secure Boot must be set to "Setup Mode" in the BIOS/UEFI before installation.**  
> This is required to enroll your own Secure Boot keys with `sbctl`.

This section will provide all individual shell commands used in the installation, including:

- 🧱 Partitioning & formatting
- 🔐 LUKS2 setup with TPM2
- 🗂️ Mounting and subvolume layout
- 📦 Base system installation
- 🧰 Chroot configuration
- 🧬 UKI creation and signing
- ⚙️ EFI setup
- 🧊 Snapper configuration
- 🌀 Swap and zswap activation

### 🧱 Step 1 — Pre-Installation Setup

```bash
# ⌨️ (Optional) Set keyboard layout to French
loadkeys fr

# 🧼 Clean existing EFI entries if needed (replace X with the entry number)
efibootmgr
efibootmgr -b X -B

# 🔐 Update GPG keys from live environment (recommended before installing)
pacman -Sy archlinux-keyring
```

### 💽 Step 2 — Disk Partitioning (GPT)

```bash
# ⚙️ Partition the disk: EFI (500MB) + LUKS root (rest of disk)
sgdisk --clear --align-end \
  --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI system partition" \
  --new=2:0:0 --typecode=2:8309 --change-name=2:"Linux LUKS" \
  /dev/nvme0n1
```

### 🧼 Step 3 — Filesystem Creation

```bash
# 🧴 Format EFI partition (optimized for NVMe 4K sector size)
mkfs.vfat -F 32 -n "SYSTEM" -S 4096 -s 1 /dev/nvme0n1p1

# 🔐 Create LUKS2 encrypted container with strong encryption options
cryptsetup --type luks2 --cipher aes-xts-plain64 --hash sha512 \
  --iter-time 5000 --key-size 512 --pbkdf argon2id \
  --label "Linux LUKS" --sector-size 4096 --use-urandom \
  --verify-passphrase luksFormat /dev/nvme0n1p2

# 🔓 Open the LUKS container as /dev/mapper/cryptarch
cryptsetup --allow-discards --persistent open --type luks2 \
  /dev/nvme0n1p2 cryptarch

# 🧊 Format the unlocked LUKS volume with BTRFS (4K sectors)
mkfs.btrfs -L "Arch Linux" -s 4096 /dev/mapper/cryptarch
```

### 🌳 Step 4 — BTRFS Subvolume Layout

```bash
# 🪵 Mount the root BTRFS volume temporarily
mount -o rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120 \
  /dev/mapper/cryptarch /mnt

# 📂 Create BTRFS subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@efibck
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@vms
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@games

# 🔓 Unmount the volume before remounting subvolumes individually
umount /mnt
```

### 🛠️ Step 5 — Mount Subvolumes & Prepare System

```bash
# 🔧 Mount root subvolume
mount -o rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@ \
  /dev/mapper/cryptarch /mnt

# 🗂️ Create necessary mount points
mkdir -p /mnt/{efi,.swap,.snapshots,.efibackup,var/{log,tmp,cache/pacman/pkg,lib/libvirt/images},home,srv,opt/games}

# 🖥️ Mount EFI system partition (read-only, noexec for safety)
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,fmask=0022,dmask=0022 \
  /dev/nvme0n1p1 /mnt/efi

# 🧷 Mount other BTRFS subvolumes
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@swap /dev/mapper/cryptarch /mnt/.swap
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@snapshots /dev/mapper/cryptarch /mnt/.snapshots
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@efibck /dev/mapper/cryptarch /mnt/.efibackup
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@log /dev/mapper/cryptarch /mnt/var/log
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@tmp /dev/mapper/cryptarch /mnt/var/tmp
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@pkg /dev/mapper/cryptarch /mnt/var/cache/pacman/pkg
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@vms /dev/mapper/cryptarch /mnt/var/lib/libvirt/images
mount -o rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@home /dev/mapper/cryptarch /mnt/home
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@srv /dev/mapper/cryptarch /mnt/srv
mount -o rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@games /dev/mapper/cryptarch /mnt/opt/games
```

### 💾 Step 6 — Create Swap File

```bash
# 🛏️ Create 4GB swap file on BTRFS subvolume
btrfs filesystem mkswapfile --size 4g /mnt/.swap/swapfile
chmod 600 /mnt/.swap/swapfile
```

### 📦 Step 7 — Install Base System

```bash
# 🧱 Install base packages + firmware, EFI tools, btrfs support, text editor and secure boot tools
pacstrap /mnt \
  base base-devel linux linux-firmware amd-ucode \
  neovim efibootmgr btrfs-progs sbctl
```

### 🗂️ Step 8 — Generate fstab

```bash
# 📄 Generate fstab with UUIDs
genfstab -U /mnt >> /mnt/etc/fstab

# 🔍 (Optional) Review fstab and check "0 1" to enable fsck on /
nvim /mnt/etc/fstab

# Content:
UUID=<BTRFS-UUID-PARTITION>      /      btrfs      rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=/@      0 1
```

### 🚪 Step 9 — Enter Chroot

```bash
# 🌀 Change root into new system
arch-chroot /mnt
```

### 🌐 Step 10 — Keyboard & Locale Configuration

```bash
# ⌨️ Set virtual console keyboard to French
nvim /etc/vconsole.conf

# Content:
KEYMAP=fr
FONT=lat9w-16

# 🌍 Set system-wide locale
nvim /etc/locale.conf

# Content:
LANG=fr_FR.UTF-8
LC_COLLATE=C
LC_MESSAGES=en_US.UTF-8

# 🔓 Enable required locales
nvim /etc/locale.gen

# Uncomment:
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8

# ⚙️ Generate locale definitions
locale-gen
```

### 🔢 Step 11 — TTY Behavior (Enable NumLock)

```bash
# 🧷 Create drop-in to activate NumLock automatically on TTY login
mkdir /etc/systemd/system/getty@.service.d
nvim /etc/systemd/system/getty@.service.d/activate-numlock.conf

# Content:
[Service]
ExecStartPre=/bin/sh -c 'setleds -D +num < /dev/%I'
```

### 🖥️ Step 12 — Host Identity Configuration

```bash
# 🏷️ Set system hostname
nvim /etc/hostname

# Content:
lianli-arch

# 🧭 Set hosts file entries for local networking
nvim /etc/hosts

# Content:
127.0.0.1      localhost
::1            localhost
192.168.1.101  lianli-arch.zenitram lianli-arch
```

### 🕒 Step 13 — Timezone & Clock Setup

```bash
# 🌍 Set system timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# ⏱️ Sync hardware clock with system time
hwclock --systohc
```

### 🧩 Step 14 — Initramfs Configuration (Systemd, LUKS, Keyboard)

```bash
# ⚙️ Edit initramfs hooks to include systemd & encryption
nvim /etc/mkinitcpio.conf

# Content:
HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems sd-shutdown)

# 🔐 Setup encrypted volume for systemd to unlock via TPM2
nvim /etc/crypttab.initramfs

# Content:
cryptarch UUID=<nvme-UUID> none tpm2-device=auto,password-echo=no,x-systemd.device-timeout=0,timeout=0,no-read-workqueue,no-write-workqueue,discard

# Get <nvme-UUID> on neovim:
:read ! lsblk -dno UUID /dev/nvme0n1p2
```

### 🧵 Step 15 — Kernel Command Line Configuration (UKI + zswap)

```bash
# ⚙️ Root and logging options (read-only fs is handled by systemd and to fsck /)
nvim /etc/cmdline.d/01-root.conf

# Content:
root=/dev/mapper/cryptarch rootfstype=btrfs rootflags=subvol=@ ro loglevel=3

# 🧠 Configure zswap parameters for performance
nvim /etc/cmdline.d/02-zswap.conf

# Content:
zswap.enabled=1 zswap.max_pool_percent=20 zswap.zpool=zsmalloc zswap.compressor=zstd zswap.accept_threshold_percent=90
```

### 🧬 Step 16 — Initramfs Preset for Unified Kernel Image (UKI)

```bash
# 🔧 Setup mkinitcpio preset to generate a UKI
nvim /etc/mkinitcpio.d/linux.preset

# Content only:
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_uki="/efi/EFI/Linux/arch-linux.efi"
default_options="--splash=/usr/share/systemd/bootctl/splash-arch.bmp"
```

### 🔐 Step 17 — Secure Boot with sbctl

```bash
# 🔑 Create Secure Boot keys
sbctl create-keys

# 📥 Enroll custom keys and micr0$0ft💩 keys
sbctl enroll-keys -m

# 🛠️ Generate the Unified Kernel Image
mkdir -p /efi/EFI/Linux
mkinitcpio -p linux
```

### 💻 Step 18 — EFI Boot Entry

```bash
# 🧷 Register UKI with UEFI firmware
efibootmgr --create --disk /dev/nvme0n1 --part 1 \
  --label "Arch Linux" --loader /EFI/Linux/arch-linux.efi --unicode
```

### 🛡️ Step 19 — LUKS TPM2 Key Enrollment

```bash
# 🔒 Enroll TPM2 key (PCR 0 = firmware, PCR 7 = Secure Boot state)
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
```

### 🧠 Step 20 — Swappiness Tuning

```bash
# 🧮 Lower swappiness to prefer RAM usage over swap
nvim /etc/sysctl.d/99-swappiness.conf

# Content, 80% RAM usage before swapping:
vm.swappiness=20
```

### 🔄 Step 21 — Encrypted Swap Setup

```bash
# 🔐 Add encrypted swap entry using /dev/urandom
nvim /etc/crypttab

# Content:
swap      /.swap/swapfile      /dev/urandom      swap,cipher=aes-xts-plain64,sector-size=4096

# 📄 Add swap to fstab
nvim /etc/fstab

# Content:
#	/.swap/swapfile      CRYPTED SWAPFILE
/dev/mapper/swap      none      swap      defaults      0 0
```

### 📦 Step 22 — Pacman Configuration

```bash
# 📦 Enable multilib, candy theme, parallel downloads & ignore snapper cron jobs
nvim /etc/pacman.conf

# Content:
NoExtract = etc/cron.daily/snapper etc/cron.hourly/snapper
Color
ParallelDownloads = 10
ILoveCandy

[multilib]
Include = /etc/pacman.d/mirrorlist
```

### 🌐 Step 23 — Network Configuration (Wired)

```bash
# 📡 Configure wired interface for DHCP, mDNS, and IPv6
nvim /etc/systemd/network/20-wired.network

# Content:
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
```

### 🔌 Step 24 — Basic Packages: Bluetooth, Snapper, Pacman Cache Service, Reflector

```bash
# 📦 Install essential tools
pacman -Syy bluez snapper pacman-contrib reflector
```

### 🕰️ Step 25 — Time Sync with French NTP Servers

```bash
# ⏲️ Set systemd-timesyncd to use French pool servers with iburst
nvim /etc/systemd/timesyncd.conf

# Content:
[Time]
NTP=0.fr.pool.ntp.org 1.fr.pool.ntp.org 2.fr.pool.ntp.org 3.fr.pool.ntp.org
FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
```

### 🚀 Step 26 — I/O Scheduler Tuning for NVMe

```bash
# 📉 Disable I/O scheduler on NVMe device to use none (for performance)
nvim /etc/udev/rules.d/60-schedulers.rules

# Content:
ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/scheduler}="none"
```

### 🧭 Step 27 — DNS Stub Resolver via systemd-resolved

```bash
# 🔁 Link stub resolver to /etc/resolv.conf
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### 🌐 Step 28 — Reflector Configuration (Update Mirrorlist)

```bash
# 🌍 Optimize pacman mirrors by age, country, and protocol
nvim /etc/xdg/reflector/reflector.conf

# Content:
--save /etc/pacman.d/mirrorlist
--country France,Germany,Netherlands
--protocol https
--latest 5
--sort age
```

### ⚙️ Step 29 — Enable Key Services (Networking, Bluetooth, Time, Packages Cache Cleaner, Mirrorlist Updater)

```bash
# 🛠️ Enable network and system services
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable bluetooth.service
systemctl enable systemd-timesyncd.service
systemctl enable paccache.timer
systemctl enable reflector.timer
```

### 🔑 Step 30 — Configure sudo

```bash
# 🛡️ Grant sudo to wheel group
EDITOR=nvim visudo

# Content:
%wheel ALL=(ALL:ALL) ALL
```

### 🚧 Step 31 — Compilation Optimization (makepkg)

```bash
# 🧰 Tune makepkg flags for native arch, use /tmp for build
nvim /etc/makepkg.conf

# Content:
CFLAGS="-march=native -O2 -pipe ..."
MAKEFLAGS="-j$(nproc)"
BUILDDIR=/tmp/makepkg

# 🦀 Optimize Rust build flags
nvim /etc/makepkg.conf.d/rust.conf

# Content:
RUSTFLAGS="-C opt-level=2 -C target-cpu=native"
```

### 🔇 Step 32 — Disable HDMI Audio

```bash
# 🔕 Blacklist HDMI audio module
nvim /etc/modprobe.d/blacklist.conf

# Content:
blacklist snd_hda_intel
```

### 🔒 Step 33 — Disable Webcam Microphone

```bash
# 🎙️ Block Logitech webcam microphone via udev rule
nvim /etc/udev/rules.d/90-blacklist-webcam-sound.rules

# Content:
SUBSYSTEM=="usb", DRIVER=="snd-usb-audio", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="085c", ATTR{authorized}="0"
```

### 🔐 Step 34 — Set Root Password

```bash
# 🔑 Set root password
passwd root
```

### 🚪 Step 35 — Exit chroot, Unmount, Reboot into Firmware Setup

```bash
# 👋 Exit chroot, unmount and reboot into UEFI/BIOS to check if Secure Boot is enabled
exit
umount -R /mnt
systemctl reboot --firmware-setup
```

### 🧩 Step 36 — Configure Snapper after Reboot

```bash
# 🔌 Unmount the default /.snapshots subvolume
umount /.snapshots

# 🗑️ Delete it to avoid conflicts with our custom mount
rm -r /.snapshots

# 🛠️ Initialize Snapper for root filesystem
snapper -c root create-config /

# ❌ Delete the subvolume Snapper just created (we’ll remount it ourselves)
btrfs subvolume delete /.snapshots

# 📂 Recreate the mount point and mount it
mkdir /.snapshots
mount /.snapshots

# 🔐 Secure the directory
chmod 750 /.snapshots

# 📝 Configure Snapper snapshot settings
nvim /etc/snapper/configs/root

# Content:
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"

NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="10"
NUMBER_LIMIT_IMPORTANT="10"

TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
```

### 🛡️ Step 37 — Custom Pacman Hook to Backup /efi

```bash
# 🪝 Create a hook to automatically backup /efi before critical updates
nvim /etc/pacman.d/hooks/10-efi_backup.hook

# Content:
## PACMAN EFI BACKUP HOOK
## /etc/pacman.d/hooks/10-efi_backup.hook

[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/lib/initcpio/*
Target = usr/lib/firmware/*
Target = usr/lib/modules/*/extramodules/
Target = usr/lib/modules/*/vmlinuz
Target = usr/src/*/dkms.conf

[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Operation = Remove
Target = mkinitcpio
Target = mkinitcpio-git

[Action]
Description = 🔐 Backing up /efi...
When = PreTransaction
Exec = /usr/local/sbin/efi_backup.sh

# ✍️ Create the backup script
nvim /usr/local/sbin/efi_backup.sh

# Content:
#!/bin/bash
## SCRIPT EFI BACKUP
## /usr/local/sbin/efi_backup.sh

tar -czf "/.efibackup/efi-$(date +%Y%m%d-%H%M%S).tar.gz" -C / efi
ls -1t /.efibackup/efi-*.tar.gz | tail -n +4 | xargs -r rm --

# ✅ Make it executable
chmod +x /usr/local/sbin/efi_backup.sh
```

### ✂️ Step 38 — Limit fstrim to FAT32 /efi Only

```bash
# ⚙️ Override default fstrim behavior
systemctl edit fstrim.service

# Content:
[Service]
ExecStart=
ExecStart=/usr/sbin/fstrim -v /efi
```

### ⏲️ Step 39 — Enable Maintenance Timers

```bash
# 🕒 Enable regular TRIM for /efi only
systemctl enable fstrim.timer

# 📸 Enable automatic timeline snapshots
systemctl enable snapper-timeline.timer

# 🧼 Enable automatic snapshot cleanup
systemctl enable snapper-cleanup.timer
```

### 🧷 Step 40 — Enable Pacman Transaction Snapshots

```bash
# 🧩 Install snap-pac to snapshot before and after pacman operations
pacman -S snap-pac
```

### 🗑️ Step 41 — Clean Snapper Initial Snapshots Manually

```bash
# 📋 List snapshots (🔍)
snapper -c root list

# 🧹 Delete a range of snapshots (e.g., snapshots 1 to 2)
snapper -c root delete 1-2
```

### 📸 Step 42 — Take Initial System Snapshot

```bash
# 🧊 Manually create the first system snapshot after full setup
snapper -c root create -d "init"
```

---

## ❓ FAQ

### ❓ Why no bootloader?

Because **UKI** allows booting the kernel directly from the EFI partition — no need for GRUB or systemd-boot.

### ❓ Can I use this on my laptop?

Yes — it's ideal for modern laptops with TPM2 and Secure Boot enabled.

---

## 🛠 Requirements

- 🖥️ UEFI firmware
- 🧩 TPM 2.0 module
- 🧷 Secure Boot support
- 💿 Recent Arch Linux ISO
- 🌐 Internet access

---

## 📜 License

Licensed under the [MIT License](LICENSE).
Feel free to use, modify, and share!

---

## 👤 Author

Crafted with ❤️ by [joan31](https://github.com/joan31)

> _"Build it clean. Build it solid. Fortress-grade Arch Linux."_
