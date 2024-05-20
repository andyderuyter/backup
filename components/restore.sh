#!/bin/bash

# Edit these constants as needed
# Default structure: /var/web/[username]/backup/TempRestore/ and /var/web/[username]/backup/public_html/
BASE_DIR="/var/web"
BACKUP_DIR_NAME="backup"
TEMP_DIR_NAME="TempRestore"
HTML_DIR_NAME="public_html"
MY_CNF="$HOME/.my.cnf"

# Function to list backups and get user choice
list_backups() {
    echo "Available backups:"
    BACKUP_DIR="$HOME/$BACKUP_DIR_NAME/"
    BACKUPS=$(ls "$BACKUP_DIR"*.tar.gz)

    if [ -z "$BACKUPS" ]; then
        echo "No backups found in $BACKUP_DIR"
        exit 1
    fi

    BACKUPS=($BACKUPS)

    for i in "${!BACKUPS[@]}"; do
        echo "$((i + 1)). $(basename "${BACKUPS[i]}")"
    done

    read -p "Enter the number of the backup you want to restore: " CHOICE
    if [[ ! $CHOICE =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#BACKUPS[@]}" ]; then
        echo "Invalid choice. Exiting."
        exit 1
    fi

    SELECTED_BACKUP="${BACKUPS[$((CHOICE - 1))]}"
}

# Function to empty public_html folder
empty_public_html() {
    SITE_PATH="$HOME/$HTML_DIR_NAME/"
    if [ -d "$SITE_PATH" ]; then
        read -p "Do you want to empty the public_html folder before restoring? (yes/no): " EMPTY_CHOICE
        if [ "$EMPTY_CHOICE" == "yes" ]; then
            find "$SITE_PATH" -mindepth 1 -delete
            echo "$HTML_DIR_NAME folder emptied."
        else
            echo "$HTML_DIR_NAME folder not emptied."
        fi
    else
        echo "Error: Directory $SITE_PATH does not exist"
        exit 1
    fi
}

# Function to drop all tables in the database
drop_all_tables() {
    echo "Dropping all tables in the database..."
    TABLES=$(mysql --defaults-file="$MY_CNF" -e 'SHOW TABLES;' | awk '{ print $1 }' | grep -v '^Tables' )
    for TABLE in $TABLES; do
        mysql --defaults-file="$MY_CNF" -e "DROP TABLE IF EXISTS $TABLE;"
    done
    echo "All tables dropped."
}

# Function to import any SQL file into the database
import_sql_file() {
    SQL_FILE=$(find "$TEMP_DIR" -maxdepth 1 -type f -name "*.sql")
    if [ -n "$SQL_FILE" ]; then
        echo "Importing database from $SQL_FILE..."
        mysql --defaults-file="$MY_CNF" < "$SQL_FILE"
        echo "Database import complete."
    else
        echo "Error: No SQL file found in $TEMP_DIR"
        exit 1
    fi
}

# Function to restore backup
restore_backup() {
    TEMP_DIR="/$HOME/$BACKUP_DIR_NAME/$TEMP_DIR_NAME/"
    mkdir -p "$TEMP_DIR"
    tar -xzf "$SELECTED_BACKUP" -C "$TEMP_DIR"
    drop_all_tables

    # Extract contents of public_html.tar.gz into public_html folder
    tar -xzf "$TEMP_DIR/$HTML_DIR_NAME.tar.gz" -C "$SITE_PATH"

    # Find and import the .sql file
    SQL_FILE=$(find "$TEMP_DIR" -maxdepth 1 -type f -name "*.sql" | head -n 1)
    if [ -n "$SQL_FILE" ]; then
        echo "Importing database from $SQL_FILE..."
        mysql --defaults-file="$MY_CNF" < "$SQL_FILE"
        echo "Database import complete."
    else
        echo "Error: No SQL file found in $TEMP_DIR"
        exit 1
    fi

    rm -Rf "$TEMP_DIR"
    echo "Backup restored from $SELECTED_BACKUP"
}

# List backups and get user choice
list_backups

# Empty public_html folder if chosen
empty_public_html

# Restore the selected backup
restore_backup

echo "Restore Complete"
