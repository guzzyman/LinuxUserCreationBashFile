#!/bin/bash

# Script arguments validation
if [ $# -ne 1 ]; then
  echo "Usage: $0 <user_data_file>"
  exit 1
fi

# Define log and password files
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"

# Ensure log and password file directories exist
mkdir -p $(dirname "$log_file")
mkdir -p $(dirname "$password_file")

# Set permissions for password file (read-only for owner)
touch "$password_file"
chmod 600 "$password_file"

# Loop through each line in the user data file
while IFS=';' read -r username groups; do

  # Remove leading/trailing whitespace
  username=${username## }
  username=${username%% }
  groups=${groups## }
  groups=${groups%% }

  # Create user group (same as username)
  groupadd "$username" &>> "$log_file"

  # Check if user already exists
  if id "$username" &> /dev/null; then
    echo "User '$username' already exists. Skipping..." >> "$log_file"
  else
    # Generate random password
    password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c16)
    echo "$username:$password" >> "$password_file"

    # Create user with random password and home directory
    useradd -m -g "$username" -s /bin/bash "$username" &>> "$log_file"
    echo "Password for user '$username': $password" >> "$log_file"

    # Set home directory permissions
    chown -R "$username:$username" "/home/$username" &>> "$log_file"
    chmod 700 "/home/$username" &>> "$log_file"

    # Add user to specified groups (comma-separated)
    for group in $(echo "$groups" | tr ',' ' '); do
      usermod -a -G "$group" "$username" &>> "$log_file"
    done
  fi

done < "$1"

echo "User creation script completed. Refer to logs for details: $log_file"
