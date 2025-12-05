#!/bin/bash

# =============================================================================
# Configuration Module
# =============================================================================
# Defines colors, global variables, and configuration settings

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script directory and log file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Counters
IMAGES_COUNT=0
CONTAINERS_COUNT=0
VOLUMES_COUNT=0
NETWORKS_COUNT=0

# Resource tracking variables
DISK_BEFORE=""
DISK_AFTER=""
DOCKER_IMAGES_BEFORE=""
DOCKER_IMAGES_AFTER=""
DOCKER_CONTAINERS_BEFORE=""
DOCKER_CONTAINERS_AFTER=""
DOCKER_VOLUMES_BEFORE=""
DOCKER_VOLUMES_AFTER=""

# Arguments
SEARCH_TERM=""
AUTO_CONFIRM=false
DRY_RUN=false
ENABLE_LOG=false
LOG_FILE=""
