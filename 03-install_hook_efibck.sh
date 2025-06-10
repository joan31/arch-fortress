#!/bin/bash
## 🚀 INSTALLATION DU HOOK PACMAN EFI BACKUP
## ./install_hook_efibck.sh
## By Joan https://github.com/joan31/

HOOK_PATH="/etc/pacman.d/hooks/10-efi_backup.hook"
SCRIPT_PATH="/usr/local/sbin/efi_backup.sh"
BACKUP_DIR="/.efibackup"
SELF_PATH="$(realpath "$0")"

# 🔒 Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Ce script doit être exécuté en tant que root." >&2
    exit 1
fi

# 📁 Création du répertoire de hook s'il n'existe pas
if [[ ! -d "/etc/pacman.d/hooks" ]]; then
    mkdir -p /etc/pacman.d/hooks
    echo "✅ Répertoire /etc/pacman.d/hooks créé."
fi

# 💾 Création du répertoire de sauvegarde EFI s'il n'existe pas
if [[ ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
    echo "✅ Répertoire de sauvegarde $BACKUP_DIR créé."
fi

# ✏️ Copie du hook
cat << EOF > "$HOOK_PATH"
## 🪝 HOOK PACMAN EFI BACKUP
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
When = PostTransaction
Exec = /usr/local/sbin/efi_backup.sh
EOF

# 📝 Copie du script de sauvegarde EFI
cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash
## 🗃️ SCRIPT EFI BACKUP
## /usr/local/sbin/efi_backup.sh
## By Joan https://github.com/joan31/

tar -czf "/.efibackup/efi-$(date +%Y%m%d-%H%M%S).tar.gz" -C / efi
ls -1t /.efibackup/efi-*.tar.gz | tail -n +4 | xargs -r rm --
EOF

# 🔑 Attribution des permissions
chmod 755 "$SCRIPT_PATH"
chmod 644 "$HOOK_PATH"
echo "🔧 Permissions définies."

# 🌟 Première sauvegarde
echo "🗃️ Lancement d'une première sauvegarde EFI..."
bash "$SCRIPT_PATH"
echo "✅ Première sauvegarde effectuée."

# 🧹 Suppression du script d'installation
echo "🗑️ Suppression du script d'installation : $SELF_PATH"
rm -f "$SELF_PATH"
echo "🎉 Installation et nettoyage effectués avec succès."