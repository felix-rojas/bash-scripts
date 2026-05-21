#!/usr/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: sudo required."
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Kills all processes related to a user."
    echo "Usage: $0 <username>"
    echo "Example: $0 user"
    exit 1
fi

target_user="$1"

# Check if the user actually exists before trying to kill their processes
if ! id "$target_user" &>/dev/null; then
    echo "Error: User '$target_user' does not exist."
    exit 1
fi

echo "Killing all processes for user: $target_user..."
pkill -9 -u "$target_user"

echo "Done."
