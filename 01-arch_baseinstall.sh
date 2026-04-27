#!/bin/bash
## ARCH LINUX INSTALLATION - BASE
## SYSTEMD INIT - LUKS - BTRFS - UKI - SECURE BOOT
## ./arch_baseinstall.sh
## By Joan https://github.com/joan31/

set -e  # Stop the script on any error

## VARIABLES
# Define common mount options
common_opts="rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120"
extra_opts="nodev,nosuid,noexec"
home_opts="nodev,nosuid"
efi_opts="rw,noatime,nodiratime,nodev,nosuid,noexec,fmask=0022,dmask=0022"

# Define subvolumes and their mount points
declare -A subvolumes=(
  [@swap]="/mnt/.swap"
  [@snapshots]="/mnt/.snapshots"
  [@efibck]="/mnt/.efibackup"
  [@log]="/mnt/var/log"
  [@pkg]="/mnt/var/cache/pacman/pkg"
  [@vms]="/mnt/var/lib/libvirt/images"
  [@tmp]="/mnt/var/tmp"
  [@home]="/mnt/home"
  [@srv]="/mnt/srv"
  [@games]="/mnt/opt/games"
)

# TPM
handles=$(tpm2_getcap handles-persistent | awk '{print $2}')

## MAIN
# Wipe all partitions and enforce GPT
echo "🛠️ Initializing disk /dev/nvme0n1 to GPT..."
sgdisk --zap-all /dev/nvme0n1

# Completely wipe the disk
echo "🔍 Checking for remnants of previous formatting..."
read -p "❓ Do you want to erase all signatures from disk /dev/nvme0n1? (y/N) " confirm_wipe
confirm_wipe=${confirm_wipe,,} # Convert to lowercase

if [[ "$confirm_wipe" == "o" || "$confirm_wipe" == "oui" ]]; then
  echo "🧹 Erasing disk signatures..."
  wipefs --all /dev/nvme0n1
  echo "✅ Wipe completed!"
else
  echo "🚫 Wipe canceled."
fi

# Check TPM
echo "🔍 Checking persistent objects in TPM..."
if [ -z "$handles" ]; then
  echo "✅ TPM already clean, no persistent entries found."
else
  echo "⚠️ The following objects are stored in TPM:"
  echo "$handles"

  read -p "❓ Do you want to delete them? (y/N) " confirm
  confirm=${confirm,,} # Convert to lowercase

  if [[ "$confirm" == "o" || "$confirm" == "oui" ]]; then
    echo "🧹 Removing persistent objects..."
    for handle in $handles; do
      echo "  ➜ Removing object: $handle"
      tpm2_evictcontrol -c "$handle" > /dev/null 2>&1
    done
  else
    echo "🚫 Deletion canceled."
  fi
fi

echo "🔄 Verifying after cleanup..."
remaining_persistent=$(tpm2_getcap handles-persistent)
remaining_transient=$(tpm2_getcap handles-transient)

if [ -z "$remaining_persistent" ] && [ -z "$remaining_transient" ]; then
  echo "✅ TPM successfully cleaned! 🎉"
else
  echo "⚠️ Some entries still persist:"
  echo "🔸 Persistent: $remaining_persistent"
  echo "🔸 Transient: $remaining_transient"
fi

# Create GPT partition table and EFI + LUKS partitions
echo "🛠️ Creating partitions on /dev/nvme0n1..."
sgdisk \
  --clear --align-end \
  --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI system partition" \
  --new=2:0:0 --typecode=2:8309 --change-name=2:"Linux LUKS" \
  /dev/nvme0n1

echo "✅ Partitioning completed."

# Set French keyboard layout for console
echo "⌨️ Setting French keyboard layout..."
loadkeys fr

# Remove all existing EFI boot entries
echo "🧹 Cleaning EFI boot entries..."
for bootnum in $(efibootmgr | grep -oP 'Boot\K[0-9A-F]{4}'); do
  echo "  → Deleting EFI Boot entry $bootnum"
  efibootmgr -b $bootnum -B
done

# Update GPG keys from live USB
echo "🔑 Updating GPG keys..."
pacman -Sy archlinux-keyring

# Format the EFI partition (optimized for 4K NVMe)
echo "💾 Formatting the EFI partition..."
mkfs.vfat -F 32 -n "SYSTEM" -S 4096 -s 1 /dev/nvme0n1p1

# Create LUKS encrypted container
echo "🔐 Creating LUKS encrypted container..."
cryptsetup \
  --type luks2 \
  --cipher aes-xts-plain64 \
  --hash sha512 \
  --iter-time 5000 \
  --key-size 512 \
  --pbkdf argon2id \
  --label "Linux LUKS" \
  --sector-size 4096 \
  --use-urandom \
  --verify-passphrase \
  luksFormat /dev/nvme0n1p2

# Open the LUKS container
echo "🔓 Unlocking the LUKS container..."
cryptsetup --allow-discards --persistent open --type luks2 /dev/nvme0n1p2 cryptarch

# Format LUKS container as Btrfs
echo "🗂 Formatting the LUKS container as Btrfs..."
mkfs.btrfs -L "Arch Linux" -s 4096 /dev/mapper/cryptarch

# Mount Btrfs root to create subvolumes
echo "🔧 Mounting Btrfs root..."
mount -o "$common_opts" /dev/mapper/cryptarch /mnt

if ! mountpoint -q /mnt; then
  echo "❌ Error: Could not mount /mnt!" >&2
  exit 1
