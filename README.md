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

📌 *To be added soon...*

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
- 🧷 Secure Boot support (optional but recommended)
- 💿 Arch Linux ISO (2024+)
- 🌐 Internet access

---

## 📜 License

Licensed under the [MIT License](LICENSE).
Feel free to use, modify, and share!

---

## 👤 Author

Crafted with ❤️ by [joan31](https://github.com/joan31)

> _"Build it clean. Build it solid. Fortress-grade Arch Linux."_
