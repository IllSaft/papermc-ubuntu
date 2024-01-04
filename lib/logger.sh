#!/bin/bash
# Logger.sh - Provides enhanced logging functionalities for Bash scripts
# Initializes the logger by archiving the old log file if no screen session is active, and creating a new one
initiate_logger() {
    local session_name="$SESSION" # Replace with your screen session name

    if [[ -z $LOGGER_INITIALIZED ]]; then
        # Check if no screen session is running
        if ! screen -list | grep -q "$session_name"; then
            # No active screen session, check if log file exists and gzip it
            if [ -f "$LOG_FILE" ]; then
                local timestamp=$(date +"%Y%m%d-%H%M%S")
                gzip -c "$LOG_FILE" >"${LOG_FILE}-${timestamp}.gz"
            fi

            # Create/clear the new log file
            >"$LOG_FILE"
            log_bold_nodate_success "Logger Initialized and new log file created."
            log_bold_nodate_tip "Previous log file archived as ${LOG_FILE}-${timestamp}.gz"
        else
            # Active screen session found, continue with existing log file
            log_bold_nodate_success "Logger Initialized, continuing with existing log file."
        fi
        export LOGGER_INITIALIZED=true
    fi
}
source "config/settings.cfg"  # Update this path to the actual location of settings.cfg
# Core Logging Function
log_event() {
    local original_mood=$1
    local narrative=$2
    local mood=$original_mood
    local is_bold=false
    local is_nodate=false
    local is_custom=false
    local is_verbose=false
    local is_debug=false

    # Extracting flags from the mood
    if [[ $mood == "BOLD_"* ]]; then
        is_bold=true
        mood="${mood#BOLD_}"
    fi
    if [[ $mood == "NODATE_"* ]]; then
        is_nodate=true
        mood="${mood#NODATE_}"
    fi
    if [[ $mood == "CUSTOM_"* ]]; then
        is_custom=true
        mood="${mood#CUSTOM_}"
    fi
    if [[ $mood == "VERBOSE_"* ]]; then
        is_verbose=true
        mood="${mood#VERBOSE_}"
    fi
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        is_debug=true
    fi

    # Applying custom colors for custom moods
    if [[ "$is_custom" == true ]]; then
        mood_style_console="${COLOR_PALETTE[$original_mood]}"
    fi

    # Apply debug and verbose color based on settings.cfg for console output
    local debug_color_console="${COLOR_DEBUG}"
    local verbose_color_console="${COLOR_VERBOSE}"
    local debug_prefix_console=""
    local verbose_prefix_console=""

    if [[ "$VERBOSE_MODE" == true ]]; then
        verbose_prefix_console="${verbose_color_console}[VERBOSE]\033[0m"
        debug_prefix_console="${debug_color_console}[DEBUG]\033[0m — "
    fi
    if [[ "$is_debug" == true ]]; then
        debug_prefix_console="${debug_color_console}[DEBUG]\033[0m — "
    fi

    # Determine the color and style based on mood
    local mood_style_console
    if [[ "$is_custom" == true ]]; then
        mood_style_console="${COLOR_PALETTE[$original_mood]}"
    else
        mood_style_console="${COLOR_PALETTE[$mood]}"
    fi
    [[ "$is_bold" == true ]] && mood_style_console="\033[1m${mood_style_console}"

    # Constructing console prefixes
    local console_prefix=""
    local logfile_prefix=""
    if [[ "$ENABLE_LOG_DATE" == true && "$is_nodate" == false ]]; then
        logfile_prefix="[$(date '+%b/%d/%Y — %-l:%M %p')]"
    fi
    console_prefix="$logfile_prefix"

    # Handling custom moods
    if [[ "$is_custom" == true ]]; then
        mood_style_console="${COLOR_PALETTE[$original_mood]}"
        local custom_prefix_text=""
        case $original_mood in
        "CUSTOM_PREFIX_1")
            custom_prefix="${LOG_PREFIX_1}"
            ;;
        "CUSTOM_PREFIX_2")
            custom_prefix="${LOG_PREFIX_2}"
            ;;
        "CUSTOM_PREFIX_3")
            custom_prefix="${LOG_PREFIX_3}"
            ;;
        *)
            custom_prefix="Custom" # Default text if custom prefix not defined
            ;;
        esac
        console_prefix="${mood_style_console}[${custom_prefix}]"
        logfile_prefix="[$custom_prefix]${logfile_prefix}"
    fi

    # Handling custom, mood, and INFO_HEADER prefixes for console
    if [[ "$ENABLE_INFO_HEADER" == true && "$mood" == "INFO_HEADER" ]]; then
        local info_header_color="${COLOR_INFO_HEADER}"
        if [[ "$USE_CUSTOM_INFO_HEADER" == true ]]; then
            console_prefix="${info_header_color}${CUSTOM_INFO_HEADER_TEXT}\033[0m"
            logfile_prefix="${logfile_prefix}${CUSTOM_INFO_HEADER_TEXT}" # No separator for logfile
        else
            console_prefix="${info_header_color}[INFO_HEADER]\033[0m"
            logfile_prefix="${logfile_prefix}[INFO_HEADER]" # No separator for logfile
        fi
    elif [[ "$is_custom" == false ]]; then
        console_prefix="${console_prefix}${mood_style_console}[$mood]"
        logfile_prefix="${logfile_prefix}[$mood]"
    fi

    # Logfile prefix (without color codes)
    local verbose_prefix_logfile=""
    local debug_prefix_logfile=""
    if [[ "$VERBOSE_MODE" == true ]]; then
        verbose_prefix_logfile="[VERBOSE] "
    fi
    if [[ "$is_debug" == true ]]; then
        debug_prefix_logfile="[DEBUG] "
    fi

    # Add separator if there is a prefix section
    [[ -n "$console_prefix" ]] && console_prefix="${console_prefix} — "
    [[ -n "$logfile_prefix" ]] && logfile_prefix="${logfile_prefix} — "

    # Displaying the messages
    local console_message="${verbose_prefix_console}${debug_prefix_console}${console_prefix}${style_console}${narrative}${COLOR_RESET}"
    echo -e "$console_message"
    local logfile_message="${verbose_prefix_logfile}${debug_prefix_logfile}${logfile_prefix}${narrative}"
    echo "$logfile_message" >>"$LOG_FILE"
}


