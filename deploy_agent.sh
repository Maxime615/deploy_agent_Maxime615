#!/bin/bash

# ==============================================================================
# Master Deployment Agent for Student Attendance Tracker
# ==============================================================================

TEMPLATES_DIR="templates"

# Signal Trap for Deployment Interruptions (Ctrl+C / Ctrl+Z)
cleanup_on_interrupt() {
    echo -e "\n\n[!] Interrupt detected! Packaging partial project..."
    if [ -n "$dir_folder" ] && [ -d "$dir_folder" ]; then
        if command -v python &> /dev/null; then
            python -c "import shutil; shutil.make_archive('${dir_folder}_archive', 'zip', '$dir_folder')" >/dev/null 2>&1
            echo "Saved partial folder to ${dir_folder}_archive.zip"
        fi
        rm -rf "$dir_folder"
    fi
    exit 130
}

# Main Interactive Menu Loop
while true; do
    clear
    echo "=========================================================="
    echo "      STUDENT ATTENDANCE TRACKER     "
    echo "=========================================================="
    echo "  1. Deploy the Application"
    echo "  2. Run the Application"
    echo "  3. Archive Log Files"
    echo "  4. Exit"
    echo "=========================================================="
    read -rp "Select an option [1-4]: " main_choice

    case "$main_choice" in
        # ======================================================================
        # FEATURE 1: DEPLOY APPLICATION
        # ======================================================================
        1)
            echo "=== FEATURE 1: DEPLOY APPLICATION ==="
            
            # Pre-flight checks
            if ! command -v python &> /dev/null; then
                echo "python is required." >&2
                read -rp "Press Enter to continue..."
                continue
            fi

            read -rp "Enter project directory suffix: " input
            if [ -z "$input" ]; then
                echo "Suffix cannot be empty." >&2
                read -rp "Press Enter to continue..."
                continue
            fi

            dir_folder="attendance_tracker_$input"
            
            if [ -d "$dir_folder" ]; then
                read -rp "Directory '$dir_folder' exists. Overwrite? [y/N]: " ov
                [[ "$ov" =~ ^[Yy]$ ]] && rm -rf "$dir_folder" || continue
            fi

            # Register trap before creation
            trap cleanup_on_interrupt SIGINT SIGTSTP

            echo "Creating folders..."
            mkdir -p "$dir_folder"/{Helpers,reports,archives/attendance,archives/absent}
            sleep 1

            echo "Copying files from templates..."
            cp "$TEMPLATES_DIR/attendance_checker.py" "$dir_folder/"
            cp "$TEMPLATES_DIR/config.json" "$dir_folder/Helpers/"

            read -rp "Choose roster option - [A] Copy template (4 prior sessions) or [B] Fresh (0 sessions): " roster_opt
            if [[ "$roster_opt" =~ ^[Bb]$ ]]; then
                echo "Email,Names,Attendance Count,Absence Count" > "$dir_folder/Helpers/assets.csv"
                emails=("alice@example.com" "bob@example.com" "charlie@example.com" "diana@example.com" "ethan@example.com" "fatima@example.com" "george@example.com" "hannah@example.com" "ibrahim@example.com" "jasmine@example.com")
                names=("Alice Johnson" "Bob Smith" "Charlie Davis" "Diana Prince" "Ethan Cole" "Fatima Noor" "George Mensah" "Hannah Kim" "Ibrahim Osei" "Jasmine Lee")
                read -rp "Enter number of students to generate (1-10): " num_fresh
                for ((i=0; i<${num_fresh:-5}; i++)); do
                    echo "${emails[$i]},${names[$i]},0,0" >> "$dir_folder/Helpers/assets.csv"
                done
                total_sessions_val=1
            else
                cp "$TEMPLATES_DIR/assets.csv" "$dir_folder/Helpers/"
                total_sessions_val=5
            fi

            python -c "
import json
p = '$dir_folder/Helpers/config.json'
c = json.load(open(p))
c['total_sessions'] = $total_sessions_val
json.dump(c, open(p, 'w'), indent=4)
"

            chmod +x "$dir_folder/attendance_checker.py"
            chmod 600 "$dir_folder/Helpers/config.json"
            echo "Permissions set (+x on script, 600 on config.json)."

            read -rp "Update alert thresholds? [y/N]: " ut
            if [[ "$ut" =~ ^[Yy]$ ]]; then
                read -rp "Warning threshold [default 75]: " warn_val
                read -rp "Failure threshold [default 50]: " fail_val
                sed -i.bak "s/\"warning\":[[:space:]*[0-9]*/\"warning\": ${warn_val:-75}/" "$dir_folder/Helpers/config.json"
                sed -i.bak "s/\"failure\":[[:space:]*[0-9]*/\"failure\": ${fail_val:-50}/" "$dir_folder/Helpers/config.json"
                rm -f "$dir_folder/Helpers/config.json.bak"
            fi

            trap - SIGINT SIGTSTP
            echo "[✓] Deployment completed in '$dir_folder'!"

            read -rp "Verify deployment by running application now? [Yes/no]: " vr
            [[ ! "$vr" =~ ^[Nn]$ ]] && (cd "$dir_folder" && python attendance_checker.py)
            read -rp "Press Enter to return to main menu..."
            ;;
            
        # ======================================================================
        # FEATURE 2: RUN APPLICATION
        # ======================================================================
        2)
            echo "=== FEATURE 2: RUN APPLICATION ==="
            dirs=(attendance_tracker_*)
            if [ ! -d "${dirs[0]}" ]; then
                echo "No deployed projects found. Run Feature 1 first." >&2
                read -rp "Press Enter to continue..."
                continue
            fi
            select target in "${dirs[@]}"; do [[ -n "$target" ]] && break; done
            cd "$target" && python attendance_checker.py && cd - >/dev/null
            read -rp "Press Enter to return to main menu..."
            ;;
            
        # ======================================================================
        # FEATURE 3: ARCHIVE LOG FILES
        # ======================================================================
        3)
            echo "=== FEATURE 3: ARCHIVE LOG FILES ==="
            dirs=(attendance_tracker_*)
            if [ ! -d "${dirs[0]}" ]; then
                echo "No deployed projects found." >&2
                read -rp "Press Enter to continue..."
                continue
            fi
            select target in "${dirs[@]}"; do [[ -n "$target" ]] && break; done
            
            ts=$(date +"%Y%m%d_%H%M%S")
            
            # Archive attendance.log using Python
            if [ -f "$target/reports/attendance.log" ]; then
                mkdir -p "$target/archives/attendance"
                python -c "
import zipfile, os
with zipfile.ZipFile('$target/archives/attendance/ATTENDANCE_${ts}.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    z.write('$target/reports/attendance.log', arcname='attendance.log')
"
                echo "Archived attendance.log to archives/attendance/ATTENDANCE_${ts}.zip"
            else
                echo "reports/attendance.log not found, skipped."
            fi

            # Archive absent.log using Python
            if [ -f "$target/reports/absent.log" ]; then
                mkdir -p "$target/archives/absent"
                python -c "
import zipfile, os
with zipfile.ZipFile('$target/archives/absent/ABSENT_${ts}.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    z.write('$target/reports/absent.log', arcname='absent.log')
"
                echo "Archived absent.log to archives/absent/ABSENT_${ts}.zip"
            else
                echo "reports/absent.log not found, skipped."
            fi

            read -rp "Press Enter to continue..."
            ;;
            
        # ======================================================================
        # EXIT SCRIPT
        # ======================================================================
        4)
            echo "Exiting Deployment Agent. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose between 1 and 4."
            sleep 1
            ;;
    esac
done