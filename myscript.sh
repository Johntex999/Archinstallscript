#!/bin/bash
set -euo pipefail

DISK="/dev/nvme0n1"

echo ">>> Leaving $DISK partitions 1-3 alone (Windows boot/system)"

# === Calculate start of new partitions dynamically ===
LAST_PART_END=$(parted -s "$DISK" unit MiB print | awk '/^ 3 / {gsub("MiB","",$3); print $3}')
EFI_START=$((LAST_PART_END + 1))
EFI_END=$((EFI_START + 1024))     # 1GB EFI

SWAP_START=$((EFI_END + 1))
SWAP_END=$((SWAP_START + 10240))  # 10GB Swap

ROOT_START=$((SWAP_END + 1))      # Rest of disk

echo ">>> Creating 1G EFI partition for Arch (p4)"
parted -s "$DISK" mkpart ESP fat32 "${EFI_START}MiB" "${EFI_END}MiB"
parted -s "$DISK" set 4 esp on

echo ">>> Creating 10G swap partition (p5)"
parted -s "$DISK" mkpart primary linux-swap "${SWAP_START}MiB" "${SWAP_END}MiB"

echo ">>> Creating root partition with remaining space (p6, Btrfs)"
parted -s "$DISK" mkpart primary btrfs "${ROOT_START}MiB" 100%

# Assign partitions
BOOT_PART="${DISK}p4"
SWAP_PART="${DISK}p5"
ROOT_PART="${DISK}p6"

echo ">>> Formatting Arch EFI partition (p4) as FAT32"
mkfs.fat -F32 "$BOOT_PART"

echo ">>> Formatting swap partition (p5)"
mkswap "$SWAP_PART"

echo ">>> Formatting root partition (p6) as Btrfs"
mkfs.btrfs -f "$ROOT_PART"

echo ">>> Mounting partitions"
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot
swapon "$SWAP_PART"

echo ">>> DONE - Arch partitions created and mounted"
lsblk "$DISK"

# === Run next script ===
echo ">>> Running archinstall..."
bash ./run_archinstall.sh