# Standard Log Level Functions
log_info() { log_event "INFO" "$1"; }
log_success() { log_event "SUCCESS" "$1"; }
log_warning() { log_event "WARNING" "$1"; }
log_error() { log_event "ERROR" "$1"; }
log_info_header() { log_event "INFO_HEADER" "$1"; }
log_important() { log_event "IMPORTANT" "$1"; }
log_note() { log_event "NOTE" "$1"; }
log_tip() { log_event "TIP" "$1"; }
log_debug() { log_event "DEBUG" "$1"; }
log_confirmation() { log_event "CONFIRMATION" "$1"; }
log_alert() { log_event "ALERT" "$1"; }
log_caution() { log_event "CAUTION" "$1"; }
log_focus() { log_event "FOCUS" "$1"; }
log_highlight() { log_event "HIGHLIGHT" "$1"; }
log_neutral() { log_event "NEUTRAL" "$1"; }
log_prompt() { log_event "PROMPT" "$1"; }
log_status() { log_event "STATUS" "$1"; }
log_verbose() { log_event "VERBOSE" "$1"; }
log_question() { log_event "QUESTION" "$1"; }

# Bold Log Level Variants
log_bold_info() { log_event "BOLD_INFO" "$1"; }
log_bold_success() { log_event "BOLD_SUCCESS" "$1"; }
log_bold_warning() { log_event "BOLD_WARNING" "$1"; }
log_bold_error() { log_event "BOLD_ERROR" "$1"; }
log_bold_important() { log_event "BOLD_IMPORTANT" "$1"; }
log_bold_note() { log_event "BOLD_NOTE" "$1"; }
log_bold_tip() { log_event "BOLD_TIP" "$1"; }
log_bold_debug() { log_event "BOLD_DEBUG" "$1"; }
log_bold_confirmation() { log_event "BOLD_CONFIRMATION" "$1"; }
log_bold_alert() { log_event "BOLD_ALERT" "$1"; }
log_bold_caution() { log_event "BOLD_CAUTION" "$1"; }
log_bold_focus() { log_event "BOLD_FOCUS" "$1"; }
log_bold_highlight() { log_event "BOLD_HIGHLIGHT" "$1"; }
log_bold_neutral() { log_event "BOLD_NEUTRAL" "$1"; }
log_bold_prompt() { log_event "BOLD_PROMPT" "$1"; }
log_bold_status() { log_event "BOLD_STATUS" "$1"; }
log_bold_verbose() { log_event "BOLD_VERBOSE" "$1"; }
log_bold_question() { log_event "BOLD_QUESTION" "$1"; }

