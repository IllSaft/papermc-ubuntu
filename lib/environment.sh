#!/bin/bash
# Verifies if the current environment meets the necessary conditions for running the application.
# Outputs: Logs information and errors related to environment compatibility.
install_corretto_21() {
    local keyring_path="/usr/share/keyrings/corretto-keyring.gpg"
    local corretto_list="/etc/apt/sources.list.d/corretto.list"

    # Check if the keyring file already exists
    if [ ! -f "$keyring_path" ]; then
        wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o "$keyring_path"
    fi

    # Check if the corretto list file already exists
    if [ ! -f "$corretto_list" ]; then
        echo "deb [signed-by=$keyring_path] https://apt.corretto.aws stable main" | sudo tee "$corretto_list"
    fi

    sudo apt-get update && sudo apt-get install -y java-21-amazon-corretto-jdk
}
check_corretto_21_installation() {
    local java_version_output=$(java -version 2>&1)
    if [[ $java_version_output != *"Corretto-21"* ]]; then
        return 1 # Corretto 21 not found
    else
        return 0 # Corretto 21 is installed
    fi
}

check_installation() {
    local tool_name=$1
    local check_command=$2 # Command or function to verify installation

    if ! $check_command &>/dev/null; then
        log_bold_nodate_error "Required tool '$tool_name' is not installed."
        read -p "Do you want to install '$tool_name' now? [y/N] " answer
        if [[ $answer =~ ^[Yy]$ ]]; then
            if [ "$tool_name" == "java-21-amazon-corretto-jdk" ]; then
                install_corretto_21 || {
                    log_bold_nodate_error "Failed to install '$tool_name'. Exiting script."
                    exit 1
                }
            else
                sudo apt-get install "$tool_name" || {
                    log_bold_nodate_error "Failed to install '$tool_name'. Exiting script."
                    exit 1
                }
            fi
            # Recheck after installation
            $check_command || {
                log_bold_nodate_error "Installation of '$tool_name' was unsuccessful. Exiting script."
                exit 1
            }
        else
            log_bold_nodate_error "Installation of '$tool_name' declined. Exiting script."
            exit 1
        fi
    fi
}

verify_environment() {
    log_bold_nodate_important "Environment Verification: Ensuring Compatibility"

    local required_tools=("java-21-amazon-corretto-jdk" "jq" "screen")
    local all_tools_installed=true

    for tool in "${required_tools[@]}"; do
        if [ "$tool" == "java-21-amazon-corretto-jdk" ]; then
            check_installation "$tool" check_corretto_21_installation || all_tools_installed=false
        else
            check_installation "$tool" "command -v $tool" || all_tools_installed=false
        fi
    done

    if [ "$all_tools_installed" = true ]; then
        log_bold_nodate_note "'${required_tools[*]}' are already installed."
    fi

    log_bold_nodate_success "Environment Setup."
}
