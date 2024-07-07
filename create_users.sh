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

  # Check if group already exists
  if [ $? -eq 0 ]; then
    echo "Group '$username' created successfully." >> "$log_file"
  else
    echo "Failed to create group '$username'. Skipping..." >> "$log_file"
  fi

  # Check if user already exists
  if id "$username" &> /dev/null; then
    echo "User '$username' already exists." >> "$log_file"
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
  fi

  # Check if user belongs to all specified groups
  user_groups=$(groups "$username" | cut -d ' ' -f 2-)
  missing_groups=""
  for group in $(echo "$groups" | tr ',' ' '); do
    if ! [[ $user_groups =~ $group ]]; then
      missing_groups="$missing_groups $group"
    fi
  done

  if [ -n "$missing_groups" ]; then
    echo "User '$username' is missing groups: $missing_groups" >> "$log_file"
    # Add user to missing groups (if user already existed)
    for group in $missing_groups; do
      usermod -a -G "$group" "$username" &>> "$log_file"
    done
  fi

  # Check if user belongs to their personal group
  if ! [[ $user_groups =~ $username ]]; then
    echo "User '$username' is not a member of their personal group." >> "$log_file"
    # Add user to their personal group
    usermod -a -G "$username" "$username" &>> "$log_file"
  fi

done < "$1"

echo "User creation script completed. Refer to logs for details: $log_file"
