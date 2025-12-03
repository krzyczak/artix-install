#!/usr/bin/env bash
#
# A simple installer for Artix Linux
#
# Authors:
# Copyright (c) 2025 krzyczak (https://github.com/krzyczak)
# Copyright (c) 2022 Maxwell Anderson
#
# This file is part of artix-installer.
#
# artix-installer is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# artix-installer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with artix-installer. If not, see <https://www.gnu.org/licenses/>.

VERSION="2.3.0"

usage() {
  echo "artix-install $VERSION"
  echo "Usage:"
  echo "  artix-install                 # run with defaults"
  echo "  artix-install -v|--version    # print version info"
  echo "  artix-install <config_path>   # run with config"
}

case "$1" in
  -v|--version)
    usage
    exit 0
    ;;
  *)
    ;;
esac

set -euo pipefail

OPTIONS=(
  X_LANGCODE
  X_KEYMAP
  X_REGION_CITY
  X_INIT
  X_FILE_SYSTEM
  X_DISK
  X_ENCRYPTED
  X_CRYPTPASS
  X_ROOT_PASSWORD
  X_USERNAME
  X_HOSTNAME
  X_GRUB_THEME
  X_INSTALL_DOCKER
  X_ENABLE_WIFI
)

declare -A LABELS=(
  [X_LANGCODE]="Language"
  [X_KEYMAP]="Keyboard Layout"
  [X_REGION_CITY]="Region / City"
  [X_INIT]="Init System"
  [X_FILE_SYSTEM]="File System"
  [X_DISK]="Disk"
  [X_ENCRYPTED]="Encrypted Disk"
  [X_CRYPTPASS]="Crypt Password"
  [X_ROOT_PASSWORD]="Root Password"
  [X_USERNAME]="Username"
  [X_HOSTNAME]="Hostname"
  [X_GRUB_THEME]="Grub theme"
  [X_INSTALL_DOCKER]="Install Docker"
  [X_ENABLE_WIFI]="Enable WiFi"
  [SAVE_AND_EXIT]="Save and Exit"
)

declare -A LABELS_INVERTED=(
  [Language]="X_LANGCODE"
  [Keyboard Layout]="X_KEYMAP"
  [Region / City]="X_REGION_CITY"
  [Init System]="X_INIT"
  [File System]="X_FILE_SYSTEM"
  [Disk]="X_DISK"
  [Encrypted Disk]="X_ENCRYPTED"
  [Crypt Password]="X_CRYPTPASS"
  [Root Password]="X_ROOT_PASSWORD"
  [Username]="X_USERNAME"
  [Hostname]="X_HOSTNAME"
  [Grub theme]="X_GRUB_THEME"
  [Install Docker]="X_INSTALL_DOCKER"
  [Enable WiFi]="X_ENABLE_WIFI"
  [Save and Exit]="SAVE_AND_EXIT"
)

# Associative array for option → value
declare -A VALS
for opt in "${OPTIONS[@]}"; do VALS["$opt"]=""; done

confirm_password() {
  local prompt="$1"
  local pass1 pass2
  local info=""

  while true; do
    pass1=$(gum input --password --placeholder "$info Enter $prompt")
    [[ -n "$pass1" ]] || {
      info="Password cannot be empty!"
      continue;
    }

    pass2=$(gum input --password --placeholder "Confirm $prompt")

    if [[ "$pass1" == "$pass2" ]]; then
      echo "$pass2"
      return 0
    else
      info="Paswords didn't match. Try again."
    fi
  done
}

load_csv() {
  local file="$1"
  while IFS='=' read -r k v; do
    [[ -z "$k" ]] && continue
    VALS["$k"]="$v"
  done < "$file"
}

save_csv() {
  local file="$1"
  : > "$file"
  for opt in "${OPTIONS[@]}"; do
    printf "%s=%s\n" "$opt" "${VALS[$opt]}" >> "$file"
  done
}

map_keymap() {
  case "$1" in
  "en_GB")
    echo "uk" ;;
  "en_US")
    echo "us" ;;
  *)
    echo "$1" | cut -c1-2
    ;;
  esac
}

move_to_bottom() {
  local key="$1"
  local tmp=()
  for opt in "${OPTIONS[@]}"; do
    [[ "$opt" == "$key" ]] && continue
    tmp+=("$opt")
  done
  tmp+=("$key")
  OPTIONS=("${tmp[@]}")
}

