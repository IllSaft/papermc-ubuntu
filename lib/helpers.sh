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
# Helper Functions

set_terminal_title() {
    echo -ne "\\033]0;${1}\\007"
}

confirm_action() {
    local prompt="${1:-$CONFIRM_PROMPT_DEFAULT}"
    log_bold_nodate_prompt "🔵 $prompt [🟢 y/🔴 N]: "
    read -r response
    [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] && return 0 || return 1
}

input_prompt() {
    read -r -p "${1}: " input
    echo "$input"
}

wait_for_keypress() {
    read -r -n1 -p "Press any key to continue..."
    echo
}

# Function for the main menu
main_menu() {
    while true; do
        echo "========================================"
        echo " PaperMC Server Management Menu"
        echo "========================================"
        echo "1. Start Minecraft Server"
        echo "2. Toggle Maintenance Mode"
        echo "3. Exit"
        echo "----------------------------------------"
        echo -n "Enter your choice [1-3]: "
        read -r choice

        case $choice in
            1) start_minecraft_server ;;
            2) toggle_maintenance_mode ;;
            3) echo "Exiting..."; return 0 ;;
            *) echo "Invalid choice. Please select 1, 2, or 3."; sleep 2 ;;
        esac
    done
}

# Function to toggle maintenance mode
toggle_maintenance_mode() {
    if [ "$MM_MODE" = true ]; then
        disable_maintenance_mode
    else
        maintenance_mode
    fi
}


maintenance_mode() {
    local server_properties="$SERVER_FOLDER/server.properties"
    local whitelist_file="$SERVER_FOLDER/whitelist.json"
    local settings_file="$BASE_DIR/config/settings.cfg"

    if [ "$MM_MODE" = true ]; then
        log_bold_nodate_warning "Maintenance mode is already enabled."
        return 0
    fi

    # Notify players and initiate maintenance
    if is_server_running; then
        # Notify players to disconnect
        screen -S "$SESSION" -p 0 -X stuff "say Server entering maintenance mode. Please disconnect.\n"
        sleep 20 # Give players time to see the message and disconnect

        # Gracefully stop the server
        screen -S "$SESSION" -p 0 -X stuff "stop\n"
        log_bold_nodate_info "Stopping Minecraft server for maintenance..."

        # Wait for server to stop
        while is_server_running; do
            sleep 5 # Adjust this sleep duration as needed
        done
        log_bold_nodate_success "Minecraft server stopped for maintenance."
    fi

    # Activate whitelist and clear it
    cp "$server_properties" "${server_properties}.bak"             # Backup server properties
    cp "$whitelist_file" "${whitelist_file}.bak"                   # Backup whitelist
    echo "[]" >"$whitelist_file"                                   # Clear whitelist
    sed -i 's/white-list=.*/white-list=true/' "$server_properties" # Enable whitelist

    # Update MM_MODE in script environment and settings.cfg file
    MM_MODE=true
    sed -i 's/^MM_MODE=.*/MM_MODE=true/' "$settings_file"

    log_bold_nodate_success "Maintenance mode enabled. Server is now in whitelist-only mode."
}


# Function to disable maintenance mode
disable_maintenance_mode() {
    local server_properties="$SERVER_FOLDER/server.properties"
    local whitelist_file="$SERVER_FOLDER/whitelist.json"
    local settings_file="$BASE_DIR/config/settings.cfg"

    if [ "$MM_MODE" = false ]; then
        log_bold_nodate_warning "Maintenance mode is not currently enabled."
        return 0
    fi

    # Check if backups exist before restoring
    [[ -f "${server_properties}.bak" ]] && mv "${server_properties}.bak" "$server_properties"
    [[ -f "${whitelist_file}.bak" ]] && mv "${whitelist_file}.bak" "$whitelist_file"

    # Update MM_MODE in script environment and settings.cfg file
    MM_MODE=false
    sed -i 's/^MM_MODE=.*/MM_MODE=false/' "$settings_file"

    log_bold_nodate_success "Maintenance mode disabled. Server settings restored."
}

