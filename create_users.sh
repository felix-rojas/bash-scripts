#!/usr/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root to create users."
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <users_file.txt>"
    exit 1
fi

INPUT_FILE="$1"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

while read -r line; do
    # Skip empty lines or comments
    [[ -z "$line" || "$line" == \#* ]] && continue

    # Regex matches: ID, "Full Name", Directory, and captures the rest
    if [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+\"([^\"]+)\"[[:space:]]+([^[:space:]]+)(.*)$ ]]; then
        user_id="${BASH_REMATCH[1]}"
        user_full_name="${BASH_REMATCH[2]}"
        user_directory="${BASH_REMATCH[3]}"
        
        # remaining positional fields
        read -r user_shell user_group user_password is_sudoer <<< "${BASH_REMATCH[4]}"
        
        # useradd command
        cmd=(useradd -c "$user_full_name" -d "$user_directory" -m)

        # apply shell if provided
        if [[ -n "$user_shell" && "$user_shell" != "-" ]]; then
            cmd+=(-s "$user_shell")
        fi

        # apply group if provided 
        if [[ -n "$user_group" && "$user_group" != "-" ]]; then
            cmd+=(-g "$user_group")
        fi

        # append user_id as the final argument for useradd
        cmd+=("$user_id")

        # execute 
        echo "Creating user: $user_id..."
        "${cmd[@]}"
        
        # check 
        if [[ $? -eq 0 ]]; then
            
            # set password if provided
            if [[ -n "$user_password" && "$user_password" != "-" ]]; then
                echo "$user_id:$user_password" | chpasswd
                if [[ $? -eq 0 ]]; then
                    echo "Password successfully set for $user_id."
                else
                    echo "Error: Failed to set password for $user_id."
                fi
            fi

            # add sudoers if specified
            # The ,, converts the variable to lowercase (so YES, Yes, and yes all work)
            if [[ -n "$is_sudoer" && ( "${is_sudoer,,}" == "yes" || "${is_sudoer,,}" == "true" ) ]]; then
                usermod -aG sudo "$user_id"
                if [[ $? -eq 0 ]]; then
                    echo "Added $user_id to the sudo group."
                else
                    echo "Error: Failed to add $user_id to sudo group."
                fi
            fi
            
        else
            echo "Error: Failed to create user $user_id."
        fi

    else
        echo "Warning: Line did not match required format, skipping: $line"
    fi

done < "$INPUT_FILE"

echo "Users created."
