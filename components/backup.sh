#!/bin/bash

# Edit these constants as needed
# Default structure: /var/web/[username]/backup/Temp/ and /var/web/[username]/backup/public_html/
BACKUP_DIR_NAME="backup"
TEMP_DIR_NAME="Temp"
HTML_DIR_NAME="public_html"
MY_CNF="$HOME/.my.cnf"

# Do not edit past this point

# Paths to backup and temp directories
BACKUP_DIR="$HOME/$BACKUP_DIR_NAME/"
TEMP_DIR="$BACKUP_DIR/$TEMP_DIR_NAME/"

# Path to website
SITE_PATH="/$HOME/$HTML_DIR_NAME/"

NOW=$(date '+%d%m%Y-%H%M%S')


# Check if TEMP_DIR exists, if not, create it
if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" && mkdir -p "$TEMP_DIR" && chmod u+w "$BACKUP_DIR" && chmod u+w "$TEMP_DIR" || { echo "Error: Unable to create backup directories"; exit 1; }
fi

# Website name
read -p "Enter website name: " WEBSITENAME
BACKUP_NAME="$WEBSITENAME"
read -p "Enter database name: " DATABASENAME
DB_NAME="$DATABASENAME"


# Check if SITE_PATH exists
if [ ! -d "$SITE_PATH" ]; then
    echo "Error: Directory $SITE_PATH does not exist"
    exit 1
fi

echo "Starting backup of public_html and database..."

# Database backup (mysql)
mysqldump --defaults-file="$MY_CNF" --databases= "$DB_NAME" --no-tablespaces > "$TEMP_DIR/$BACKUP_NAME-$NOW.sql"

# Backup site files
tar -zcf "$TEMP_DIR/$HTML_DIR_NAME.tar.gz" -C "$SITE_PATH" .

# Create archive
tar -zcf "$BACKUP_DIR/$BACKUP_NAME-$NOW.tar.gz" -C "$TEMP_DIR" .

# Delete temporary files
rm -Rf "$TEMP_DIR"

echo "Backup complete: [$(du -sh "$BACKUP_DIR/$BACKUP_NAME-$NOW.tar.gz" | awk '{print $1}')]"