# Function to check if the Minecraft server is running
is_server_running() {
    screen -list | grep -q "$SESSION"
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
            local latest_build=$(get_latest_build "$(get_latest_version)")
            if [[ "$latest_build" != "$current_build" ]]; then
                log_bold_nodate_warning "[WARNING] - Server update available. Current build: #$current_build, Latest build: #$latest_build."
                if confirm_action "Do you want to update to the latest build?"; then
                    get_build "$BASE_DIR" "$SERVER_FOLDER"
                    start_minecraft_server
                else
                    offer_to_attach
                fi
            else
                log_bold_nodate_info "Server is already running the latest build #$current_build."
                offer_to_attach
            fi
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
    log_bold_nodate_note "Starting Minecraft server for systemd..."
    get_build "$BASE_DIR" "$SERVER_FOLDER"
    start_minecraft_server
    log_bold_nodate_info "Minecraft server started by systemd."
}

# Parse command-line arguments
parse_arguments() {
    while [[ "$1" != "" ]]; do
        case $1 in
        help)
            usage
            exit 0
            ;;
        auto)
            SYSTEMCTL_AUTO_START=true
            ;;
        *)
            main
            ;;
        esac
        shift
    done
}

# Function to stop, disable, and remove the systemd service
stop_disable_and_remove_systemctl() {
    local service_file="/etc/systemd/system/$SERVICE_NAME.service"

    # Exit if the service file does not exist
    if [ ! -f "$service_file" ]; then
        log_bold_nodate_note "$SERVICE_NAME.service file does not exist. Skipping process."
        return 0
    fi

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
                sleep 5 # Adjust this sleep duration as needed
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
    log_bold_nodate_info "Removing $SERVICE_NAME service file..."
    sudo rm "$service_file"
    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    log_bold_nodate_success "$SERVICE_NAME.service stopped, disabled, and removed successfully."
}

# Function to create the systemd service
create_systemctl() {
    local session_name="$SESSION"
    local eula_file="$SERVER_FOLDER/eula.txt"

    # Check and create SERVER_FOLDER if it doesn't exist
    if [ ! -d "$SERVER_FOLDER" ]; then
        mkdir -p "$SERVER_FOLDER"
    fi

    # Check if service already exists
    if systemctl --quiet is-active $SERVICE_NAME || systemctl --quiet is-enabled $SERVICE_NAME; then
        log_bold_nodate_note "Service $SERVICE_NAME already exists and is active or enabled."
        return 0 # Skip systemctl start process
    fi

    # EULA acceptance check
    if [[ ! -f "$eula_file" || $(grep -c 'eula=false' "$eula_file") -gt 0 ]]; then
        log_bold_nodate_tip "You must$COLOR_INFO accept$COLOR_TIP the Minecraft$COLOR_HIGHLIGHT EULA$COLOR_TIP to start the server."
        log_bold_nodate_tip "Read it here:$COLOR_CAUTION https://aka.ms/MinecraftEULA"
        if confirm_action "Do you accept the Minecraft$COLOR_HIGHLIGHT EULA?"; then
            echo "eula=true" >"$eula_file"
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
    local requested_build_number=$PAPER_VERSION
    local session_name="$SESSION"
    local server_jar="$SERVER_JAR"
    local symlink_path="${base_dir}/${server_folder}/$server_jar"

    # Check if server is running
    if screen -list | grep -q "$session_name"; then
        log_bold_nodate_warning "Server is currently running. Please stop the server before changing builds."
        exit 1
    fi

    # Determine the latest version and build number
    local latest_version=$(get_latest_version)
    local latest_build=$(get_latest_build "$latest_version")

    # Handle 'latest' version setting
    if [ "$requested_build_number" = "latest" ]; then
        requested_build_number=$latest_build
    fi

    # Check for updates if running version is not the requested version
    local current_build=$(get_current_build_number)
    if [[ "$requested_build_number" != "$current_build" ]]; then
        log_bold_nodate_focus "Fetching build: $requested_build_number (Current build: $current_build)..."
    else
        log_custom_prefix_1 "PaperMC Build #$current_build. Matches requested build. No update required."
        return 0
    fi

    local file_name="paper-$latest_version-$requested_build_number.jar"
    local file_path="${base_dir}/lib/builds/$file_name"

    mkdir -p "${base_dir}/lib/builds"
    mkdir -p "${base_dir}/${server_folder}"

    # Download build if it doesn't exist
    if [ ! -f "$file_path" ]; then
        log_bold_nodate_info "Downloading $file_name ..."
        if ! curl -o "$file_path" -# "https://api.papermc.io/v2/projects/paper/versions/$latest_version/builds/$requested_build_number/downloads/$file_name"; then
            log_bold_nodate_error "Download failed. Please check the build number and version, and try again."
            exit 1
        fi
        log_bold_nodate_success "Download complete. Downloaded $file_name."
    else
        log_nodate_note "$file_name already exists. Skipping download."
    fi

    # Link build if different from current build
    if [ ! -L "$symlink_path" ] || [ "$(readlink "$symlink_path")" != "$file_path" ]; then
        [ -L "$symlink_path" ] && rm "$symlink_path"
        ln -s "$file_path" "$symlink_path"
        log_nodate_note "Linked $file_name to ${server_folder}/$server_jar."
    else
        log_nodate_note "Current build matches the requested build. No need to re-link."
    fi
}

