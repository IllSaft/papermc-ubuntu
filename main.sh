#!/bin/bash

# Check if the script is being run as root or with sudo
if [ "$(id -u)" = "0" ]; then
    echo "This script should not be run as root or with sudo. Please run as a normal user."
    exit 1
fi

# Base Directory of the Script
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export BASE_DIR

# Source Configuration and Libraries
source "$BASE_DIR/config/settings.cfg"
source "$BASE_DIR/config/palette.sh"
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/debugger.sh"
source "$BASE_DIR/lib/environment.sh"
source "$BASE_DIR/lib/error_handling.sh"
source "$BASE_DIR/lib/helpers.sh"

# Initialize Logger
if [[ -z $LOGGER_INITIALIZED ]]; then
    initiate_logger
    export LOGGER_INITIALIZED=true
fi

# Set Terminal Title
set_terminal_title "$APPLICATION_TITLE"

# Modify the main function
main() {
    verify_environment
    if [[ $CALLED_BY_SYSTEMD == 1 ]]; then
        start_server_for_systemd
        exit 0
    fi

    if [[ $SYSTEMCTL_AUTO_START == true ]]; then
        log_bold_nodate_focus "Checking and managing PaperMC server via systemctl..."
        create_systemctl
    else
        stop_disable_and_remove_systemctl

        # Check for server status and handle build updates
        handle_build_update "$@"
    fi

    log_nodate_success "Main script execution completed"
}

# Pass arguments to main
main "$@"
