#!/usr/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 user"
    exit 1
fi

target_user="$1"

# exact match first
if grep -q "^${target_user}:" /etc/passwd; then
    user_id=$(id -u "$target_user")
    echo "Exact match:"
    echo "The UID for '$target_user' is: $user_id"
else
    echo "Exact match for '$target_user' not found."
fi

# -F: sets the field separator to a colon.
# $1 ~ target checks if the first field (username) contains the search term.
# $1 != target prevents the exact match from being printed again.
similar_matches=$(awk -F: -v target="$target_user" '$1 ~ target && $1 != target {print "- " $1 " (UID: " $3 ")"}' /etc/passwd)

if [[ -n "$similar_matches" ]]; then
    echo ""
    echo "Similar matches:"
    echo "$similar_matches"
fi
