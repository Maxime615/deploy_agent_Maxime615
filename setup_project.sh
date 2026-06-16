#!/bin/bash

# Ask the user for an input
echo "Welcome to student attendance tracker"
echo "Please enter your username"
read input

# Verify a username was typed
if [ "$input" = "" ]
then
        echo "No username! please enter a username"
        exit
fi

# This creates a folder name
dir_folder="attendance_tracker_$input"

# Implement a Signal Trap to handle user interrupts (SIGINT/Ctrl+C)
function clean_up {
        echo ""
        echo "Interrupt detected, saving current state..."
        tar -czf "$dir_folder"_archive.tar.gz "$dir_folder" 2>/dev/null
        # Remove the incomplete directory
        rm -rf "$dir_folder"
        echo "Done. Saved to ${dir_folder}_archive.tar.gz"
        exit
}

# Register the trap BEFORE creating directories
trap clean_up SIGINT

# Creates all folders
echo "Creating folders..."
mkdir "$dir_folder"
mkdir "$dir_folder/Helpers"
mkdir "$dir_folder/reports"

# Simulating a small delay so you have time to test Ctrl+C if you want
sleep 1

# Creating the attendance_checker file
echo "Creating the attendance_checker file..."
cat > "$dir_folder/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

# Creating the assets file
echo "Creating the assets file..."
cat > "$dir_folder/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Creating the config file
echo "Creating the config file..."
cat > "$dir_folder/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

# Creating the reports file
echo "Creating the reports file..."
cat > "$dir_folder/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

# Updating attendance threshold
echo "Enter the warning number (Default 75):"
read warning
if [ "$warning" = "" ]
then
        warning=75
fi

echo "Enter the failure number (Default 50):"
read failure
if [ "$failure" = "" ]
then
        failure=50
fi

# Checking if the inputs are actual positive numbers
if ! [[ "$warning" =~ ^[0-9]+$ ]]
then
        echo "Invalid number. Stopping."
        exit
fi
if ! [[ "$failure" =~ ^[0-9]+$ ]]
then
        echo "Invalid number. Stopping."
        exit
fi

# Use sed to edit values in the config.json file
echo "Updating the config.json file..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS compatibility
    sed -i '' "s/\"warning\": 75/\"warning\": $warning/" "$dir_folder/Helpers/config.json"
    sed -i '' "s/\"failure\": 50/\"failure\": $failure/" "$dir_folder/Helpers/config.json"
else
    # Standard Linux compatibility
    sed -i "s/\"warning\": 75/\"warning\": $warning/" "$dir_folder/Helpers/config.json"
    sed -i "s/\"failure\": 50/\"failure\": $failure/" "$dir_folder/Helpers/config.json"
fi

# Environment Validation
echo "Verification for python3..."
if command -v python3 > /dev/null
then
        echo "Python3 is present!"
        python3 --version
else
        echo "Warning: Python3 is not present."
fi

echo "Project setup done!"
