#!/bin/bash

# Edit these constants as needed
# Default structure: /var/web/[username]/backup/
BASE_DIR="/var/web"
BACKUP_DIR_NAME="backup"
DESTINATION_HOST="6aa454105.l27powered.eu"

# Prompt for the source username
read -p "Enter your source username: " SOURCE_USERNAME

# Construct the backup directory path
BACKUP_DIR="$BASE_DIR/$SOURCE_USERNAME/$BACKUP_DIR_NAME"

# Check if the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

# List tar.gz files sorted by modification time (newest first)
FILES=($(ls -t "$BACKUP_DIR"/*.tar.gz 2> /dev/null))

# Check if there are any tar.gz files
if [ ${#FILES[@]} -eq 0 ]; then
  echo "No tar.gz files found in the backup directory."
  exit 1
fi

# Display the files and prompt for selection
echo "Select a file to transfer:"
select FILE_NAME in "${FILES[@]}"; do
  if [[ -n "$FILE_NAME" ]]; then
    echo "You selected: $FILE_NAME"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

# Prompt for the destination username and password
read -p "Enter the destination username: " DESTINATION_USERNAME
read -s -p "Enter the destination password: " DESTINATION_PASSWORD
echo

# Construct the destination path
DESTINATION_PATH="$BASE_DIR/$DESTINATION_USERNAME/$BACKUP_DIR_NAME/"

# Transfer the file using rsync with progress
RSYNC_PASSWORD=$DESTINATION_PASSWORD rsync -av --progress "$FILE_NAME" "$DESTINATION_USERNAME@$DESTINATION_HOST:$DESTINATION_PATH"

# Check if the rsync command was successful
if [ $? -eq 0 ]; then
  echo "File transfer successful."
else
  echo "File transfer failed."
fi
