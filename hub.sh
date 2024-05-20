#!/bin/bash

# Get the directory of the current script
script_dir=$(dirname "$(realpath "$0")")
script_dir=${script_dir%/}  # Remove trailing slash, if any
components_dir="components"
MY_CNF="$HOME/.my.cnf"

# Check if the script has executable permissions
if [[ ! -x "$0" ]]; then
    echo "Error: The script $0 does not have executable permissions."
    echo "Please run: chmod +x $0"
    exit 1
fi

# Set executable permissions for the required scripts
for script in install.sh backup.sh restore.sh transfer.sh; do 
    chmod +x "$script_dir/$components_dir/$script"
done
chmod +x "$script_dir/update.sh"

# Function to get the latest local commit hash
get_latest_local_commit() {
    local latest_commit=$(git -C "$script_dir/" log -1 --pretty=format:"%h")
    echo "$latest_commit"
}

# Function to get the latest online commit hash
get_latest_online_commit() {
    git -C "$script_dir/" fetch origin main >/dev/null 2>&1
    local latest_commit=$(git -C "$script_dir/" log -1 origin/main --pretty=format:"%h")
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

# Function to initialize the .my.cnf file
initialize_my_cnf() {
    # Prompt for MySQL credentials and database name
    read -p "Enter MySQL username: " db_user
    read -sp "Enter MySQL password: " db_pass
    echo
    read -p "Enter MySQL host [default: localhost]: " db_host
    db_host=${db_host:-localhost}  # Set default value to localhost if empty
    read -p "Enter default database name: " db_name

    # Create or update the .my.cnf file in the user's home directory
    cat > "$MY_CNF" <<EOF
[client]
user=$db_user
password=$db_pass
host=$db_host
database=$db_name
EOF

    # Secure the .my.cnf file by setting proper permissions
    chmod 600 "$MY_CNF"

    echo ".my.cnf file has been created/updated successfully."
}

# Function to check if .my.cnf file is present
check_my_cnf() {
    if [[ -f "$MY_CNF" ]]; then
        echo "Existing MySQL credentials:"
        cat "$MY_CNF"
        read -p "Do you want to use the existing MySQL credentials? (yes/no): " use_existing
        if [[ "$use_existing" == "yes" ]]; then
            echo "Using existing MySQL credentials."
        else
            rm -i "$MY_CNF"
            echo ".my.cnf file has been deleted."
            initialize_my_cnf
        fi
    else
        initialize_my_cnf
    fi
}

# Function to empty public_html folder
empty_public_html() {
    SITE_PATH="$HOME/public_html"
    if [ -d "$SITE_PATH" ]; then
        read -p "Are you sure you want to empty the public_html folder? This action cannot be undone. (yes/no): " confirm_empty_public_html
        if [ "$confirm_empty_public_html" == "yes" ]; then
            echo "Emptying public_html folder..."
            find "$SITE_PATH" -mindepth 1 -delete
            echo "public_html folder emptied."
        else
            echo "Operation aborted."
        fi
    else
        echo "Error: Directory $SITE_PATH does not exist"
        exit 1
    fi
}

# Function to drop all tables in the database
drop_all_tables() {
    echo "Dropping all tables in the database..."
    read -p "Are you sure you want to drop all tables in the database? This action cannot be undone. (yes/no): " confirm_drop_all_tables
    if [ "$confirm_drop_all_tables" == "yes" ]; then
        mysql --defaults-file="$MY_CNF" -e 'SHOW TABLES;' | awk '{ print $1 }' | grep -v '^Tables' | while read -r TABLE; do
            mysql --defaults-file="$MY_CNF" -e "DROP TABLE IF EXISTS $TABLE;"
        done
        echo "All tables dropped."
    else
        echo "Operation aborted."
    fi
}

# Function to display the menu
show_menu() {
    echo " "
    echo "Please select a task:"
    echo "0) Initialize MySQL configuration"
    echo "1) Install WordPress"
    echo "2) Backup public_html and database"
    echo "3) Restore a previous backup"
    echo "4) Transfer a backup to another account"
    echo "5) Update this script via git pull"
    echo "6) /!\ DANGER - Empty public_html folder"
    echo "7) /!\ DANGER - Drop all tables in the database"
    echo "8) Exit"
}

# Main loop to handle user input
while true; do
    show_menu
    read -p "Enter your choice [0-8]: " choice

    case $choice in
        0)
            check_my_cnf
            echo "MySQL configuration initialization completed. Returning to the main menu..."
            ;;
        1)
            "$script_dir/$components_dir/install.sh"
            echo "WordPress installation completed. Returning to the main menu..."
            ;;
        2)
            "$script_dir/$components_dir/backup.sh"
            echo "Backup task completed. Returning to the main menu..."
            ;;
        3)
            "$script_dir/$components_dir/restore.sh"
            echo "Restore task completed. Returning to the main menu..."
            ;;
        4)
            "$script_dir/$components_dir/transfer.sh"
            echo "Transfer task completed. Returning to the main menu..."
            ;;
        5)
            "$script_dir/update.sh"
            echo "Update of zabit-shell-tools completed. Returning to the main menu..."
            ;;
        6)
            empty_public_html
            ;;
        7)
            drop_all_tables
            ;;
        8)
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
