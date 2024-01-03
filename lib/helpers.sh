#!/bin/bash
# This script contains helper functions that provide various utilities to the application.

# Sets the terminal title to the provided argument.
# Inputs: 
#   $1 - The title string to be set for the terminal.
# Usage: 
#   set_terminal_title "My Application"
set_terminal_title() {
    local title=$1

    # Setting the terminal title
    echo -ne "\\033]0;${title}\\007"

    # Consider adding error handling if necessary
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

# Main function to get the build
get_build() {
    local base_dir=$1      # The base directory path
    local server_folder=$2 # Server folder name
    local build_number=$3  # Build number

    # Check if build number is provided
    if [ -z "$build_number" ]; then
        # No build number provided, get the latest build
        build_number=$(get_latest_build "$(get_latest_version)")
        log_nodate_info "Fetching the latest build of the latest version"
    else
        log_nodate_info "Fetching build number $build_number of the latest version"
    fi

    local version=$(get_latest_version)
    local file_name="paper-$version-$build_number.jar"
    local file_path="${base_dir}/builds/${file_name}"  # Absolute path for the file
    local download_url="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build_number/downloads/$file_name"

    # Create directories if they don't exist
    mkdir -p "${base_dir}/builds"
    mkdir -p "${base_dir}/${server_folder}"

    # Check if the file already exists
    if [ -f "${file_path}" ]; then
        log_nodate_note "$file_name already exists. Skipping download."
    else
        # Download the file
        log_nodate_info "Downloading $file_name ..."
        if curl -o "${file_path}" -# "$download_url"; then
            log_bold_nodate_success "Download complete."
            log_bold_info "Downloaded $file_name."
        else
            log_bold_nodate_error "Download failed. Please check the build number and version, and try again."
            exit 1
        fi
    fi

    # Link to server_files/paper.jar
    local symlink_path="${base_dir}/${server_folder}/paper.jar"
    if [ -f "${file_path}" ]; then
        if [ -L "${symlink_path}" ] || [ -f "${symlink_path}" ]; then
            rm "${symlink_path}"  # Remove existing symlink or file
        fi
        ln -s "${file_path}" "${symlink_path}"
        log_nodate_note "Linked ${file_name} to ${server_folder}/paper.jar."
    else
        log_bold_nodate_error "Error: The file ${file_path} does not exist. Cannot create symbolic link."
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
        log_bold_nodate_warning "A screen session named '$session_name' is already running."
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
        # Prompt for EULA acceptance
        log_bold_nodate_prompt "Do you accept the Minecraft EULA? (https://aka.ms/MinecraftEULA) [y/N]"
        read -r eula_acceptance
        if [[ $eula_acceptance =~ ^[Yy]$ ]]; then
            # User accepted the EULA, generate eula.txt
            echo "#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA)." > "$eula_file"
            echo "#$(date) - grab current timestamp" >> "$eula_file"
            echo "eula=true" >> "$eula_file"
            log_nodate_success "EULA accepted. Starting the server..."
        else
            # User declined the EULA, exit the script
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
    log_nodate_info "Started Minecraft server in a screen session named '$session_name'."


    # Prompt to screen in
    log_bold_nodate_prompt "Do you want to attach to the '$session_name' server screen session? [y/N]"
    read -t 4 -r screen_in
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
            log_bold_nodate_error "Server session '$session_name' has ended!"
        ) &
        
        log_nodate_success "Main script execution completed"
        # Immediate return to the command prompt
        disown
        exit 0
    fi
}