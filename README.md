## README: create_users.sh

This README file explains the functionality and usage of the `create_users.sh` script, designed to automate user creation, group assignment, and home directory setup for new users on a Linux system.

**Benefits:**

* **Streamlined Onboarding:** Efficiently onboard new developers or users by automating user account creation.
* **Reduced Manual Work:** Save time and minimize errors by automating repetitive tasks.
* **Improved Consistency:** Ensure consistent user account configuration based on a defined format.

**HNG Internship Program:**

This script can be a valuable tool for companies participating in the HNG Internship Program ([https://hng.tech/](https://hng.tech/)) to manage user accounts for interns effectively.

**Script Functionality:**

The `create_users.sh` script takes a text file as input, where each line represents a user with the following format:



* `username`: The username for the new user account.
* `groups`: Comma-separated list of groups the user should belong to.

**Script Features:**

* **User and Group Creation (lines 20-25):**
  * Checks if a group with the same name as the username already exists (`groupadd "$username"`).
  * Logs the action to the log file (`>> "$log_file"`).
  * Checks if the user already exists using the `id` command (`id "$username"`).
    * If the user exists, a message is logged and the script skips user creation (`echo "User '$username' already exists. Skipping..." >> "$log_file"`).

* **Random Password Generation and Storage (lines 27-32):**
  * Generates a random password using `/dev/urandom` and stores it in a variable (`password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c16)`).
  * Appends the username and password to the password file separated by a colon (`echo "$username:$password" >> "$password_file"`).

* **User Creation, Home Directory Setup, and Permissions (lines 34-40):**
  * Creates the user with the generated password, home directory, and sets the shell to `/bin/bash` (`useradd -m -g "$username" -s /bin/bash "$username"`).
  * Logs the password for the user to the log file (`echo "Password for user '$username': $password" >> "$log_file"`).
  * Sets ownership and permissions for the home directory (`chown -R "$username:$username" "/home/$username"` and `chmod 700 "/home/$username"`).

* **Group Membership (lines 42-46):**
  * Loops through each group listed in the comma-separated list (`for group in $(echo "$groups" | tr ',' ' ')`)
  * Adds the user to the specified group using `usermod` (`usermod -a -G "$group" "$username"`).
  * Logs the group addition to the log file (`>> "$log_file"`).

**Usage:**

1. **Create a User Data File:** Prepare a text file containing user information in the specified format (`username;groups`).
2. **Run the Script:** Execute the script with the user data file path as an argument:


**Log File:**

The script logs all actions to the `/var/log/user_management.log` file for reference and troubleshooting.

**Password File:**

Generated user passwords are stored securely in the `/var/secure/user_passwords.txt` file. This file has restricted permissions, allowing only the owner to read its contents.

**Requirements:**

* Linux system with Bash interpreter.
* User with administrative privileges to execute the script.