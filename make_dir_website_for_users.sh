#!/bin/bash

# arguments
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <target_directory> <directory_alias> <users_file>"
    echo "Example: sudo $0 ~/my_project project_alias users.txt"
    exit 1
fi

TARGET_DIR="$1"
ALIAS="$2"
USERS_FILE="$3"

HTPASSWD_FILE="/etc/apache2/.${ALIAS}_htpasswd"
WWW_ROOT="/var/www/html"
SYMLINK_PATH="$WWW_ROOT/$ALIAS"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

if [[ ! -f "$USERS_FILE" ]]; then
    echo "Error: Users file '$USERS_FILE' not found."
    exit 1
fi

# Convert to absolute path to prevent broken symlinks
TARGET_DIR=$(realpath "$TARGET_DIR")

# apliqué 755 cuando debería de ser 705
# es decir, otros usuarios tienen permiso 
echo "Applying permissions (755 for directories, 644 for files) in $TARGET_DIR..."
find "$TARGET_DIR" -type d -exec chmod 705 {} +
find "$TARGET_DIR" -type f -exec chmod 644 {} +

# Grant execute (+x) permissions to all parent directories so Apache can traverse to the target
echo "Ensuring parent directories are traversable by Apache..."
PARENT_DIR="$TARGET_DIR"
while [[ "$PARENT_DIR" != "/" ]]; do
    chmod a+x "$PARENT_DIR"
    PARENT_DIR=$(dirname "$PARENT_DIR")
done

# .htaccess file
HTACCESS_FILE="$TARGET_DIR/.htaccess"
echo "Creating .htaccess file at $HTACCESS_FILE..."

# require login by default
cat <<EOF > "$HTACCESS_FILE"
AuthType Basic
AuthName "Restricted Content"
AuthUserFile $HTPASSWD_FILE
Require valid-user
EOF

# file restriction to htaccess
chmod 644 "$HTACCESS_FILE"

# symbolic link in /var/www/html
echo "Creating symbolic link at $SYMLINK_PATH..."
if [[ -e "$SYMLINK_PATH" || -L "$SYMLINK_PATH" ]]; then
    echo "Notice: Path $SYMLINK_PATH already exists. Overwriting."
    rm -f "$SYMLINK_PATH"
fi
ln -s "$TARGET_DIR" "$SYMLINK_PATH"

# /etc/apache2 SHOULD exist but just in case
if [[ ! -d "/etc/apache2" ]]; then
    echo "Check if apache2 is installed!"
    echo "Creating output directory: /etc/apache2"
    mkdir -p "/etc/apache2"
fi

# Create and enable a specific Apache configuration for this directory
APACHE_CONF="/etc/apache2/conf-available/${ALIAS}_site.conf"
echo "Generating Apache configuration at $APACHE_CONF..."
cat <<EOF > "$APACHE_CONF"
<Directory "$TARGET_DIR">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF

# Enable the new configuration if a2enconf is available (Debian/Ubuntu systems)
if command -v a2enconf &> /dev/null; then
    a2enconf "${ALIAS}_site"
else
    echo "Warning: a2enconf not found. You may need to manually include $APACHE_CONF in your httpd.conf."
fi

# create htpasswd file
OVERWRITE=false
if [[ ! -f "$HTPASSWD_FILE" ]]; then
    OVERWRITE=true
    echo "Notice: $HTPASSWD_FILE does not exist. It will be created."
fi

echo "Processing users from $USERS_FILE..."
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
    
done < "$USERS_FILE"

echo "Restarting apache2 service..."
service apache2 restart

echo "Setup complete! Website ${ALIAS} is password protected and ready.
