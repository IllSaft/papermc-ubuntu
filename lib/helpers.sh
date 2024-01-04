#!/bin/bash
# This script contains helper functions that provide various utilities to the application.

# Sets the terminal title to the provided argument.
# Inputs: 
#   $1 - The title string to be set for the terminal.
# Usage: 
#   set_terminal_title "My Application"
#!/bin/bash
# This script contains helper functions that provide various utilities to the application.

# Sets the terminal title to the provided argument.
# Usage: set_terminal_title "My Application"
set_terminal_title() {
    local title=$1
    echo -ne "\\033]0;${title}\\007"
}

# Confirmation Prompt
confirm_action() {
    local prompt="${1:-$CONFIRM_PROMPT_DEFAULT}"
    read -r -p "$prompt [y/N]: " response
    [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
}

# Input Prompt
input_prompt() {
    local prompt=$1
    read -r -p "$prompt: " input
    echo "$input"
}

# Wait for Key Press
wait_for_keypress() {
    read -r -n1 -p "Press any key to continue..."
    echo
}

# Function to show help message
usage() {
    log_bold_nodate_tip "Usage: $0 [build number]"
    log_bold_nodate_tip "       If no arguments are provided, the latest build of the latest version will be downloaded."
    log_bold_nodate_tip "       If the build number is provided, that build of the latest version will be downloaded."
    exit 1
}

# Function to fetch the latest version
get_latest_version() {
    curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]'
}

# Function to fetch the latest build number for a given version
get_latest_build() {
    local version=$1
    local specific_build=$2

    # Check if a specific build number is provided
    if [ -n "$specific_build" ]; then
        echo "$specific_build"
    else
        curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" | jq -r '.builds[-1]'
    fi
}

# Function to check if file exists in builds directory
check_file_exists() {
    local file_name=$1
    if [ -f "builds/$file_name" ]; then
        return 0
    else
        return 1
    fi
}

get_current_build_number() {
    local symlink_path="${BASE_DIR}/${SERVER_FOLDER}/$SERVER_JAR"
    if [ -L "$symlink_path" ]; then
        local symlink_target=$(readlink "$symlink_path")
        # Extract build number from filename pattern "paper-<version>-<build>.jar"
        local build_number=$(echo "$symlink_target" | sed -n 's/.*paper-.*-\([0-9]\+\)\.jar/\1/p')
        if [ -n "$build_number" ]; then
            echo "$build_number"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Function to handle build updates
handle_build_update() {
    local requested_build_number=$PAPER_VERSION

    # Check if the server is running
    if is_server_running; then
        local current_build=$(get_current_build_number)
        if [[ "$requested_build_number" = "latest" ]]; then
            check_for_update
        elif [[ "$requested_build_number" != "$current_build" ]]; then
            log_bold_nodate_warning "Server is currently running build #$current_build. Please stop the server before changing builds."
            check_and_attach_screen_session
        else
            log_bold_nodate_info "Server is already running build #$current_build."
            offer_to_attach
        fi
    else
        get_build "$BASE_DIR" "$SERVER_FOLDER" "$requested_build_number"
        start_minecraft_server
    fi
}

# Function to offer attaching to the current session
offer_to_attach() {
    if confirm_action "Would you like to attach to the server console?"; then
        screen -r "$SESSION"
    fi
}

# Function to check if an update is available and prompt the user
check_for_update() {
    local latest_build=$(get_latest_build "$(get_latest_version)")
    local current_build=$(get_current_build_number)

    if [[ "$latest_build" != "$current_build" ]]; then
        log_bold_nodate_warning "[WARNING] - Server update available. Current build: #$current_build, Latest build: #$latest_build."
        if confirm_action "Do you want to update to the latest build?"; then
            get_build "$BASE_DIR" "$SERVER_FOLDER"
            start_minecraft_server
        fi
    else
        log_bold_nodate_focus "Server is up-to-date with the latest build #$latest_build."
        check_and_attach_screen_session
    fi
}

# Function to check if the server is running
is_server_running() {
    screen -list | grep -q "$SESSION"
}

# Function specifically for starting the server when called by systemd
start_server_for_systemd() {
    log_nodate_info "Starting Minecraft server for systemd..."
    get_build "$BASE_DIR" "$SERVER_FOLDER"
    start_minecraft_server
    log_nodate_info "Minecraft server started by systemd."
}

# Parse command-line arguments
parse_arguments() {
    while [[ "$1" != "" ]]; do
        case $1 in
            help )
                usage
                exit 0
                ;;
            auto )
                SYSTEMCTL_AUTO_START=true
                ;;
            * )
                main
                ;;
        esac
        shift
    done
}

