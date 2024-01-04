#!/bin/bash
# debugger.sh

# Get the absolute directory of debugger.sh
DEBUGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load necessary configurations and libraries
source "$DEBUGGER_DIR/../config/settings.cfg"
source "$DEBUGGER_DIR/logger.sh"

# Function to log debug messages and toggle Bash debug mode
toggle_debug_mode() {
    local message=$1

    # Check if LOG_LEVEL is set to DEBUG
    if [ "$LOG_LEVEL" == "DEBUG" ]; then
        log_event "DEBUG" "$message"
        set -x  # Enable Bash debug mode
    else
        set +x  # Disable Bash debug mode
    fi
}


# Additional debugging functions can be added here