# No-Date Log Level Variants
log_nodate_info() { log_event "NODATE_INFO" "$1"; }
log_nodate_success() { log_event "NODATE_SUCCESS" "$1"; }
log_nodate_warning() { log_event "NODATE_WARNING" "$1"; }
log_nodate_error() { log_event "NODATE_ERROR" "$1"; }
log_nodate_info_header() { log_event "NODATE_INFO_HEADER" "$1"; }
log_nodate_important() { log_event "NODATE_IMPORTANT" "$1"; }
log_nodate_note() { log_event "NODATE_NOTE" "$1"; }
log_nodate_tip() { log_event "NODATE_TIP" "$1"; }
log_nodate_debug() { log_event "NODATE_DEBUG" "$1"; }
log_nodate_confirmation() { log_event "NODATE_CONFIRMATION" "$1"; }
log_nodate_alert() { log_event "NODATE_ALERT" "$1"; }
log_nodate_caution() { log_event "NODATE_CAUTION" "$1"; }
log_nodate_focus() { log_event "NODATE_FOCUS" "$1"; }
log_nodate_highlight() { log_event "NODATE_HIGHLIGHT" "$1"; }
log_nodate_neutral() { log_event "NODATE_NEUTRAL" "$1"; }
log_nodate_prompt() { log_event "NODATE_PROMPT" "$1"; }
log_nodate_status() { log_event "NODATE_STATUS" "$1"; }
log_nodate_verbose() { log_event "NODATE_VERBOSE" "$1"; }
log_nodate_question() { log_event "NODATE_QUESTION" "$1"; }

# Bold No-Date Log Level Variants
log_bold_nodate_info() { log_event "BOLD_NODATE_INFO" "$1"; }
log_bold_nodate_success() { log_event "BOLD_NODATE_SUCCESS" "$1"; }
log_bold_nodate_warning() { log_event "BOLD_NODATE_WARNING" "$1"; }
log_bold_nodate_error() { log_event "BOLD_NODATE_ERROR" "$1"; }
log_bold_nodate_info_header() { log_event "BOLD_NODATE_INFO_HEADER" "$1"; }
log_bold_nodate_important() { log_event "BOLD_NODATE_IMPORTANT" "$1"; }
log_bold_nodate_note() { log_event "BOLD_NODATE_NOTE" "$1"; }
log_bold_nodate_tip() { log_event "BOLD_NODATE_TIP" "$1"; }
log_bold_nodate_debug() { log_event "BOLD_NODATE_DEBUG" "$1"; }
log_bold_nodate_confirmation() { log_event "BOLD_NODATE_CONFIRMATION" "$1"; }
log_bold_nodate_alert() { log_event "BOLD_NODATE_ALERT" "$1"; }
log_bold_nodate_caution() { log_event "BOLD_NODATE_CAUTION" "$1"; }
log_bold_nodate_focus() { log_event "BOLD_NODATE_FOCUS" "$1"; }
log_bold_nodate_highlight() { log_event "BOLD_NODATE_HIGHLIGHT" "$1"; }
log_bold_nodate_neutral() { log_event "BOLD_NODATE_NEUTRAL" "$1"; }
log_bold_nodate_prompt() { log_event "BOLD_NODATE_PROMPT" "$1"; }
log_bold_nodate_status() { log_event "BOLD_NODATE_STATUS" "$1"; }
log_bold_nodate_verbose() { log_event "BOLD_NODATE_VERBOSE" "$1"; }
log_bold_nodate_question() { log_event "BOLD_NODATE_QUESTION" "$1"; }

# Custom Prefix Logging Functions
log_custom_prefix_1() { log_event "CUSTOM_PREFIX_1" "$1"; }
log_custom_prefix_2() { log_event "CUSTOM_PREFIX_2" "$1"; }
log_custom_prefix_3() { log_event "CUSTOM_PREFIX_3" "$1"; }

# Bold Variants
log_bold_custom_prefix_1() { log_event "BOLD_CUSTOM_PREFIX_1" "$1"; }
log_bold_custom_prefix_2() { log_event "BOLD_CUSTOM_PREFIX_2" "$1"; }
log_bold_custom_prefix_3() { log_event "BOLD_CUSTOM_PREFIX_3" "$1"; }

# No-Date Variants
log_nodate_custom_prefix_1() { log_event "NODATE_CUSTOM_PREFIX_1" "$1"; }
log_nodate_custom_prefix_2() { log_event "NODATE_CUSTOM_PREFIX_2" "$1"; }
log_nodate_custom_prefix_3() { log_event "NODATE_CUSTOM_PREFIX_3" "$1"; }

# Bold No-Date Variants
log_bold_nodate_custom_prefix_1() { log_event "BOLD_NODATE_CUSTOM_PREFIX_1" "$1"; }
log_bold_nodate_custom_prefix_2() { log_event "BOLD_NODATE_CUSTOM_PREFIX_2" "$1"; }
log_bold_nodate_custom_prefix_3() { log_event "BOLD_NODATE_CUSTOM_PREFIX_3" "$1"; }

# [Rest of your script...]