#!/bin/bash

# =============================================================================
# Helper Functions Module
# =============================================================================
# Provides formatting and logging utilities

# Core logging function - appends to log file without timestamp
log_to_file() {
    if [[ "$ENABLE_LOG" == true && -n "$LOG_FILE" ]]; then
        # Ensure log directory exists
        mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
        echo "$1" >> "$LOG_FILE"
    fi
}

# Log with timestamp prefix
log_with_timestamp() {
    if [[ "$ENABLE_LOG" == true && -n "$LOG_FILE" ]]; then
        # Ensure log directory exists
        mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

print_header() {
    local line="═══════════════════════════════════════════════════════════════"
    echo -e "\n${BOLD}${BLUE}${line}${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}${line}${NC}\n"
    log_to_file ""
    log_to_file "$line"
    log_to_file "  $1"
    log_to_file "$line"
    log_to_file ""
}

print_section() {
    echo -e "\n${BOLD}${CYAN}─── $1 ───${NC}\n"
    log_to_file ""
    log_to_file "─── $1 ───"
    log_to_file ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log_to_file "✓ $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log_to_file "⚠ $1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log_to_file "✗ $1"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log_to_file "ℹ $1"
}

# Print and log a plain line (no formatting)
print_line() {
    echo -e "$1"
    log_to_file "$1"
}

usage() {
    echo -e "${BOLD}Docker Resources Liberator${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  $(basename "$0") <search_term> [options]"
    echo ""
    echo -e "${BOLD}Arguments:${NC}"
    echo "  search_term    The keyword to search for in Docker resource names"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -y, --yes      Skip confirmation prompt (auto-confirm deletion)"
    echo "  -d, --dry-run  Show what would be deleted without actually deleting"
    echo "  -l, --log      Save output to a log file in logs/ directory"
    echo "  -h, --help     Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $(basename "$0") myproject              # Find and delete resources matching 'myproject'"
    echo "  $(basename "$0") myproject -y           # Auto-confirm deletion"
    echo "  $(basename "$0") myproject --dry-run    # Preview without deleting"
    echo "  $(basename "$0") myproject --log        # Save log file for auditing"
    echo ""
    exit 0
}
