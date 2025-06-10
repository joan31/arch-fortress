#!/bin/bash
## INSTALLATION ARCH LINUX - BASE
## SYSTEMD INIT - LUKS - BTRFS - UKI - SECURE BOOT
## ./arch_baseinstall.sh
## By Joan https://github.com/joan31/

set -e  # Arrêter le script en cas d'erreur

## VARIABLES
# Définition des options communes de montage
common_opts="rw,noatime,nodiratime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120"
extra_opts="nodev,nosuid,noexec"
home_opts="nodev,nosuid"
efi_opts="rw,noatime,nodiratime,nodev,nosuid,noexec,fmask=0077,dmask=0077"

# Définition des subvolumes et leurs points de montage
declare -A subvolumes=(
    [@swap]="/mnt/.swap"
    [@snapshots]="/mnt/.snapshots"
    [@efibck]="/mnt/.efibackup"
    [@log]="/mnt/var/log"
    [@pkg]="/mnt/var/cache/pacman/pkg"
    [@vms]="/mnt/var/lib/libvirt/images"
    [@tmp]="/mnt/tmp"
    [@home]="/mnt/home"
    [@srv]="/mnt/srv"
)

# TPM
handles=$(tpm2_getcap handles-persistent | awk '{print $2}')

## MAIN
# Supprime toutes les partitions et force GPT
echo "🛠️ Initialisation du disque /dev/nvme0n1 en GPT..."
sgdisk --zap-all /dev/nvme0n1

# Wipe complètement le disque
echo "🔍 Vérification des artefacts d'un formatage précédent..."
read -p "❓ Veux-tu effacer toutes les signatures du disque /dev/nvme0n1 ? (o/N) " confirm_wipe
confirm_wipe=${confirm_wipe,,} # Conversion en minuscule

if [[ "$confirm_wipe" == "o" || "$confirm_wipe" == "oui" ]]; then
    echo "🧹 Suppression des signatures du disque..."
    wipefs --all /dev/nvme0n1
    echo "✅ Wipe terminé !"
else
    echo "🚫 Wipe annulé."
fi

# Vérifier le TPM
echo "🔍 Vérification des objets persistants dans le TPM..."
if [ -z "$handles" ]; then
    echo "✅ TPM déjà vide, aucune entrée persistante à supprimer."
else
    echo "⚠️ Les objets suivants sont stockés dans le TPM :"
    echo "$handles"

    read -p "❓ Veux-tu les supprimer ? (o/N) " confirm
    confirm=${confirm,,} # Conversion en minuscule

    if [[ "$confirm" == "o" || "$confirm" == "oui" ]]; then
        echo "🧹 Suppression des objets persistants..."
        for handle in $handles; do
            echo "  ➜ Suppression de l'objet : $handle"
            tpm2_evictcontrol -c "$handle" > /dev/null 2>&1
        done
    else
        echo "🚫 Suppression annulée."
    fi
fi

echo "🔄 Vérification après suppression..."
remaining_persistent=$(tpm2_getcap handles-persistent)
remaining_transient=$(tpm2_getcap handles-transient)

if [ -z "$remaining_persistent" ] && [ -z "$remaining_transient" ]; then
    echo "✅ TPM nettoyé avec succès ! 🎉"
else
    echo "⚠️ Certaines entrées persistent encore :"
    echo "🔸 Persistent: $remaining_persistent"
    echo "🔸 Transient: $remaining_transient"
fi

# Création de la table de partition GPT et des partitions EFI + LUKS avec sgdisk
echo "🛠️ Création des partitions sur /dev/nvme0n1..."
sgdisk \
    --clear --align-end \
    --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI system partition" \
    --new=2:0:0 --typecode=2:8309 --change-name=2:"Linux LUKS" \
    /dev/nvme0n1
       
echo "✅ Partitionnement terminé."

# Activation du clavier français pour la console
echo "⌨️ Activation du clavier français..."
loadkeys fr

# Suppression de toutes les entrées EFI existantes
echo "🧹 Nettoyage des entrées EFI..."
for bootnum in $(efibootmgr | grep -oP 'Boot\K[0-9A-F]{4}'); do
    echo "  → Suppression de l'entrée EFI Boot$bootnum"
    efibootmgr -b $bootnum -B
done

# Mise à jour des clés GPG du live USB
echo "🔑 Mise à jour des clés GPG..."
pacman -Sy archlinux-keyring

# Formatage de la partition EFI (optimisation pour NVMe 4K)
echo "💾 Formatage de la partition EFI..."
mkfs.vfat -F 32 -n "SYSTEM" -S 4096 -s 1 /dev/nvme0n1p1

# Création du conteneur chiffré LUKS
echo "🔐 Création du conteneur chiffré LUKS..."
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

# Accès au conteneur LUKS
echo "🔓 Déverrouillage du conteneur LUKS..."
cryptsetup --allow-discards --persistent open --type luks2 /dev/nvme0n1p2 cryptarch

# Formatage du conteneur LUKS en Btrfs
echo "🗂 Formatage du conteneur LUKS en Btrfs..."
mkfs.btrfs -L "Arch Linux" -s 4096 /dev/mapper/cryptarch

# Monter la racine du Btrfs pour créer les subvolumes
echo "🔧 Montage de la racine Btrfs..."
mount -o "$common_opts" /dev/mapper/cryptarch /mnt

if ! mountpoint -q /mnt; then
    echo "❌ Erreur : Impossible de monter /mnt !" >&2
    exit 1
fi

