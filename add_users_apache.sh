#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <input_file> <output_file>"
    echo "Example: $0 users.txt apache_passwords"
    echo "This will create the file /etc/apache2/.apache_passwords"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
HTPASSWD_FILE="/etc/apache2/.$OUTPUT_FILE"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

if [[ ! -d "$OUTPUT_FILE" ]]; then
    echo "Creating output directory: $OUTPUT_FILE"
    mkdir -p "$OUTPUT_FILE"
fi

OVERWRITE=false
if [[ ! -f "$HTPASSWD_FILE" ]]; then
    OVERWRITE=true
    echo "Notice: $HTPASSWD_FILE does not exist. It will be created."
fi

# read file
while IFS=" " read -r username password; do
    # skip empty lines or comments
    [[ -z "$username" || "$username" == \#* ]] && continue

    # skip if no password is provided 
    if [[ -z "$password" ]]; then
        echo "Warning: No password provided for user '$username'. Skipping."
        continue
    fi

    # create or append
    if [[ "$OVERWRITE" == true ]]; then
        htpasswd -c -b "$HTPASSWD_FILE" "$username" "$password"
        OVERWRITE=false
    else
        htpasswd -b "$HTPASSWD_FILE" "$username" "$password"
    fi
    
done < "$INPUT_FILE"

echo "Finished processing $INPUT_FILE. Output updated at $HTPASSWD_FILE."