fi

# Create subvolumes
echo "📂 Creating subvolumes..."
echo "  → Creating @"
btrfs subvolume create "/mnt/@"

for subvol in "${!subvolumes[@]}"; do
  echo "  → Creating $subvol"
  btrfs subvolume create "/mnt/$subvol"
done

# Unmount Btrfs root
umount /mnt

# Mount subvolumes with appropriate options
echo "🔗 Mounting subvolumes..."

# Mount root subvolume @ first
echo "🔗 Mounting root subvolume..."
echo "  → Mounting @ to /mnt"
mount -o "$common_opts,subvol=@" /dev/mapper/cryptarch /mnt

# Mount other subvolumes
echo "🔗 Mounting other subvolumes..."
for subvol in "${!subvolumes[@]}"; do
  echo "  → Mounting $subvol to ${subvolumes[$subvol]}"
  case "$subvol" in
    @home|@games) opts="$common_opts,$home_opts" ;;
    @swap|@snapshots|@efibck|@log|@pkg|@vms|@tmp|@srv) opts="$common_opts,$extra_opts" ;;
  esac
  mkdir -p "${subvolumes[$subvol]}"
  mount -o "$opts,subvol=$subvol" /dev/mapper/cryptarch "${subvolumes[$subvol]}"
done

# Mount EFI separately
echo "🔗 Mounting SYSTEM EFI partition..."
echo "  → Mounting /dev/nvme0n1p1 to /mnt/efi"
mkdir /mnt/efi
mount -o "$efi_opts" /dev/nvme0n1p1 /mnt/efi

# Create Btrfs swapfile
echo "💾 Creating swapfile..."
btrfs filesystem mkswapfile --size 4g /mnt/.swap/swapfile
chmod 600 /mnt/.swap/swapfile

if [[ ! -f /mnt/.swap/swapfile ]]; then
  echo "❌ Error: Swapfile not created!" >&2
  exit 1
fi

# Install base packages
echo "📦 Installing base packages..."
pacstrap /mnt base base-devel linux linux-headers linux-firmware amd-ucode neovim efibootmgr btrfs-progs sbctl plymouth zram-generator

# Generate fstab with fsck enabled for @
echo "📝 Generating fstab..."
genfstab -U /mnt | awk '
  /subvol=\/@([[:space:]]|,)/ { $6="1" }
  { print $1"\t"$2"\t\t"$3"\t\t"$4"\t"$5,$6 }
' >> /mnt/etc/fstab

echo -e "\n📊 Installation summary:"

# Check if disk is GPT
PART_TABLE=$(lsblk -o PTTYPE -nr /dev/nvme0n1 | head -n 1)
if [[ "$PART_TABLE" == "gpt" ]]; then
  echo -e "✅ Partitioning type: GPT"
else
  echo -e "❌ Partitioning type: NOT GPT ($PART_TABLE)"
fi
read -p "↩️  Press Enter to continue..."

# Check if partitions are aligned
PART1_ALIGN=$(parted /dev/nvme0n1 align-check optimal 1)
PART2_ALIGN=$(parted /dev/nvme0n1 align-check optimal 2)
if [[ "$PART1_ALIGN" == "1 aligned" && "$PART2_ALIGN" == "2 aligned" ]]; then
  echo -e "✅ Optimal alignment for EFI and LUKS partitions"
else
  echo -e "❌ Non-optimal alignment for EFI and LUKS partitions ($PART1_ALIGN / $PART2_ALIGN)"
fi
read -p "↩️  Press Enter to continue..."

# Check if NVMe uses physical 4K sectors
PHYSICAL_BLOCK_SIZE=$(cat /sys/block/nvme0n1/queue/physical_block_size)
if [[ "$PHYSICAL_BLOCK_SIZE" == "4096" ]]; then
  echo -e "✅ NVMe disk detected with physical block size of 4K"
else
  echo -e "❌ Warning: Disk has physical block size of $PHYSICAL_BLOCK_SIZE (not 4K)"
fi
read -p "↩️  Press Enter to continue..."

# List partitions with size, format, label
echo -e "\n🖥️  Partition list:"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT -nr /dev/nvme0n1
read -p "↩️  Press Enter to continue..."

# List Btrfs subvolumes and mount points
echo -e "\n📁 Btrfs subvolumes and mount points:"
if btrfs subvolume list -p /mnt &>/dev/null; then
  btrfs subvolume list -p /mnt | awk '{print "  ➜ " $NF}'
else
  echo "❌ Could not list subvolumes!"
fi
read -p "↩️  Press Enter to continue..."

# Check swapfile presence
if [[ -f /mnt/.swap/swapfile ]]; then
  echo -e "\n🟡 Swapfile detected: /mnt/.swap/swapfile"
else
  echo -e "\n⚠️  No swapfile detected!"
fi
read -p "↩️  Press Enter to continue..."

# Check and display fstab
echo -e "\n📄 Checking fstab file:"
if [[ -f /mnt/etc/fstab ]]; then
  echo -e "✅ fstab found! Here's a preview:"
  du -sh /mnt/etc/fstab
  echo -e "\n📝 fstab content:"
  cat /mnt/etc/fstab
else
  echo -e "❌ fstab not found!"
fi
read -p "↩️  Press Enter to continue..."

# End
echo -e "\n🚀 Base installation complete!"
echo -e "🐧 You can now chroot into the system to continue setup:\n"
echo -e "   ➜  \e[1;32march-chroot /mnt\e[0m"
