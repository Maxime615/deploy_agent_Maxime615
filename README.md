# Student Attendance Tracker

## Project Overview 
This repository demonstrates the power of **Infrastructure as Code (IaC)** by replacing manual workflows with a robust shell script (`setup_project.sh`). 

By automating the scaffolding, configuration, and validation steps, this tool delivers three major operational advantages:
* **Reproducibility:** Guarantees that every deployment server runs the exact same folder structure and core files.
* **Efficiency:** slashes an error-prone, 10-minute manual directory configuration down to a 2-second automated execution.
* **Reliability:** Eliminates manual human mistakes, such as typographical errors in directory paths or missing environment templates.

---

## Workspace Architecture Blueprint
When executed, the script prompts for a unique instance identifier (`{input}`) and builds an isolated workspace named `attendance_tracker_{input}`. The structured layout inside that directory matches this strict protocol:

```text
attendance_tracker_{input}/
├── attendance_checker.py      # The primary Python application runtime logic
├── Helpers/
│   ├── assets.csv             # Target student attendance dataset register
│   └── config.json            # Application environment thresholds matrix
└── reports/
    └── reports.log            # Target runtime activity output registry

```

## Running the script 
To run the script I used (`chmod +x setup_project.sh`) to make the script executable then afterwards I used (`./setup_project.sh`) to run the script
