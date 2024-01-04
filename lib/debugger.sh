#!/bin/bash
# debugger.sh

# Get the absolute directory of debugger.sh
DEBUGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load necessary configurations and libraries
source "$DEBUGGER_DIR/../config/settings.cfg"
source "$DEBUGGER_DIR/logger.sh"

# Function to log debug messages and toggle Bash debug mode
toggle_debug_mode() {
    # Enable debug logging if VERBOSE_MODE is true or LOG_LEVEL is DEBUG
    if [ "$VERBOSE_MODE" == "true" ] || [ "$LOG_LEVEL" == "DEBUG" ]; then
        log_bold_nodate_debug "Debug Mode Enabled."  # Log the debug message
        
        # Check if VERBOSE_MODE is also true
        if [ "$VERBOSE_MODE" == "true" ]; then
            log_bold_nodate_verbose "Verbose Mode Enabled"
        fi

        set +x  # Enable Bash debug mode
    else
        set +x  # Disable Bash debug mode
    fi
}

# Additional debugging functions can be added here
