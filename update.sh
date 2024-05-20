#!/bin/bash

# Get the directory of the script without the trailing slash
script_dir=$(dirname "$(realpath "$0")")
script_dir=${script_dir%/}  # Remove trailing slash, if any
components_dir="components"

# Function to check the exit status of the last command and exit if it failed
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "An error occurred. Exiting."
        exit 1
    fi
}

# Stash any uncommitted changes
git stash
check_exit_status

# Pull the latest changes from the remote repository
git pull
check_exit_status

# Drop the stashed changes
git stash drop
check_exit_status

# Ensure the update.sh script is executable
chmod +x "$(basename "$0")"
check_exit_status

# Make all .sh files in the components directory executable
find "$script_dir/$components_dir" -type f -iname "*.sh" -exec chmod +x {} \;
check_exit_status

echo "Update and permissions adjustment completed successfully."
