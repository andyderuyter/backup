#!/bin/bash

# Edit these constants as needed
# Default structure: /var/web/[username]/backup/Temp/ and /var/web/[username]/backup/public_html/
BASE_DIR="/var/web"
BACKUP_DIR_NAME="backup"
TEMP_DIR_NAME="Temp"
HTML_DIR_NAME="public_html"
DEFAULT_DATABASEHOST="localhost"

# Do not edit past this point

# Username
read -p "Enter username: " USERNAME

# Paths to backup and temp directories
BACKUP_DIR="$BASE_DIR/$USERNAME/$BACKUP_DIR_NAME/"
TEMP_DIR="$BACKUP_DIR/$TEMP_DIR_NAME/"

# Path to website
SITE_PATH="/$BASE_DIR/$USERNAME/$HTML_DIR_NAME/"

NOW=$(date '+%d%m%Y-%H%M%S')


# Check if TEMP_DIR exists, if not, create it
if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" && mkdir -p "$TEMP_DIR" && chmod u+w "$BACKUP_DIR" && chmod u+w "$TEMP_DIR" || { echo "Error: Unable to create backup directories"; exit 1; }
fi

# Website name
read -p "Enter website name: " WEBSITENAME
BACKUP_NAME="$WEBSITENAME"

# Check if SITE_PATH exists
if [ ! -d "$SITE_PATH" ]; then
    echo "Error: Directory $SITE_PATH does not exist"
    exit 1
fi

# Database credentials
read -p "Enter database host [Press enter for ${DEFAULT_DATABASEHOST}]: " DATABASEHOST
DATABASEHOST=${DATABASEHOST:-$DEFAULT_DATABASEHOST}

read -p "Enter database name: " DATABASENAME
DB_NAME="$DATABASENAME"

read -p "Enter database user: " DATABASEUSER
DB_USER="$DATABASEUSER"

echo -n "Enter database password: "
read DATABASEPASSWORD
echo

echo "Starting Backup..."

# Database backup (mysql)
mysqldump -h "$DATABASEHOST" -u "$DB_USER" -p"$DATABASEPASSWORD" "$DB_NAME" --no-tablespaces > "$TEMP_DIR/$DATABASENAME-$NOW.sql"

# Backup site files
tar -zcf "$TEMP_DIR/$HTML_DIR_NAME.tar.gz" -C "$SITE_PATH" .

# Create archive
tar -zcf "$BACKUP_DIR/$BACKUP_NAME-$NOW.tar.gz" -C "$TEMP_DIR" .

# Delete temporary files
rm -Rf "$TEMP_DIR"

echo "Backup Complete [$(du -sh "$BACKUP_DIR/$BACKUP_NAME-$NOW.tar.gz" | awk '{print $1}')]"
