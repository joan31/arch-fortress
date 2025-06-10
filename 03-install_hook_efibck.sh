#!/bin/bash
## 🚀 INSTALLATION OF THE PACMAN EFI BACKUP HOOK
## ./install_hook_efibck.sh
## By Joan https://github.com/joan31/

HOOK_PATH="/etc/pacman.d/hooks/10-efi_backup.hook"
SCRIPT_PATH="/usr/local/sbin/efi_backup.sh"
BACKUP_DIR="/.efibackup"
SELF_PATH="$(realpath "$0")"

# 🔒 Checking for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root." >&2
    exit 1
fi

# 📁 Create the hooks directory if it doesn't exist
if [[ ! -d "/etc/pacman.d/hooks" ]]; then
    mkdir -p /etc/pacman.d/hooks
    echo "✅ Directory /etc/pacman.d/hooks created."
fi

# 💾 Create the EFI backup directory if it doesn't exist
if [[ ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
    echo "✅ Backup directory $BACKUP_DIR created."
fi

# ✏️ Copy the hook
cat << EOF > "$HOOK_PATH"
## 🪝 PACMAN EFI BACKUP HOOK
## /etc/pacman.d/hooks/10-efi_backup.hook
## By Joan https://github.com/joan31/

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
Description = 📦 Backing up /efi...
When = PreTransaction
Exec = /usr/local/sbin/efi_backup.sh
EOF

# 📝 Copy the EFI backup script
cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash
## 🗃️ EFI BACKUP SCRIPT
## /usr/local/sbin/efi_backup.sh
## By Joan https://github.com/joan31/

tar -czf "/.efibackup/efi-$(date +%Y%m%d-%H%M%S).tar.gz" -C / efi
ls -1t /.efibackup/efi-*.tar.gz | tail -n +4 | xargs -r rm --
EOF

# 🔑 Set permissions
chmod 755 "$SCRIPT_PATH"
chmod 644 "$HOOK_PATH"
echo "🔧 Permissions set."

# 🌟 Initial backup
echo "🗃️ Starting initial EFI backup..."
bash "$SCRIPT_PATH"
echo "✅ Initial backup completed."

# 🧹 Remove installation script
echo "🗑️ Removing installation script: $SELF_PATH"
rm -f "$SELF_PATH"
echo "🎉 Installation and cleanup completed successfully."
