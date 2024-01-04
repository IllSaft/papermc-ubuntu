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

# Main Function
main() {
    toggle_debug_mode
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

        # Main menu for server management
        handle_build_update "$@"
        main_menu
    fi

    log_nodate_success "Main script execution completed"
}
# Function to handle build updates (from helpers.sh)
handle_build_update "$@"

# Main Menu Function (from helpers.sh)
main_menu

# Function to check and attach to existing screen session (from helpers.sh)
check_and_attach_screen_session

# Function to start the Minecraft server inside a screen session (from helpers.sh)
start_minecraft_server

# Function to toggle maintenance mode (from helpers.sh)
toggle_maintenance_mode

# Function to enable maintenance mode (from helpers.sh)
maintenance_mode

# Function to disable maintenance mode (from helpers.sh)
disable_maintenance_mode

# Pass arguments to main
main "$@"
