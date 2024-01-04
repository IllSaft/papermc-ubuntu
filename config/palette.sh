# Color Palette Script
# This script defines a color palette using `tput` commands for logging and styling.

# Load Custom Colors from Settings
# Ensure that settings.cfg exists in the correct path
if [ -f "./config/settings.cfg" ]; then
    source ./config/settings.cfg
else
    echo "Error: settings.cfg not found. Please check the path."
    exit 1
fi
# Color Customization for Log Levels
# Primary Colors for basic log levels
COLOR_INFO=$(tput setaf 119)    # Very Light Green for informational messages
COLOR_WARNING=$(tput setaf 208) # Dark Orange for warnings
COLOR_ERROR=$(tput setaf 124)   # Deep Dark Red for errors

# Extended Colors for additional log levels
COLOR_INFO_HEADER=$(tput setaf 141)  # Lavender for INFO_HEADER
COLOR_IMPORTANT=$(tput setaf 80)     # Turquoise for IMPORTANT
COLOR_NOTE=$(tput setaf 250)         # Light Grey for NOTE
COLOR_TIP=$(tput setaf 245)          # Light-Dark Grey for TIP
COLOR_DEBUG=$(tput setaf 200)        # Hot Pink for DEBUG
COLOR_VERBOSE=$(tput setaf 245)      # Light-Dark Grey for VERBOSE
COLOR_SUCCESS=$(tput setaf 82)       # Very Bright Green for success messages
COLOR_CONFIRMATION=$(tput setaf 190) # Bright Lime for CONFIRMATION
COLOR_ALERT=$(tput setaf 214)        # Tangerine for ALERT
COLOR_CAUTION=$(tput setaf 220)      # Yellow/Amber for CAUTION
COLOR_FOCUS=$(tput setaf 33)         # Dark Blue for FOCUS
COLOR_HIGHLIGHT=$(tput setaf 201)    # Magenta for HIGHLIGHT
COLOR_NEUTRAL=$(tput setaf 244)      # Neutral Grey for NEUTRAL
COLOR_PROMPT=$(tput setaf 51)        # Cyan for PROMPT
COLOR_STATUS=$(tput setaf 163)       # Light Magenta for STATUS
COLOR_QUESTION=$(tput setaf 172)     # Bright-ish Orange/Amber for questions

# Custom Colors for Custom Log Prefixes
COLOR_CUSTOM_PREFIX_1=$(tput setaf 33) # Orange
COLOR_CUSTOM_PREFIX_2=$(tput setaf 51) # Cyan for PROMPT
COLOR_CUSTOM_PREFIX_3=$(tput setaf 35) # Purple

# Reset to default color
COLOR_RESET=$(tput sgr0)
# Color Palette Definition using `tput`
declare -A COLOR_PALETTE=(
    [BLACK]=$(tput setaf 0)
    [BOLD_BLACK]=$(tput bold)$(tput setaf 0) # or '\033[1;30m'
    [RED]=$(tput setaf 1)
    [GREEN]=$(tput setaf 2)
    [YELLOW]=$(tput setaf 3)
    [BLUE]=$(tput setaf 4)
    [PURPLE]=$(tput setaf 5)
    [CYAN]=$(tput setaf 6)
    [WHITE]=$(tput setaf 7)
    [RESET]=$(tput sgr0)
    [INFO]="$COLOR_INFO"
    [INFO_HEADER]="$COLOR_INFO_HEADER"
    [IMPORTANT]="$COLOR_IMPORTANT"
    [NOTE]="$COLOR_NOTE"
    [TIP]="$COLOR_TIP"
    [CONFIRMATION]="$COLOR_CONFIRMATION"
    [SUCCESS]="$COLOR_SUCCESS"
    [WARNING]="$COLOR_WARNING"
    [ERROR]="$COLOR_ERROR"
    [PROMPT]="$COLOR_PROMPT"
    [DEBUG]="$COLOR_DEBUG"
    [QUESTION]="$COLOR_QUESTION"
    [CAUTION]="$COLOR_CAUTION"
    [FOCUS]="$COLOR_FOCUS"
    [HIGHLIGHT]="$COLOR_HIGHLIGHT"
    [NEUTRAL]="$COLOR_NEUTRAL"
    [ALERT]="$COLOR_ALERT"
    [CUSTOM_PREFIX_1]="$COLOR_CUSTOM_PREFIX_1"
    [CUSTOM_PREFIX_2]="$COLOR_CUSTOM_PREFIX_2"
    [CUSTOM_PREFIX_3]="$COLOR_CUSTOM_PREFIX_3"
)

# Add Bold Variants to the Palette
for color in BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE; do
    COLOR_PALETTE["BOLD_$color"]="$(tput bold)${COLOR_PALETTE[$color]}"
done
# This script can be sourced in other scripts to use the defined color palette.
