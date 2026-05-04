# 🏰 Arch Fortress — Secure & Minimal Arch Linux Installer

![Linux](https://img.shields.io/badge/OS-Linux-black?style=flat-square&logo=linux&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Distro-Arch-blue?style=flat-square&logo=arch-linux)
![EFI](https://img.shields.io/badge/Firmware-EFI-white?style=flat-square&logo=rocket&logoColor=white)
![UKI](https://img.shields.io/badge/Boot-UKI-purple?style=flat-square&logo=linuxfoundation&logoColor=white)
![LUKS2 + TPM2](https://img.shields.io/badge/Encryption-LUKS2%20%2B%20TPM2-orange?style=flat-square&logo=cryptpad&logoColor=white)
![Secure Boot](https://img.shields.io/badge/Secure%20Boot-Enabled-teal?style=flat-square&logo=socket&logoColor=white)
![BTRFS](https://img.shields.io/badge/Filesystem-BTRFS-deepskyblue?style=flat-square&logo=buffer&logoColor=white)
![Systemd](https://img.shields.io/badge/Init-Systemd-slateblue?style=flat-square&logo=circle&logoColor=white)
![zRam](https://img.shields.io/badge/zRam-Enabled-limegreen?style=flat-square&logo=cashapp&logoColor=white)
![Snapper](https://img.shields.io/badge/Snapper-Enabled-darkslategray?style=flat-square&logo=simpleicons&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square&logo=open-source-initiative)](LICENSE)

**Arch Fortress** is a lightweight, secure, modern and efficient Arch Linux installation framework.

It aims to provide a **solid base system** for advanced users who want a clean, fully encrypted system using modern technologies — **without unnecessary components** like GRUB or classic init hooks.

> 🛡️ Built on: **EFI**, **UKI**, **LUKS2 + TPM2**, **Secure Boot**, **BTRFS**, **Systemd init**, **zRam**, **snapper**

---

## 📚 Table of Contents

- [🎯 Overview](#-overview)
- [⚙️ Features](#️-features)
- [📦 Structure](#-structure)
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
- 🔁 **Direct EFI boot** via a signed **Unified Kernel Image (UKI)** — no bootloader (no GRUB, no systemd-boot)
- 💥 Full **Secure Boot** support
- 🧠 Modern `mkinitcpio` using **systemd init hooks**
- 🧵 **zRam** enabled for compressed in-memory swap, reducing disk swap pressure
- 💾 Encrypted **swap file** on BTRFS as zRam fallback
  - Uses a transient encryption key generated at boot from `/dev/urandom`  
  - ⚠️ Hibernation is not possible (non-persistent encryption key)
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
- **zRam** enabled to provide fast compressed RAM-based swap
- Encrypted **swap file** on BTRFS

### ⚙️ Boot Process
- **No bootloader** (no GRUB, no systemd-boot)
- EFI directly loads a **signed Unified Kernel Image (UKI)**
- UKI built with `mkinitcpio`, containing:
  - Kernel
  - Initramfs
  - Kernel cmdline

### 🧠 Init System
- `mkinitcpio` using:
  - `systemd`, `sd-vconsole`, `sd-encrypt`
- No legacy hooks like `udev`, `usr`, `resume`, `keymap`, `consolefont`, `encrypt`
- Faster, cleaner, future-proof boot

### 🛟 Automatic EFI Backup
- The `/efi` (ESP) is automatically backed up to `/.efibck`
- Useful for system recovery

---

## 📦 Structure

<details>
<summary>📁 <code>arch-fortress/</code> (click to expand)</summary>

```
arch-fortress/
├── etc/
│   └── pacman.d/
│       └── hooks/
│           └── 10-efi_backup.hook
├── usr/
│   └── local/
│       └── sbin/
│           └── efi_backup.sh
├── 01-arch_baseinstall.sh
├── 02-arch_baseinstall_chroot.sh
├── 03-install_hook_efibck.Sh
├── LICENSE
└── README.md
```

</details>

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
- 🌀 Swap and zRam activation

### 🧱 Step 1 — Pre-Installation Setup

- ⌨️ (Optional) Set keyboard layout to French
```bash
loadkeys fr
```

- 🧼 Clean existing EFI entries if needed (replace X with the entry number)
```bash
efibootmgr
efibootmgr -b X -B
```

- 🔐 Update GPG keys from live environment (recommended before installing)
```bash
pacman -Sy archlinux-keyring
```

### 💽 Step 2 — Disk Partitioning (GPT)

- ⚙️ Partition the disk: EFI (500MB) + LUKS root (rest of disk)
```bash
sgdisk --clear --align-end \
  --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI system partition" \
  --new=2:0:0 --typecode=2:8309 --change-name=2:"Linux LUKS" \
  /dev/nvme0n1
```

### 🧼 Step 3 — Filesystem Creation


- 🧴 Format EFI partition (optimized for NVMe 4K sector size)
```bash
mkfs.vfat -F 32 -n "SYSTEM" -S 4096 -s 1 /dev/nvme0n1p1
```

- 🔐 Create LUKS2 encrypted container with strong encryption options
```bash
cryptsetup --type luks2 --cipher aes-xts-plain64 --hash sha512 \
  --iter-time 5000 --key-size 512 --pbkdf argon2id \
  --label "Linux LUKS" --sector-size 4096 --use-urandom \
  --verify-passphrase luksFormat /dev/nvme0n1p2
```

- 🔓 Open the LUKS container as /dev/mapper/cryptarch
```bash
cryptsetup --allow-discards --persistent open --type luks2 \
  /dev/nvme0n1p2 cryptarch
```

- 🧊 Format the unlocked LUKS volume with BTRFS (4K sectors)
```bash
mkfs.btrfs -L "Arch Linux" -s 4096 /dev/mapper/cryptarch
```

### 🌳 Step 4 — BTRFS Subvolume Layout

- 🪵 Mount the root BTRFS volume temporarily
```bash
mount -o rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120 \
  /dev/mapper/cryptarch /mnt
```

- 📂 Create BTRFS subvolumes
```bash
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
```

- 🔓 Unmount the volume before remounting subvolumes individually
```bash
umount /mnt
```

### 🛠️ Step 5 — Mount Subvolumes & Prepare System

- 🔧 Mount root subvolume
```bash
mount -o rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@ \
  /dev/mapper/cryptarch /mnt
```

- 🗂️ Create necessary mount points
```bash
mkdir -p /mnt/{efi,.swap,.snapshots,.efibackup,var/{log,tmp,cache/pacman/pkg,lib/libvirt/images},home,srv,opt/games}
```

- 🖥️ Mount EFI system partition (read-only, noexec for safety)
```bash
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,fmask=0022,dmask=0022 \
  /dev/nvme0n1p1 /mnt/efi
```

- 🧷 Mount other BTRFS subvolumes
```bash
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

- 🛏️ Create 4GB swap file on BTRFS subvolume
```bash
btrfs filesystem mkswapfile --size 4g /mnt/.swap/swapfile
chmod 600 /mnt/.swap/swapfile
```

### 📦 Step 7 — Install Base System

- 🧱 Install base packages, kernel + firmwares, EFI tools, btrfs support, text editor, secure boot tools, splash screen and zRam generator service
```bash
pacstrap /mnt \
  base base-devel linux linux-headers linux-firmware amd-ucode \
  neovim efibootmgr btrfs-progs sbctl plymouth zram-generator
```

### 🗂️ Step 8 — Generate fstab

- 📄 Generate fstab with UUIDs
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

- 🔍 (Optional) Review fstab and check "0 1" to enable fsck on `/`
```bash
nvim /mnt/etc/fstab
```

- Content:
```bash
UUID=<BTRFS-UUID-PARTITION>      /      btrfs      rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=/@      0 1
```

### 🚪 Step 9 — Enter Chroot

- 🌀 Change root into new system
```bash
arch-chroot /mnt
```

### 🌐 Step 10 — Keyboard & Locale Configuration

- ⌨️ Set virtual console keyboard to French
```bash
nvim /etc/vconsole.conf
```

- Content:
```bash
KEYMAP=fr
FONT=lat9w-16
```

- 🧩 Set X11 keyboard layout
```bash
localectl set-x11-keymap fr pc105 azerty compose:rctrl
```
> 💡 This ensures correct keyboard compatibility with Xorg/XWayland apps and proper layout support in display managers like Plasma Login Manager (used by KDE Plasma).

- 🌍 Set system-wide locale
```bash
nvim /etc/locale.conf
```

- Content:
```bash
LANG=fr_FR.UTF-8
LC_COLLATE=C
LC_MESSAGES=en_US.UTF-8
```

- 🔓 Enable required locales
```bash
nvim /etc/locale.gen
```

- Uncomment:
```bash
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
```

- ⚙️ Generate locale definitions
```bash
locale-gen
```

### 🔢 Step 11 — TTY Behavior (Enable NumLock)

- 🧷 Create drop-in to activate NumLock automatically on TTY login
```bash
mkdir /etc/systemd/system/getty@.service.d
nvim /etc/systemd/system/getty@.service.d/activate-numlock.conf
```

- Content:
```bash
[Service]
ExecStartPre=/bin/sh -c 'setleds -D +num < /dev/%I'
```

### 🖥️ Step 12 — Host Identity Configuration

- 🏷️ Set system hostname
```bash
nvim /etc/hostname
```

- Content:
```bash
lianli-arch
```

- 🧭 Set hosts file entries for local networking
```bash
nvim /etc/hosts
```

- Content:
```bash
127.0.0.1      localhost
::1            localhost
192.168.1.101  lianli-arch.zenitram lianli-arch
```

### 🕒 Step 13 — Timezone & Clock Setup

- 🌍 Set system timezone
```bash
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
```

- ⏱️ Sync hardware clock with system time
```bash
hwclock --systohc
```

### 🧩 Step 14 — Initramfs Configuration (AMDGPU Module, Systemd, LUKS, Keyboard)

- ⚙️ Edit initramfs modules and hooks to include AMDGPU driver before anything, systemd & encryption
```bash
nvim /etc/mkinitcpio.conf
```

- Content:
```bash
MODULES=(amdgpu)

HOOKS=(systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems)
```

- 🔐 Setup encrypted volume for systemd to unlock via TPM2
```bash
nvim /etc/crypttab.initramfs
```

- Content:
```bash
cryptarch UUID=<nvme-UUID> none tpm2-device=auto,password-echo=no,x-systemd.device-timeout=0,timeout=0,no-read-workqueue,no-write-workqueue,discard
```

- Get `<nvme-UUID>` on neovim:
```bash
:read ! lsblk -dno UUID /dev/nvme0n1p2
```

### 🧵 Step 15 — Kernel Command Line Configuration (UKI + disable zswap)

- ⚙️ Root and logging options (read-only fs is handled by systemd and to fsck /)
```bash
nvim /etc/cmdline.d/01-root.conf
```

- Content:
```bash
root=/dev/mapper/cryptarch rootfstype=btrfs rootflags=subvol=@ ro loglevel=3 quiet splash
```

- 🧠 Disable kernel zswap to avoid duplicate swap compression when using zRam as primary swap device
```bash
nvim /etc/cmdline.d/02-zswap.conf
```

- Content:
```bash
zswap.enabled=0
```

### 🧬 Step 16 — Initramfs Preset for Unified Kernel Image (UKI)

- 🔧 Setup mkinitcpio preset to generate a UKI
```bash
nvim /etc/mkinitcpio.d/linux.preset
```

- Content only:
```bash
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_uki="/efi/EFI/Linux/arch-linux.efi"
```
> 💡 `default_options="--splash=/usr/share/systemd/bootctl/splash-arch.bmp"` is commented out by default and can be uncommented to enable the splash screen, but it may be redundant if Plymouth is used.

### 🔐 Step 17 — Secure Boot with sbctl

- 🔑 Create Secure Boot keys
```bash
sbctl create-keys
```

- 📥 Enroll custom keys and micr0$0ft💩 keys
```bash
sbctl enroll-keys -m
```

- 🛠️ Generate the Unified Kernel Image
```bash
mkdir -p /efi/EFI/Linux
mkinitcpio -p linux
```

> ℹ️ Note: TPM2-based disk decryption will be configured after the first reboot to ensure the system is fully initialized and all required services are available.

### 💻 Step 18 — EFI Boot Entry

- 🧷 Register UKI with UEFI firmware
```bash
efibootmgr --create --disk /dev/nvme0n1 --part 1 \
  --label "Arch Linux" --loader /EFI/Linux/arch-linux.efi --unicode
```

### 🧠 Step 19 — zRam Setup

- ⚙️ Configure zRam swap device (primary in-memory compressed swap)
```bash
nvim /etc/systemd/zram-generator.conf
```

- Content (balanced gaming + desktop performance):
```bash
[zram0]
zram-size = min(ram / 4, 8 * 1024)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
```

- 🧮 Configure kernel virtual memory parameters for zRam-based swap behavior
```bash
nvim /etc/sysctl.d/99-vm-zram-parameters.conf
```

- Content (low-latency desktop + gaming responsiveness):
```bash
vm.swappiness = 20
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

### 🔄 Step 20 — Encrypted Swap Setup

- 🔐 Add encrypted swap mapping using `/dev/urandom` (secure swapfile via device-mapper)
```bash
nvim /etc/crypttab
```

- Content:
```bash
swap      /.swap/swapfile      /dev/urandom      swap,cipher=aes-xts-plain64,sector-size=4096
```

- 📄 Add swap entry with low priority (fallback to zram)
```bash
nvim /etc/fstab
```

- Content:
```bash
#	/.swap/swapfile      ENCRYPTED FALLBACK SWAP
/dev/mapper/swap      none      swap      pri=0      0 0
```

### 📦 Step 21 — Pacman Configuration

- 📦 Enable multilib, candy theme, parallel downloads & ignore snapper cron jobs
```bash
nvim /etc/pacman.conf
```

- Content:
```bash
NoExtract = etc/cron.hourly/snapper
Color
ParallelDownloads = 10
ILoveCandy

[multilib]
Include = /etc/pacman.d/mirrorlist
```

### 🌐 Step 22 — Network Configuration
> 🔀 Choose one network management method depending on your setup
> - ⚙️ `systemd-networkd` → lightweight, minimal, server-friendly, wired only
> - 🖥️ `NetworkManager` → recommended for desktop environments (e.g. KDE Plasma, GNOME) with Wi-Fi support

####  ⚙️ Option A — systemd-networkd (Only Wired, Minimal & Lightweight)

- 📡 Configure wired interface for DHCP, mDNS, and IPv6
```bash
nvim /etc/systemd/network/20-wired.network
```

- Content:
<details>
<summary>📄 <code>20-wired.network</code> content (click to expand)</summary>

```bash
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
</details>

####  ⚙️ Option B — NetworkManager (Desktop-Friendly, Wi-Fi Ready)
> 💡 Recommended if you plan to use KDE Plasma, GNOME, or need Wi-Fi support

- 📦 Install NetworkManager
 ```bash
pacman -Syy networkmanager
```

### 🔌 Step 23 — Basic Packages: Bluetooth, Snapper, Pacman Cache Service, Reflector

- 📦 Install essential tools
```bash
pacman -Syy bluez snapper pacman-contrib reflector
```

### 🕰️ Step 24 — Time Sync with French NTP Servers

- ⏲️ Set systemd-timesyncd to use French pool servers with iburst
```bash
nvim /etc/systemd/timesyncd.conf
```

- Content:
```bash
[Time]
NTP=0.fr.pool.ntp.org 1.fr.pool.ntp.org 2.fr.pool.ntp.org 3.fr.pool.ntp.org
FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
```

### 🚀 Step 25 — I/O Scheduler Tuning for NVMe

- 📉 Disable I/O scheduler on NVMe device to use none (for performance)
```bash
nvim /etc/udev/rules.d/60-schedulers.rules
```

- Content:
```bash
ACTION=="add|change", KERNEL=="nvme[0-9]*", ENV{DEVTYPE}=="disk", ATTR{queue/scheduler}="none"
```

### 🧭 Step 26 — DNS Stub Resolver via systemd-resolved
> ⚠️ Only apply this step if you are using *systemd-networkd* (from Step 23)
> ⏭️ Skip this step if you selected *NetworkManager*

- 🔁 Link stub resolver to `/etc/resolv.conf`
```bash
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### 🌐 Step 27 — Reflector Configuration (Update Mirrorlist)

- 🌍 Optimize pacman mirrors by age, country, and protocol
```bash
nvim /etc/xdg/reflector/reflector.conf
```

- Content:
```bash
--save /etc/pacman.d/mirrorlist
--country France,Germany,Netherlands
--protocol https
--latest 5
--sort age
```

### ⚙️ Step 28 — Enable Key Services (Networking, Bluetooth, Time, Maintenance)

- 🌐 Enable network services (based on your previous choice)

- ⚙️ If using *systemd-networkd*:
```bash
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
```

- 🖥️ If using *NetworkManager*:
```bash
systemctl enable NetworkManager.service
```

- 🔧 Enable essential system services
```bash
systemctl enable bluetooth.service
systemctl enable systemd-timesyncd.service
```

- 🧹 Enable maintenance timers (package cache cleaner & mirrorlist updater)
```bash
systemctl enable paccache.timer
systemctl enable reflector.timer
```

- 🚫 Disable hibernation-related targets (not used / not supported in this setup)
```bash
systemctl mask hibernate.target hybrid-sleep.target
```
> This disables hibernation and hybrid sleep at the systemd level.
> - Swap is encrypted with a non-persistent key, making hibernation unusable  
> - It prevents any accidental suspend-to-disk attempts  
> - It keeps the system configuration cleaner and more explicit
>  
> 💡 On KDE Plasma, this also removes the hibernation option from the power menu, making it cleaner and less confusing.

### 🧰 Step 29 — Change System Editor and Visualiser

- 📝 Define default system editor (used by system tools like systemctl edit, git, etc.)
```bash
nvim /etc/environment
```

- Content:
```bash
EDITOR=nvim
VISUAL=nvim
```

- 🔄 Apply changes immediately (current shell)
```bash
export EDITOR=nvim
```

### 🔑 Step 30 — Configure sudo

- 🛡️ Grant sudo to wheel group
```bash
visudo
```

- Content:
```bash
%wheel ALL=(ALL:ALL) ALL
```

### 🚧 Step 31 — Compilation Optimization (makepkg)

- 🧰 Tune makepkg flags for native arch, use /tmp for build
```bash
nvim /etc/makepkg.conf
```

- Content:
```bash
CFLAGS="-march=native -O2 -pipe ..."
MAKEFLAGS="-j$(nproc)"
BUILDDIR=/tmp/makepkg
```

- 🦀 Optimize Rust build flags
```bash
nvim /etc/makepkg.conf.d/rust.conf
```

- Content:
```bash
RUSTFLAGS="-C opt-level=2 -C target-cpu=native"
```

### 🔇 Step 32 — Disable HDMI Audio

- 🔕 Blacklist HDMI audio module
```bash
nvim /etc/modprobe.d/blacklist.conf
```

- Content:
```bash
blacklist snd_hda_intel
```

### 🔒 Step 33 — Disable Webcam Microphone

- 🎙️ Block Logitech webcam microphone via udev rule
```bash
nvim /etc/udev/rules.d/90-blacklist-webcam-sound.rules
```

- Content:
```bash
SUBSYSTEM=="usb", DRIVER=="snd-usb-audio", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="085c", ATTR{authorized}="0"
```

### ⚡ Step 34 — Allow games Group to Read CPU Power

- 🎮 Grant members of the games group permission to read CPU power (via Intel RAPL interface).
```bash
nvim /etc/udev/rules.d/70-intel-rapl.rules
```

- Content:
```bash
SUBSYSTEM=="powercap", KERNEL=="intel-rapl:0", RUN+="/usr/bin/chgrp games /sys/%p/energy_uj", RUN+="/usr/bin/chmod g+r /sys/%p/energy_uj"
```

> ✅ This ensures users in the `games` group can access CPU energy readings without requiring root privileges — useful for monitoring tools or performance overlays.

### 🔐 Step 35 — Set Root Password

- 🔑 Set root password
```bash
passwd root
```

### 🚪 Step 36 — Exit chroot, Unmount, Reboot into Firmware Setup

- 👋 Exit chroot, unmount and reboot into UEFI/BIOS to check if Secure Boot is enabled
```bash
exit
umount -R /mnt
systemctl reboot --firmware-setup
```

### 🛡️ Step 37 — LUKS TPM2 Key Enrollment

- 🔒 Enroll TPM2 key (PCR 0 = firmware, PCR 7 = Secure Boot state)
```bash
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
```

### 🧩 Step 38 — Configure Snapper after Reboot

- 🔌 Unmount the default /.snapshots subvolume
```bash
umount /.snapshots
```

- 🗑️ Delete it to avoid conflicts with our custom mount
```bash
rm -r /.snapshots
```

- 🛠️ Initialize Snapper for root filesystem
```bash
snapper -c root create-config /
```

- ❌ Delete the subvolume Snapper just created (we’ll remount it ourselves)
```bash
btrfs subvolume delete /.snapshots
```

- 📂 Recreate the mount point and mount it
```bash
mkdir /.snapshots
mount /.snapshots
```

- 🔐 Secure the directory
```bash
chmod 750 /.snapshots
```

- 📝 Configure Snapper snapshot settings
```bash
nvim /etc/snapper/configs/root
```

- Content:
```bash
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

### 🛡️ Step 39 — Custom Pacman Hook to Backup /efi

- 🪝 Create a hook to automatically backup /efi before critical updates
```bash
nvim /etc/pacman.d/hooks/10-efi_backup.hook
```

- Content:

<details>
<summary>📄 <code>10-efi_backup.hook</code> content (click to expand)</summary>

```bash
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
Description = Backing up /efi...
When = PreTransaction
Exec = /usr/local/sbin/efi_backup.sh
```

</details>

- ✍️ Create the backup script
```bash
nvim /usr/local/sbin/efi_backup.sh
```

- Content:

<details>
<summary>📄 <code>efi_backup.sh</code> content (click to expand)</summary>

```bash
#!/bin/bash
## SCRIPT EFI BACKUP
## /usr/local/sbin/efi_backup.sh

tar -czf "/.efibackup/efi-$(date +%Y%m%d-%H%M%S).tar.gz" -C / efi
ls -1t /.efibackup/efi-*.tar.gz | tail -n +4 | xargs -r rm --
```

</details>

- ✅ Make it executable
```bash
chmod +x /usr/local/sbin/efi_backup.sh
```

### ⏲️ Step 40 — Enable Maintenance Timers

- 🕒 Enable regular TRIM
```bash
systemctl enable fstrim.timer
```

- 📸 Enable automatic timeline snapshots
```bash
systemctl enable snapper-timeline.timer
```

- 🧼 Enable automatic snapshot cleanup
```bash
systemctl enable snapper-cleanup.timer
```

### 🧷 Step 41 — Enable Pacman Transaction Snapshots

- 🧩 Install snap-pac to snapshot before and after pacman operations
```bash
pacman -S snap-pac
```

### Step 42 — 🎮 Shared games directory (multi-user Steam library)

- 🕹️ Allow access and inheritance for users in the `games` group via ACL
```bash
chown root:games /opt/games
chmod 2775 /opt/games
setfacl -dm g:games:rwx /opt/games
```

### 🗑️ Step 42 — Clean Snapper Initial Snapshots Manually

- 📋 List snapshots (🔍)
```bash
snapper -c root list
```

- 🧹 Delete a range of snapshots (e.g., snapshots 1 to 2)
```bash
snapper -c root delete 1-2
```

### 📸 Step 43 — Take Initial System Snapshot

- 🧊 Manually create the first system snapshot after full setup
```bash
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
- 🧮 NVMe drive with 4K physical block size

---

## 📜 License

Licensed under the [MIT License](LICENSE).
Feel free to use, modify, and share!

---

## 👤 Author

Crafted with ❤️ by [joan31](https://github.com/joan31)

> _"Build it clean. Build it solid. Fortress-grade Arch Linux."_