# Function to configure the Minecraft server
configure_minecraft_server() {
    local server_properties="$SERVER_FOLDER/server.properties"

    # Check if server is in maintenance mode
    if [ "$MM_MODE" = true ]; then
        echo "⚙️ Server is in Maintenance Mode. Enabling whitelist..."
        WHITE_LIST="true"
        MOTD="§d§l--\\\\ §e§k||| §c§l§oMC4ALL MM MODE§7§l§o! §e§k||| §d\\\\--§r"
    fi

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

    log_bold_nodate_note "🛠️  Minecraft server properties configured."
}

start_minecraft_server() {
    local session_name="$SESSION"
    local java_options="$JAVA_OPTS"
    local server_folder="$SERVER_FOLDER"
    local server_jar="$SERVER_JAR"
    local eula_file="$server_folder/eula.txt"

    echo "----------------------------------------"
    echo "🌟 Starting Minecraft Server 🌟"
    echo "----------------------------------------"

    # Check if the server is already running
    if screen -list | grep -q "$session_name"; then
        log_bold_nodate_alert "🚨 A screen session named '$session_name' is already running."
        log_bold_nodate_prompt "🔗 Do you want to attach to this session? [Y/n]: "
        read -r attach_session

        if [[ $attach_session =~ ^[Yy]$ ]]; then
            screen -r "$session_name"
            log_bold_nodate_highlight "🔹 Detached from screen session. Server is running in the background."
            exit 0
        else
            log_bold_nodate_highlight "👋 Skipping screen attachment."
            return 0
        fi
    fi

    # EULA acceptance check
    if [[ ! -f "$eula_file" || $(grep -c 'eula=false' "$eula_file") -gt 0 ]]; then
        log_bold_nodate_tip "📜 You must accept the Minecraft EULA to start the server."
        if confirm_action "🤝 Do you accept the Minecraft EULA?"; then
            echo "eula=true" > "$eula_file"
            log_bold_nodate_confirmation "👍 EULA accepted."
        else
            log_bold_nodate_error "❌ Minecraft EULA was declined. Server cannot start."
            exit 1
        fi
    fi

    # Check for maintenance mode
    if [ "$MM_MODE" = true ]; then
        log_bold_nodate_warning "⚠️ Server is currently in Maintenance Mode."
        if ! confirm_action "🛠️ Do you want to continue starting the server in Maintenance Mode?"; then
            log_bold_nodate_highlight "🔸 Server start aborted."
            return 0
        fi
    fi

    # Start server
    log_bold_nodate_prompt "🚀 Do you want to start the Minecraft server? [Y/n] (auto-start in 8 seconds): "
    read -t 8 -r start_server
    start_server=${start_server:-Y}

    if [[ $start_server =~ ^[Yy]$ ]]; then
        # Configure the server considering maintenance mode
        configure_minecraft_server
        cd "$server_folder"
        screen -dmS "$session_name" bash -c "java $java_options -jar '$server_jar' --nogui 2>&1 | tee -a '$LOG_FILE'"
        log_bold_nodate_success "🎉 Server is starting in a screen session named '$session_name'."

        log_bold_nodate_prompt "🔎 Do you want to attach to the server console? [Y/n] (auto-no in 10 seconds): "
        read -t 10 -r screen_in
        screen_in=${screen_in:-N}

        if [[ $screen_in =~ ^[Yy]$ ]]; then
            screen -r "$session_name"
        else
            log_bold_nodate_highlight "👍 Server is running in the background."
        fi
    else
        log_bold_nodate_warning "🛑 Server startup aborted."
    fi
}