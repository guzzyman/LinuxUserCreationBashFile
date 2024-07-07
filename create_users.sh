#!/bin/bash

# Check if the script is run as root (superuser)
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Check if the input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create log and password files if they do not exist
touch $LOG_FILE
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to generate random passwords
generate_password() {
    openssl rand -base64 12
}

# Read the input file line by line
while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists, skipping..." | tee -a $LOG_FILE
        continue
    fi

    # Create a personal group for the user
    addgroup "$username"

    # Create the user with the personal group and home directory
    adduser -D -G "$username" -s /bin/bash "$username"

    # Add the user to additional groups if specified
    if [ -n "$groups" ]; then
        IFS=',' read -r -a group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            if ! getent group "$group" > /dev/null; then
                addgroup "$group"
            fi
            adduser "$username" "$group"
        done
    fi

    # Generate a random password for the user
    password=$(generate_password)

    # Set the user's password
    echo "$username:$password" | chpasswd

    # Log the actions
    echo "Created user $username with groups $groups and home directory" | tee -a $LOG_FILE

    # Store the username and password securely
    echo "$username,$password" >> $PASSWORD_FILE
done < "$INPUT_FILE"

echo "User creation process completed. Check $LOG_FILE for details."