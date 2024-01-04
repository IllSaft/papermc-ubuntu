#!/bin/bash

# Initial Setup Script
echo "Configuring the Bash Skeleton environment..."

# Base Directory of the Setup Script
BASE_DIR="$(dirname "$0")"

# Setting executable permissions for the script components
chmod +x "$BASE_DIR/main.sh"
chmod +x "$BASE_DIR/lib/"*
chmod +x "$BASE_DIR/config/palette.sh"

echo "Setup completed successfully. Run ./main.sh to get started."
