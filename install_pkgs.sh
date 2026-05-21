#!/usr/bin/bash

# check pkgs.txt for example usage

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <packages_file.txt>"
    exit 1
fi

PACKAGE_FILE="$1"

# 2. Check if the file exists
if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Error: File '$PACKAGE_FILE' not found."
    exit 1
fi

# grep -vE '^\s*#|^\s*$' removes everything after # and blank lines
PACKAGES=$(grep -vE '^\s*#|^\s*$' "$PACKAGE_FILE" | tr '\n' ' ')

if [[ -z "$PACKAGES" ]]; then
    echo "Error: No packages found in '$PACKAGE_FILE'."
    exit 1
fi

# $PACKAGES is split by bash into individual arguments
apt install -s $PACKAGES 2>/dev/null | awk '/^Inst/ {print $2}' | xargs -r apt install -y && apt autoremove