# Function to stop, disable, and remove the systemd service
stop_disable_and_remove_systemctl() {
    # Check if the service is active and stop it
    if systemctl --quiet is-active $SERVICE_NAME; then
        log_bold_nodate_info "Stopping $SERVICE_NAME service..."

        # Check if the screen session exists and send 'stop' command to the Minecraft server
        if screen -list | grep -q "$SESSION"; then
            log_bold_nodate_info "Sending stop command to the Minecraft server..."
            screen -S "$SESSION" -p 0 -X stuff "stop$(printf \\r)"

            # Wait for the server to shut down gracefully
            log_bold_nodate_info "Waiting for the server to shut down gracefully..."
            while screen -list | grep -q "$SESSION"; do
                sleep 5  # Adjust this sleep duration as needed
            done

            log_bold_nodate_success "Minecraft server stopped gracefully."
        else
            log_bold_nodate_warning "No screen session found. Proceeding to stop the service directly."
        fi

        sudo systemctl stop $SERVICE_NAME
    fi

    # Check if the service is enabled and disable it
    if systemctl --quiet is-enabled $SERVICE_NAME; then
        log_bold_nodate_info "Disabling $SERVICE_NAME service..."
        sudo systemctl disable $SERVICE_NAME
    fi

    # Remove the service file
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        log_bold_nodate_info "Removing $SERVICE_NAME service file..."
        sudo rm "/etc/systemd/system/$SERVICE_NAME.service"
        sudo systemctl daemon-reload
        sudo systemctl reset-failed
    fi

    log_bold_nodate_success "$SERVICE_NAME.service stopped, disabled, and removed successfully."
}

# Function to create the systemd service
create_systemctl() {
    local session_name="$SESSION"
    local eula_file="$SERVER_FOLDER/eula.txt"

    # Check if service already exists
    if systemctl --quiet is-active $SERVICE_NAME || systemctl --quiet is-enabled $SERVICE_NAME; then
        log_bold_nodate_note "Service $SERVICE_NAME already exists and is active or enabled."
        return 0  # Skip systemctl start process
    fi

    # EULA acceptance check
    if [[ ! -f "$eula_file" || $(grep -c 'eula=false' "$eula_file") -gt 0 ]]; then
        log_bold_nodate_tip "You must accept the Minecraft EULA to start the server."
        log_bold_nodate_tip "Read it here: https://aka.ms/MinecraftEULA"
        if confirm_action "Do you accept the Minecraft EULA?"; then
            echo "eula=true" > "$eula_file"
            log_bold_nodate_confirmation "EULA accepted."
        else
            log_bold_nodate_error "Minecraft EULA was declined. Cannot start the server."
            exit 1
        fi
    fi

    # Create and start the systemd service
    sudo bash -c "cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=$DESCRIPTION

[Service]
Environment='CALLED_BY_SYSTEMD=1'
Type=forking
ExecStart=$SCRIPT_PATH
WorkingDirectory=$WORKING_DIR
User=$USER
Group=$GROUP
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME

    log_bold_nodate_success "$SERVICE_NAME.service created and started successfully."
}

# Function to check and attach to existing screen session
check_and_attach_screen_session() {
    local session_name="$SESSION"
    if screen -list | grep -q "$session_name"; then
        log_bold_nodate_alert "A screen session named '$session_name' is already running."
        log_bold_nodate_prompt "Do you want to attach to this session? [y/N]"
        read -r attach_session
        if [[ $attach_session =~ ^[Yy]$ ]]; then
            screen -r "$session_name"
            # After attempting to attach, check if the screen session is still active
            if screen -list | grep -q "$session_name"; then
                log_bold_nodate_highlight "Detached from screen session. Server is running in the background. Use 'screen -r $session_name' to re-attach."
            else
                log_bold_nodate_error "Server shutdown or screen session terminated."
            fi
            exit 0
        else
            log_bold_nodate_highlight "Skipping screen attachment. Use 'screen -r $session_name' to re-attach later."
        fi
        exit 0
    fi
}

# Function to download and link a specific build
get_build() {
    local base_dir=$1
    local server_folder=$2
    local session_name="$SESSION"
    local server_jar="$SERVER_JAR"
    local symlink_path="${base_dir}/${server_folder}/$server_jar"

    # Check if server is running
    if screen -list | grep -q "$session_name"; then
        log_bold_nodate_warning "Server is currently running. Please stop the server before changing builds."
        exit 1
    fi

    # Extract the current symlinked build number
    local current_build=$(get_current_build_number)

    # Determine the requested build number based on PAPER_VERSION
    local latest_version=$(get_latest_version)
    local requested_build_number
    if [ "$PAPER_VERSION" = "latest" ]; then
        requested_build_number=$(get_latest_build "$latest_version")
        log_nodate_info "Fetching latest build: $requested_build_number..."
    else
        requested_build_number="$PAPER_VERSION"
        log_nodate_info "Fetching specified build: $requested_build_number..."
    fi

    local file_name="paper-$latest_version-$requested_build_number.jar"
    local file_path="${base_dir}/lib/builds/$file_name"

    mkdir -p "${base_dir}/lib/builds"
    mkdir -p "${base_dir}/${server_folder}"

    if [ ! -f "$file_path" ]; then
        log_nodate_info "Downloading $file_name ..."
        if curl -o "$file_path" -# "https://api.papermc.io/v2/projects/paper/versions/$latest_version/builds/$requested_build_number/downloads/$file_name"; then
            log_bold_nodate_success "Download complete."
            log_bold_info "Downloaded $file_name."
        else
            log_bold_nodate_error "Download failed. Please check the build number and version, and try again."
            exit 1
        fi
    else
        log_nodate_note "$file_name already exists. Skipping download."
    fi

    if [ "$requested_build_number" != "$current_build" ] || [ ! -L "$symlink_path" ]; then
        if [ -L "$symlink_path" ] || [ -f "$symlink_path" ]; then
            rm "$symlink_path"
        fi
        ln -s "$file_path" "$symlink_path"
        log_nodate_note "Linked $file_name to ${server_folder}/$server_jar."
    else
        log_nodate_note "Current build matches the requested build. No need to re-link."
    fi
}

