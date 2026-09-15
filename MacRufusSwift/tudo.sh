#!/bin/bash
# This script simulates sudo command for testing password authentication instead of risking multiple failures and getting locked out. 
# First, it looks for and reads file of same directory "tudo.ini" and parses a timestamp of last successful password authentication.  If the timestamp is older than 5 minutes, it prompts for a password "Password:" and checks input against a hardcoded password. 
# If the password is correct, it updates the timestamp in the "tudo.ini" file.  The script will then exit with termination code 0.
# If the password is incorrect, it would repeat the prompt "Sorry, try again. Password:" for 2 more tries before exiting the script with termination code 1.

# Hardcoded password (for testing purposes only)
PASSWORD="testpassword"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the ini file
INI_FILE="$SCRIPT_DIR/tudo.ini"

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Check if ini file exists
if [[ -f "$INI_FILE" ]]; then
    # Read the timestamp from the ini file
    LAST_TIME=$(cat "$INI_FILE")
    
    # Calculate time difference
    TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
    
    # If last authentication was within 5 minutes (300 seconds), skip password prompt
    if [[ $TIME_DIFF -lt 300 ]]; then
        exit 0
    fi
fi

# Prompt for password with 3 attempts
ATTEMPTS=0
MAX_ATTEMPTS=3

while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
    read -p "Password: " INPUT_PASSWORD
    
    if [[ "$INPUT_PASSWORD" == "$PASSWORD" ]]; then
        # Password correct, update timestamp
        echo $CURRENT_TIME > "$INI_FILE"
        exit 0
    else
        ATTEMPTS=$((ATTEMPTS + 1))
        if [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; then
            echo "Sorry, try again. Password:"
        fi
    fi
done

# If we reach here, password was incorrect after 3 attempts
exit 1