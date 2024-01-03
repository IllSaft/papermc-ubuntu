#!/bin/bash

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
    # Check for 'help' argument
    if [[ $1 == "help" ]]; then
        usage
        exit 0
    fi
    # Log Headers and Environment Verification
    log_bold_nodate_info_header "[ PaperMC Server ]"
    verify_environment
    toggle_debug_mode "Debugger Enabled."

    # Code Functions 
    get_build "$BASE_DIR" "$SERVER_FOLDER" "$@"
    # Start the Minecraft server and monitor screen session
    start_minecraft_server

    # This log will be executed after the screen session ends or the script is stopped
    log_nodate_success "Main script execution completed"
}

# Execute Main Function
main "$@"