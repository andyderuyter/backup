#!/bin/bash

# Set executable permissions for the required scripts
chmod +x /var/web/$(whoami)/zabit-shell-tools/components/install.sh
chmod +x /var/web/$(whoami)/zabit-shell-tools/components/backup.sh
chmod +x /var/web/$(whoami)/zabit-shell-tools/components/restore.sh
chmod +x /var/web/$(whoami)/zabit-shell-tools/components/transfer.sh
chmod +x /var/web/$(whoami)/zabit-shell-tools/update.sh

# Function to get the latest local commit hash
get_latest_local_commit() {
    local latest_commit=$(git -C /var/web/$(whoami)/zabit-shell-tools log -1 --pretty=format:"%h")
    echo "$latest_commit"
}

# Function to get the latest online commit hash
get_latest_online_commit() {
    git -C /var/web/$(whoami)/zabit-shell-tools fetch origin main >/dev/null 2>&1
    local latest_commit=$(git -C /var/web/$(whoami)/zabit-shell-tools log -1 origin/main --pretty=format:"%h")
    echo "$latest_commit"
}

# Get the latest local and online commit hashes
latest_local_commit=$(get_latest_local_commit)
latest_online_commit=$(get_latest_online_commit)

# Display the latest commits
echo "Latest Local Commit: $latest_local_commit"
echo "Latest Online Commit: $latest_online_commit"

# Check if the latest local commit doesn't match the latest online commit
if [[ "$latest_local_commit" != "$latest_online_commit" ]]; then
    echo "- INFO: The latest local commit does not match the latest online commit. Please update your script."
fi

# Function to display the menu
show_menu() {
    echo " "
    echo "Please select a task:"
    echo "1) Install WordPress"
    echo "2) Backup public_html and database"
    echo "3) Restore a previous backup"
    echo "4) Transfer a backup to another account"
    echo "5) Update this script via git pull"
    echo "6) Exit"
}

# Main loop to handle user input
while true; do
    show_menu
    read -p "Enter your choice [1-6]: " choice

    case $choice in
        1)
            ./components/install.sh
            echo "WordPress installation completed. Returning to the main menu..."
            ;;
        2)
            ./components/backup.sh
            echo "Backup task completed. Returning to the main menu..."
            ;;
        3)
            ./components/restore.sh
            echo "Restore task completed. Returning to the main menu..."
            ;;
        4)
            ./components/transfer.sh
            echo "Transfer task completed. Returning to the main menu..."
            ;;
        5)
            ./update.sh
            echo "Update of zabit-shell-tools completed. Returning to the main menu..."
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice, please try again."
            ;;
    esac
    # Adding a short pause for better user experience
    sleep 2
done