# Création des subvolumes
echo "📂 Création des subvolumes..."
echo "  → Création de @"
btrfs subvolume create "/mnt/@"

for subvol in "${!subvolumes[@]}"; do
    echo "  → Création de $subvol"
    btrfs subvolume create "/mnt/$subvol"
done

# Démonter la racine Btrfs
umount /mnt

# Monter les subvolumes avec les options appropriées
echo "🔗 Montage des subvolumes..."

# Monter la racine root @ en premier
echo "🔗 Montage du subvolume racine..."
echo "  → Montage de @ sur /mnt"
mount -o "$common_opts,subvol=@" /dev/mapper/cryptarch /mnt

# Monter les autres subvolumes
echo "🔗 Montage des autres subvolumes..."
for subvol in "${!subvolumes[@]}"; do
    echo "  → Montage de $subvol sur ${subvolumes[$subvol]}"
    case "$subvol" in
        @home) opts="$common_opts,$home_opts" ;;
        @swap|@snapshots|@efibck|@log|@pkg|@vms|@tmp|@srv) opts="$common_opts,$extra_opts" ;;
    esac
    mkdir -p "${subvolumes[$subvol]}"
    mount -o "$opts,subvol=$subvol" /dev/mapper/cryptarch "${subvolumes[$subvol]}"
done

# Monter EFI séparément
echo "🔗 Montage de la partition SYSTEM EFI..."
echo "  → Montage de /dev/nvme0n1p1 sur /mnt/efi"
mkdir /mnt/efi
mount -o "$efi_opts" /dev/nvme0n1p1 /mnt/efi

# Création du swapfile Btrfs
echo "💾 Création du swapfile..."
btrfs filesystem mkswapfile --size 4g /mnt/.swap/swapfile
chmod 600 /mnt/.swap/swapfile

if [[ ! -f /mnt/.swap/swapfile ]]; then
    echo "❌ Erreur : Swapfile non créé !" >&2
    exit 1
fi

# Installation des paquets de base
echo "📦 Installation des paquets de base..."
pacstrap /mnt base base-devel linux linux-firmware amd-ucode neovim efibootmgr btrfs-progs sbctl

# Génération du fichier fstab avec activation de fsck pour @
echo "📝 Génération du fichier fstab..."
genfstab -U /mnt | awk '
    /subvol=\/@([[:space:]]|,)/ { $6="1" }
    { print $1"\t"$2"\t\t"$3"\t\t"$4"\t"$5,$6 }
' >> /mnt/etc/fstab

echo -e "\n📊 Récapitulatif de l'installation :"

# Vérifier si le disque est en GPT
PART_TABLE=$(lsblk -o PTTYPE -nr /dev/nvme0n1 | head -n 1)
if [[ "$PART_TABLE" == "gpt" ]]; then
    echo -e "✅ Type de partitionnement : GPT"
else
    echo -e "❌ Type de partitionnement : NON GPT ($PART_TABLE)"
fi
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Vérifier si les partitions sont bien alignés
PART1_ALIGN=$(parted /dev/nvme0n1 align-check optimal 1)
PART2_ALIGN=$(parted /dev/nvme0n1 align-check optimal 2)
if [[ "$PART1_ALIGN" == "1 aligned" && "$PART2_ALIGN" == "2 aligned" ]]; then
    echo -e "✅ Alignement optimal des partitions EFI et LUKS"
else
    echo -e "❌ Alignement non optimal des partitions EFI et LUKS ($PART1_ALIGN / $PART2_ALIGN)"
fi
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Vérifier si le NVMe est bien en secteur physique 4K
PHYSICAL_BLOCK_SIZE=$(cat /sys/block/nvme0n1/queue/physical_block_size)
if [[ "$PHYSICAL_BLOCK_SIZE" == "4096" ]]; then
    echo -e "✅ Disque NVMe détecté avec une taille physique de 4K"
else
    echo -e "❌ Attention : Le disque a une taille de bloc physique de $PHYSICAL_BLOCK_SIZE (pas 4K)"
fi
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Liste des partitions avec taille, format, nom
echo -e "\n🖥️  Liste des partitions :"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT -nr /dev/nvme0n1
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Liste des subvolumes Btrfs et points de montage
echo -e "\n📁 Subvolumes Btrfs et points de montage :"
if btrfs subvolume list -p /mnt &>/dev/null; then
    btrfs subvolume list -p /mnt | awk '{print "  ➜ " $NF}'
else
    echo "❌ Impossible de lister les subvolumes !"
fi
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Vérifier la présence de la swapfile
if [[ -f /mnt/.swap/swapfile ]]; then
    echo -e "\n🟡 Swapfile détectée : /mnt/.swap/swapfile"
else
    echo -e "\n⚠️  Aucune swapfile détectée !"
fi
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Vérifier la présence et le contenu du fstab
echo -e "\n📄 Vérification du fichier fstab :"
if [[ -f /mnt/etc/fstab ]]; then
    echo -e "✅ fstab détecté ! Voici un aperçu :"
    du -sh /mnt/etc/fstab
    echo -e "\n📝 Contenu du fstab :"
    cat /mnt/etc/fstab
else
    echo -e "❌ fstab non trouvé !"
fi
read -p "↩️  Appuyez sur Entrée pour continuer..."

# Fin
echo -e "\n🚀 Installation de base terminée !"
echo -e "🐧 Vous pouvez maintenant entrer dans l'environnement chroot pour configurer votre système :\n"
echo -e "   ➜  \e[1;32march-chroot /mnt\e[0m"