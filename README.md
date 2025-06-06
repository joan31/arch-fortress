# 🏰 Arch Fortress — Secure & Minimal Arch Linux Installer

**Arch Fortress** is a lightweight, secure, modern and efficient Arch Linux installation framework.

It aims to provide a **solid base system** for advanced users who want a clean, fully encrypted system using modern technologies — **without unnecessary components** like GRUB or classic init hooks.

> 🛡️ Built on: **EFI**, **UKI**, **LUKS2 + TPM2**, **Secure Boot**, **BTRFS**, **Systemd init**, **zswap**, **snapper**

---

## 📚 Table of Contents

- [🎯 Overview](#-overview)
- [⚙️ Features](#️-features)
- [📦 Project Structure](#-project-structure)
- [🗂️ Disk Layout & Subvolume Architecture](#️-disk-layout--subvolume-architecture)
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
- 💾 Encrypted **swap file** + **zswap** for compressed memory
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

## 🚀 Automatic Installation (WIP)

> 🧪 Coming soon: Full auto-install script with configuration prompts or flags.

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

> 🧠 For advanced users or educational purposes

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
# ⌨️ Set keyboard layout to French
loadkeys fr

# 🧼 Clean existing EFI entries if needed (replace X with the entry number)
efibootmgr
efibootmgr -b X -B

# 🔐 Update GPG keys from live environment (recommended before installing)
pacman -Sy archlinux-keyring
```

### 💽 Step 2 — Disk Partitioning (GPT)

```bash
# ⚙️ Partition the disk: EFI (512MB) + LUKS root (rest of disk)
sgdisk --clear --align-end \
  --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI system partition" \
  --new=2:0:0     --typecode=2:8309 --change-name=2:"Linux LUKS" \
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
btrfs subvolume create /mnt/@           # root
btrfs subvolume create /mnt/@swap       # encrypted swap
btrfs subvolume create /mnt/@snapshots  # for Snapper
btrfs subvolume create /mnt/@efibck     # automatic EFI backups
btrfs subvolume create /mnt/@log        # system logs
btrfs subvolume create /mnt/@pkg        # pacman cache
btrfs subvolume create /mnt/@tmp        # temp files
btrfs subvolume create /mnt/@vms        # libvirt VMs
btrfs subvolume create /mnt/@home       # user data
btrfs subvolume create /mnt/@srv        # server data
btrfs subvolume create /mnt/@games      # optional game data

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
mount -o rw,noatime,nodiratime,nodev,nosuid,noexec,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@vm /dev/mapper/cryptarch /mnt/var/lib/libvirt/images
mount -o rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@home /dev/mapper/cryptarch /mnt/home
mount -o rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@srv /dev/mapper/cryptarch /mnt/srv
mount -o rw,noatime,nodiratime,nodev,nosuid,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,subvol=@games /dev/mapper/cryptarch /mnt/opt/games
```

### 💾 Step 6 — Create Encrypted Swap File

```bash
# 🛏️ Create 4GB swap file on BTRFS subvolume
btrfs filesystem mkswapfile --size 4g /mnt/.swap/swapfile
chmod 600 /mnt/.swap/swapfile
```

### 📦 Step 7 — Install Base System

```bash
# 🧱 Install base packages + firmware, EFI tools, and btrfs support
pacstrap /mnt \
  base base-devel linux linux-firmware amd-ucode \
  neovim efibootmgr btrfs-progs sbctl
```

### 🗂️ Step 8 — Generate fstab

```bash
# 📄 Generate fstab with UUIDs
genfstab -U /mnt >> /mnt/etc/fstab

# 🔍 (Optional) Review fstab
nvim /mnt/etc/fstab
# Make sure root uses: subvol=/@ ... 0 1
```

### 🚪 Step 9 — Enter Chroot

```bash
# 🌀 Change root into new system
arch-chroot /mnt
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
