# Student Attendance Tracker - Deployment Agent (`deploy_agent.sh`)

A robust Master Deployment Agent built with Bash shell scripting to automate the deployment, configuration, execution, and log archival of the Student Attendance Tracker Python application.

---

## Features

1. **Deploy the Application (Feature 1)**:
   * Creates the required directory structure (`attendance_tracker_{input}/`) along with subdirectories (`Helpers/`, `reports/`, `archives/attendance/`, `archives/absent/`).
   * Handles existing directories safely by prompting the user before overwriting.
   * Supports two roster options:
     * **Option A**: Copies template roster (4 prior sessions recorded, `total_sessions` set to 5).
     * **Option B**: Generates a fresh roster with customizable student count (0 prior sessions, `total_sessions` set to 1)[cite: 2].
   * Applies secure file permissions (`chmod +x` on the Python script, `chmod 600` on sensitive configuration files)[cite: 2].
   * Allows interactive updates to warning and failure attendance alert thresholds using `sed` in-place editing[cite: 2].
   * Automatically verifies the deployment by offering to run the application immediately[cite: 2].

2. **Run the Application (Feature 2)**:
   * Scans for deployed project directories and presents an interactive menu[cite: 2].
   * Hands over the terminal to the interactive Python marking script (`attendance_checker.py`)[cite: 2].

3. **Archive Log Files (Feature 3)**:
   * Automatically detects generated logs (`reports/attendance.log` and `reports/absent.log`)[cite: 2].
   * Compresses and moves each log into its respective archive directory (`archives/attendance/` or `archives/absent/`) with a precise UTC timestamp filename (`ATTENDANCE_YYYYMMDD_HHMMSS.zip` / `ABSENT_YYYYMMDD_HHMMSS.zip`)[cite: 2].
   * Handles missing logs gracefully without crashing the script if no records exist[cite: 2].

4. **Signal Handling (Ctrl+C / Ctrl+Z)**:
   * Traps `SIGINT` and `SIGTSTP` signals during the deployment phase[cite: 2].
   * Automatically packages any partial project files created up to that point into a `.zip` archive (`attendance_tracker_{input}_archive.zip`) and cleans up the half-made directory gracefully[cite: 2].

---

## How to Run the Script

1. Open your terminal (Git Bash on Windows or any Bash shell on Linux/macOS).
2. Ensure Python is installed and accessible in your path[cite: 3].
3. Make sure the script has execution permissions:
   ```bash
   chmod +x deploy_agent.sh
4. Run "./deploy_agent.sh"