# Function to configure the Minecraft server
configure_minecraft_server() {
    local server_properties="$SERVER_FOLDER/server.properties"

    # Update server properties
    {
        echo "motd=$MOTD"
        echo "difficulty=$DIFFICULTY"
        echo "enforce-whitelist=$ENFORCE_WHITELIST"
        echo "white-list=$WHITE_LIST"
        echo "gamemode=$GAMEMODE"
        echo "level-name=$LEVEL_NAME"
        echo "max-players=$MAX_PLAYERS"
        echo "pvp=$PVP"
        echo "server-ip=$SERVER_IP"
        echo "server-port=$SERVER_PORT"
    } > "$server_properties"

    log_nodate_success "Minecraft server properties configured."
}


# Function to start the Minecraft server inside a screen session
start_minecraft_server() {
    local session_name="$SESSION"
    local java_options="$JAVA_OPTS"
    local server_folder="$SERVER_FOLDER"
    local server_jar="$SERVER_JAR"
    local eula_file="$server_folder/eula.txt"

    # Check if the screen session already exists
    if screen -list | grep -q "$session_name"; then
        log_bold_nodate_alert "A screen session named '$session_name' is already running."
        log_bold_nodate_prompt "Do you want to attach to this session? [y/N]"
        read -r attach_session
        if [[ $attach_session =~ ^[Yy]$ ]]; then
            screen -r "$session_name"
            # After attempting to attach, check if the screen session is still active
            if screen -list | grep -q "$session_name"; then
                log_bold_nodate_highlight "Detached from screen session. Server is running in the background. Use 'screen -r $session_name' to re-attach."
            else
                log_bold_nodate_error "Server shutdown or screen session terminated."
            fi
            log_nodate_success "Main script execution completed"
            exit 0
        else
            log_bold_nodate_highlight "Skipping screen attachment. Use 'screen -r $session_name' to re-attach later."
            return 0
        fi
    fi

    # Check if EULA is already accepted
    if [[ -f "$eula_file" && $(grep -c 'eula=true' "$eula_file") -gt 0 ]]; then
        log_nodate_success "EULA already accepted. Starting the server..."
    else
        echo "You must accept the Minecraft EULA to start the server."
        echo "Read it here: https://aka.ms/MinecraftEULA"
        if confirm_action "Do you accept the Minecraft EULA?"; then
            echo "eula=true" > "$eula_file"
            log_nodate_success "EULA accepted. Starting the server..."
        else
            log_bold_nodate_error "Minecraft EULA was declined. Exiting script."
            exit 1
        fi
    fi

    # Start the server in a detached screen session and redirect output to logfile
    (
        configure_minecraft_server
        cd "$server_folder"
        screen -dmS "$session_name" bash -c "java $java_options -jar '$server_jar' --nogui 2>&1 | tee -a '$LOG_FILE'"
    )
    log_bold_nodate_success "Started Minecraft server in a screen session named '$session_name'."

    # Prompt to screen in
    log_bold_nodate_prompt "Do you want to attach to the '$session_name' server screen session? [Y/n] (Default: No in 10 seconds)"
    read -t 10 -r -p "" screen_in
    screen_in=${screen_in:-N}  # Default to 'N' if no input is provided

    if [[ $screen_in =~ ^[Yy]$ ]]; then
        screen -r "$session_name"
        # After attempting to attach, check if the screen session is still active
        if screen -list | grep -q "$session_name"; then
            log_bold_nodate_highlight "Detached from screen session. Server is running in the background. Use 'screen -r $session_name' to re-attach."
        else
            log_bold_nodate_error "Server shutdown or screen session terminated."
        fi
        log_nodate_success "Main script execution completed"
        exit 0
    else
        log_bold_nodate_highlight "Server is running in the background. Use 'screen -r $session_name' to attach to the session."

        # Launch a background process to monitor the screen session
        (
            while screen -list | grep -q "$session_name"; do
                sleep 10  # Check every 10 seconds
            done
        ) &
        # Immediate return to the command prompt
        disown
        exit 0
    fi
}
