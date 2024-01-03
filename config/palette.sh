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

# Color Palette Definition using `tput`
declare -A COLOR_PALETTE=(
    [BLACK]=$(tput setaf 0)
    [BOLD_BLACK]=$(tput bold)$(tput setaf 0)   # or '\033[1;30m'
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
)

# Add Bold Variants to the Palette
for color in BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE; do
    COLOR_PALETTE["BOLD_$color"]="$(tput bold)${COLOR_PALETTE[$color]}"
done
# This script can be sourced in other scripts to use the defined color palette.
