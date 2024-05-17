#!/bin/bash

NOW=$(date '+%d%m%Y-%H%M%S')

# Username
read -p "Enter username: " USERNAME
BACKUP_DIR="/var/web/$USERNAME/backup/"
TEMP_DIR="/var/web/$USERNAME/backup/Temp/"

# Check if TEMP_DIR exists, if not, create it
if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" && mkdir -p "$TEMP_DIR" && chmod u+w "$BACKUP_DIR" && chmod u+w "$TEMP_DIR" || { echo "Error: Unable to create backup directories"; exit 1; }
fi

# Website name
read -p "Enter website name: " WEBSITENAME
BACKUP_NAME="$WEBSITENAME"

# Path to website
SITE_PATH="/var/web/$USERNAME/public_html/"

# Check if SITE_PATH exists
if [ ! -d "$SITE_PATH" ]; then
    echo "Error: Directory $SITE_PATH does not exist"
    exit 1
fi

# Database credentials
read -p "Enter database host: " DATABASEHOST
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
tar -zcf "$TEMP_DIR/public_html.tar.gz" -C "$SITE_PATH" .

# Create archive
tar -zcf "$BACKUP_DIR/$BACKUP_NAME-$NOW.tar.gz" -C "$TEMP_DIR" .

# Delete temporary files
rm -Rf "$TEMP_DIR"

echo "Backup Complete [$(du -sh "$BACKUP_DIR/$BACKUP_NAME-$NOW.tar.gz" | awk '{print $1}')]"