select_block_device() {
  # Collect drive list (excluding loop devices)
  DRIVES=$(lsblk -dnpo NAME,SIZE,MODEL | grep -v loop)

  # Format entries for gum choose
  CHOICES=""
  while read -r line; do
    DEV=$(echo "$line" | awk '{print $1}')
    SIZE=$(echo "$line" | awk '{print $2}')
    MODEL=$(echo "$line" | cut -d' ' -f3-)
    CHOICES+="${DEV} — ${MODEL} (${SIZE})"$'\n'
  done <<< "$DRIVES"

  # Ask user to choose
  SELECTED=$(echo -e "$CHOICES" | gum choose)

  # Extract only "/dev/sdX" part from selected line
  SELECTED_DRIVE=$(echo "$SELECTED" | awk '{print $1}')

  echo $SELECTED_DRIVE
}

[[ $# -eq 1 ]] && load_csv "$1"

gum style --border double --margin 1 --padding "1 2" --bold --foreground "#00FFFF" "Artix Linux Installer Configuration"

while true; do
  rows=""
  for opt in "${OPTIONS[@]}"; do
    case $opt in
      X_CRYPTPASS|X_ROOT_PASSWORD)
        rows+="${LABELS[$opt]},"${VALS[$opt]:+***}""$'\n'
        ;;
      *)
        rows+="${LABELS[$opt]},${VALS[$opt]}"$'\n'
        ;;
    esac
  done
  rows+="Save and Exit,"$'\n'
  rows+="Exit without saving,"$'\n'
  rows+="Install using selected settings,"$'\n'

  choice=$(printf "%s" "$rows" |
    gum table -c "Option,Value" \
      --widths 35,40 \
      --border rounded \
      --header.background "#333355")

  selected_label="${choice%%,*}"
  key="${LABELS_INVERTED[$selected_label]:-$selected_label}"

  case "$key" in
    SAVE_AND_EXIT)
      out="${1:-artix-install.conf}"
      save_csv "$out"
      printf "Configuration saved to %s\n" "$out"
      exit 0
      ;;

    X_LANGCODE)
      lang=$(gum filter "en_US" "en_GB" "de_DE" "fr_FR" "pl_PL" --header "Language code" --placeholder "Language code")
      VALS[X_LANGCODE]="$lang"
      VALS[X_KEYMAP]="$(map_keymap "$lang")"
      move_to_bottom "$key"
      move_to_bottom "X_KEYMAP"
      sudo loadkeys "${VALS[X_KEYMAP]}"
      ;;

    X_REGION_CITY)
      timezones=$(find /usr/share/zoneinfo/posix -type f -printf "%P\n")
      VALS[$key]=$(gum filter --placeholder "Europe/Jersey" $timezones)
      move_to_bottom "$key"
      ;;

    X_INIT)
      VALS[$key]=$(gum choose "openrc" "dinit" --header "Init system")
      move_to_bottom "$key"
      ;;

    X_FILE_SYSTEM)
      VALS[$key]=$(gum choose "btrfs" "ext4" --header "File system")
      move_to_bottom "$key"
      ;;

    X_DISK)
      VALS[$key]=$(select_block_device)
      move_to_bottom "$key"
      ;;

    X_ENCRYPTED)
      VALS[$key]=$(gum choose yes no | cut -b 1)
      if [[ "${VALS[$key]}" == "y" ]]; then
        VALS[X_CRYPTPASS]=$(confirm_password "LUKS encryption passphrase")
      fi
      move_to_bottom "$key"
      move_to_bottom "X_CRYPTPASS"
      ;;

    # TODO: Add this or leave it as is?
    # X_CRYPTPASS)
    #   VALS[$key]=$(confirm_password "LUKS encryption passphrase")
    #   VALS[X_ENCRYPTED]="y"
    #   move_to_bottom "X_ENCRYPTED"
    #   move_to_bottom "$key"
    #   ;;

    X_ROOT_PASSWORD)
      VALS[$key]=$(confirm_password "root password")
      move_to_bottom "$key"
      ;;

    X_USERNAME|X_HOSTNAME)
      label=$(echo $key | tr -d X_ | tr '[:upper:]' '[:lower:]')
      VALS[$key]=$(gum input --placeholder "Enter $label")
      move_to_bottom "$key"
      ;;

    X_GRUB_THEME)
      VALS[$key]=$(gum choose "catppuccin" "none" --header "Select grub theme")
      move_to_bottom "$key"
      ;;

    X_INSTALL_DOCKER|X_ENABLE_WIFI)
      VALS[$key]=$(gum choose yes no | cut -b 1)
      move_to_bottom "$key"
      ;;

    "Install using selected settings")
      break
      ;;

    "Exit without saving")
      exit 0
      ;;

    *)
      ;;
  esac
