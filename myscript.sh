#!/bin/bash
set -euo pipefail

DISK="/dev/nvme0n1"

# === CHANGE THIS to your Wi-Fi credentials ===
WIFI_SSID="Rooftop 5.0"
WIFI_PASS="060120070301200921082010"

echo ">>> Leaving $DISK partitions 1-3 alone (Windows boot/system)"

echo ">>> Creating 1G EFI partition for Arch (p4)"
parted -s "$DISK" mkpart ESP fat32 528.4GiB 529.4GiB
parted -s "$DISK" set 4 esp on

echo ">>> Creating 10G swap partition (p5)"
parted -s "$DISK" mkpart primary linux-swap 529.4GiB 539.4GiB

echo ">>> Creating root partition with remaining space (p6, Btrfs)"
parted -s "$DISK" mkpart primary btrfs 539.4GiB 100%

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

echo ">>> Connecting to Wi-Fi"
systemctl start iwd
iwctl --passphrase "$WIFI_PASS" station wlan0 connect "$WIFI_SSID"

echo ">>> Checking connection"
ping -c 3 archlinux.org || echo "⚠️ Wi-Fi connection failed, check SSID/PASSWORD"

echo ">>> DONE - Arch partitions created, mounted, Wi-Fi ready"
lsblk "$DISK"