done

gum style --border double --margin 1 --padding "1 2" \
  --bold --foreground "#00FFFF" \
  "Configuration complete." \
  "The selected device will be wiped." \
  "This is your last chance to abort."

gum confirm "Do you want to continue?"

gum spin --spinner points --title "Probing mirrors..." -- \
  sh -c 'rankmirrors -v -n 5 /etc/pacman.d/mirrorlist \
    | grep "^Server =" \
    | cat - /etc/pacman.d/mirrorlist \
    | sudo tee /etc/pacman.d/mirrorlist.new > /dev/null'

mv /etc/pacman.d/mirrorlist.new /etc/pacman.d/mirrorlist
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

for key in "${!VALS[@]}"; do
  varname=$(echo "$key" | tr '[:lower:]' '[:upper:]')
  printf -v "$varname" "%s" "${VALS[$key]}"
done

SWAP_SIZE=8
PART1="$X_DISK"1
PART2="$X_DISK"2
case "$X_DISK" in
*"nvme"* | *"mmcblk"*)
  PART1="$X_DISK"p1
  PART2="$X_DISK"p2
  ;;
esac

if [ "$X_ENCRYPTED" = "y" ]; then
  MY_ROOT="/dev/mapper/root"
else
  MY_ROOT=$PART2
  [ "$X_FILE_SYSTEM" = "ext4" ] && MY_ROOT=$PART2
fi


BASE_DIR=$(dirname "$(realpath "$0")")
MOD_DIR="$BASE_DIR/modules"

# Install
sudo INSTALL_DOCKER=$X_INSTALL_DOCKER \
  ENABLE_WIFI=$X_ENABLE_WIFI MY_INIT="$X_INIT" \
  MY_DISK="$X_DISK" PART1="$PART1" PART2="$PART2" SWAP_SIZE="$SWAP_SIZE" \
  MY_FS="$X_FILE_SYSTEM" ENCRYPTED="$X_ENCRYPTED" CRYPTPASS="$X_CRYPTPASS" \
  MY_ROOT="$MY_ROOT" \
  "$MOD_DIR/installer.sh"

if [ "$X_ENABLE_WIFI" = "y" ]; then
  # Copy over current WiFi config to new host.

  # TODO: Update X_ENABLE_WIFI to instead ask for the WiFi manager to be used: "NetworkManager", "iwd", etc.
  # And then copy relevant files.

  # For iwd:
  # mkdir -p /mnt/var/lib/iwd
  # cp -a /var/lib/iwd/* /mnt/var/lib/iwd/
  # chown -R root:root /mnt/var/lib/iwd
  # # chmod 600 /mnt/var/lib/iwd/*.80211x # TODO: Why chatgpt also suggested this?
  # chmod 600 /mnt/var/lib/iwd/*.psk

  # For NetworkManager with wpa_supplicant:
  mkdir -p /mnt/etc/NetworkManager/system-connections
  cp -a /etc/NetworkManager/system-connections/* /mnt/etc/NetworkManager/system-connections/
  chmod 600 /mnt/etc/NetworkManager/system-connections/*.nmconnection
  chown root:root /mnt/etc/NetworkManager/system-connections/*.nmconnection
fi

sudo cp "$MOD_DIR/iamchroot.sh" /mnt/root/ &&
  sudo INSTALL_DOCKER=$X_INSTALL_DOCKER ENABLE_WIFI=$X_ENABLE_WIFI \
    REGION_CITY="$X_REGION_CITY" MY_HOSTNAME="$X_HOSTNAME" \
    MY_USER=$X_USERNAME ROOT_PASSWORD="$X_ROOT_PASSWORD" MY_INIT="$X_INIT" \
    PART2="$PART2" MY_FS="$X_FILE_SYSTEM" \
    ENCRYPTED="$X_ENCRYPTED" CRYPTPASS="$X_CRYPTPASS" \
    LANGCODE="$X_LANGCODE" MY_KEYMAP="$X_KEYMAP" \
    X_GRUB_THEME="$X_GRUB_THEME" \
    artix-chroot /mnt sh -ec './root/iamchroot.sh; rm /root/iamchroot.sh; exit' &&
  printf '\nYou may now poweroff.\n'

# TODO: Is sudo really needed in the linve above?
# TODO: Why ./root/iamchroot.sh instead of /root/iamchroot.sh?
