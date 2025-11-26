#!/bin/bash

# =============================================================================
# Docker Resources Liberator
# =============================================================================
# A modular script to find and remove Docker resources matching a search term.
# Cleans up images, containers, volumes, and networks.
# Logs system resource usage before and after cleanup.
#
# Usage: ./liberate.sh <search_term> [options]
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# -----------------------------------------------------------------------------
# Usage & Argument Parsing
# -----------------------------------------------------------------------------

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
    echo "  -h, --help     Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $(basename "$0") sofc                # Find and delete resources matching 'sofc'"
    echo "  $(basename "$0") myproject -y       # Auto-confirm deletion"
    echo "  $(basename "$0") testing --dry-run  # Preview without deleting"
    echo ""
    exit 0
}

# Parse arguments
SEARCH_TERM=""
AUTO_CONFIRM=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo "Use --help for usage information."
            exit 1
            ;;
        *)
            if [[ -z "$SEARCH_TERM" ]]; then
                SEARCH_TERM="$1"
            else
                echo -e "${RED}Error: Multiple search terms provided. Only one is allowed.${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate search term
if [[ -z "$SEARCH_TERM" ]]; then
    echo -e "${RED}Error: No search term provided.${NC}"
    echo "Use --help for usage information."
    exit 1
fi

# Set log file with search term in name
LOG_FILE="${LOG_DIR}/${SEARCH_TERM}_${TIMESTAMP}.log"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

print_header() {
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${BOLD}${CYAN}─── $1 ───${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# System Resource Functions
# -----------------------------------------------------------------------------

init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Initialize log file
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "Docker Resources Liberator - Log File"
        echo "Search Term: ${SEARCH_TERM}"
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo "Dry Run: ${DRY_RUN}"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
    } > "$LOG_FILE"
}

get_system_resources() {
    local label="$1"
    
    print_section "System Resources - ${label}"
    log_to_file "=== System Resources - ${label} ==="
    
    # Timestamp
    echo -e "${BOLD}Timestamp:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    log_to_file "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Disk usage for root filesystem
    echo -e "\n${BOLD}Disk Usage:${NC}"
    echo -e "  Root filesystem (/):"
    local root_disk=$(df -h / | tail -1)
    local root_used=$(echo "$root_disk" | awk '{print $3}')
    local root_total=$(echo "$root_disk" | awk '{print $2}')
    local root_avail=$(echo "$root_disk" | awk '{print $4}')
    local root_pct=$(echo "$root_disk" | awk '{print $5}')
    echo -e "    Total: ${root_total}, Used: ${root_used} (${root_pct}), Available: ${root_avail}"
    log_to_file "Disk (/): Total=${root_total}, Used=${root_used} (${root_pct}), Available=${root_avail}"
    
    # Check if /var/lib/docker is a separate mount
    if mountpoint -q /var/lib/docker 2>/dev/null; then
        echo -e "  Docker filesystem (/var/lib/docker):"
        local docker_disk=$(df -h /var/lib/docker | tail -1)
        local docker_used=$(echo "$docker_disk" | awk '{print $3}')
        local docker_total=$(echo "$docker_disk" | awk '{print $2}')
        local docker_avail=$(echo "$docker_disk" | awk '{print $4}')
        local docker_pct=$(echo "$docker_disk" | awk '{print $5}')
        echo -e "    Total: ${docker_total}, Used: ${docker_used} (${docker_pct}), Available: ${docker_avail}"
        log_to_file "Disk (docker): Total=${docker_total}, Used=${docker_used} (${docker_pct}), Available=${docker_avail}"
    fi
    
    # Memory usage
    echo -e "\n${BOLD}Memory Usage:${NC}"
    local mem_total=$(free -h | grep "^Mem:" | awk '{print $2}')
    local mem_used=$(free -h | grep "^Mem:" | awk '{print $3}')
    local mem_free=$(free -h | grep "^Mem:" | awk '{print $4}')
    local mem_avail=$(free -h | grep "^Mem:" | awk '{print $7}')
    echo -e "  Total: ${mem_total}, Used: ${mem_used}, Free: ${mem_free}, Available: ${mem_avail}"
    log_to_file "Memory: Total=${mem_total}, Used=${mem_used}, Free=${mem_free}, Available=${mem_avail}"
    
    # Swap usage
    local swap_total=$(free -h | grep "^Swap:" | awk '{print $2}')
    local swap_used=$(free -h | grep "^Swap:" | awk '{print $3}')
    if [[ "$swap_total" != "0B" && "$swap_total" != "0" ]]; then
        echo -e "  Swap: Total: ${swap_total}, Used: ${swap_used}"
        log_to_file "Swap: Total=${swap_total}, Used=${swap_used}"
    fi
    
    # Docker system disk usage
    echo -e "\n${BOLD}Docker Disk Usage:${NC}"
    log_to_file "Docker system df:"
    
    # Get docker system df output
    local docker_df
    docker_df=$(docker system df 2>/dev/null)
    
    # Parse and display docker disk usage
    echo "$docker_df" | while IFS= read -r line; do
        echo -e "  $line"
    done
    echo "$docker_df" >> "$LOG_FILE"
    
    # Store values for comparison (in bytes)
    if [[ "$label" == "BEFORE" ]]; then
        DISK_BEFORE=$(df -B1 / | tail -1 | awk '{print $4}')
        DOCKER_IMAGES_BEFORE=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '1p')
        DOCKER_CONTAINERS_BEFORE=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '2p')
        DOCKER_VOLUMES_BEFORE=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '3p')
    else
        DISK_AFTER=$(df -B1 / | tail -1 | awk '{print $4}')
        DOCKER_IMAGES_AFTER=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '1p')
        DOCKER_CONTAINERS_AFTER=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '2p')
        DOCKER_VOLUMES_AFTER=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '3p')
    fi
    
    echo ""
    log_to_file ""
}

show_resource_comparison() {
    print_section "Resource Comparison (Before → After)"
    log_to_file "=== Resource Comparison ==="
    
    echo -e "${BOLD}Disk Space Changes:${NC}"
    
    # Calculate disk space freed
    if [[ -n "$DISK_BEFORE" && -n "$DISK_AFTER" ]]; then
        local disk_freed=$((DISK_AFTER - DISK_BEFORE))
        
        if [[ $disk_freed -gt 0 ]]; then
            local disk_freed_human=$(numfmt --to=iec-i --suffix=B $disk_freed 2>/dev/null || echo "${disk_freed} bytes")
            echo -e "  ${GREEN}✓ Disk space freed: ${disk_freed_human}${NC}"
            log_to_file "Disk space freed: ${disk_freed_human}"
        elif [[ $disk_freed -lt 0 ]]; then
            local disk_used=$((-disk_freed))
            local disk_used_human=$(numfmt --to=iec-i --suffix=B $disk_used 2>/dev/null || echo "${disk_used} bytes")
            echo -e "  ${YELLOW}↑ Additional disk used: ${disk_used_human}${NC}"
            log_to_file "Additional disk used: ${disk_used_human}"
        else
            echo -e "  ${BLUE}→ No change in disk space${NC}"
            log_to_file "Disk space: No change"
        fi
    fi
    
    # Docker resource changes
    echo -e "\n${BOLD}Docker Resource Changes:${NC}"
    echo -e "  Images:     ${DOCKER_IMAGES_BEFORE:-N/A} → ${DOCKER_IMAGES_AFTER:-N/A}"
    echo -e "  Containers: ${DOCKER_CONTAINERS_BEFORE:-N/A} → ${DOCKER_CONTAINERS_AFTER:-N/A}"
    echo -e "  Volumes:    ${DOCKER_VOLUMES_BEFORE:-N/A} → ${DOCKER_VOLUMES_AFTER:-N/A}"
    
    log_to_file "Docker Images: ${DOCKER_IMAGES_BEFORE:-N/A} → ${DOCKER_IMAGES_AFTER:-N/A}"
    log_to_file "Docker Containers: ${DOCKER_CONTAINERS_BEFORE:-N/A} → ${DOCKER_CONTAINERS_AFTER:-N/A}"
    log_to_file "Docker Volumes: ${DOCKER_VOLUMES_BEFORE:-N/A} → ${DOCKER_VOLUMES_AFTER:-N/A}"
    
    # Current Docker disk usage (detailed)
    echo -e "\n${BOLD}Current Docker Disk Usage:${NC}"
    docker system df
    
    # Reclaimable space
    echo -e "\n${BOLD}Reclaimable Space:${NC}"
    docker system df | grep -v "TYPE" | while read -r type total active size reclaimable; do
        if [[ -n "$reclaimable" ]]; then
            echo -e "  ${type}: ${reclaimable}"
        fi
    done
}

# -----------------------------------------------------------------------------
# Discovery Functions
# -----------------------------------------------------------------------------

find_images() {
    print_section "Docker Images containing '${SEARCH_TERM}'"
    
    local images=$(docker images -a --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$images" ]]; then
        print_info "No images found"
        return
    fi
    
    echo -e "${BOLD}REPOSITORY:TAG\t\t\t\tIMAGE ID\tSIZE${NC}"
    echo "$images" | while read -r line; do
        echo -e "  $line"
    done
    
    IMAGES_COUNT=$(echo "$images" | wc -l | tr -d ' ')
    echo -e "\n  ${YELLOW}Found: ${IMAGES_COUNT} image(s)${NC}"
    log_to_file "Found ${IMAGES_COUNT} image(s) matching '${SEARCH_TERM}'"
}

find_containers() {
    print_section "Docker Containers containing '${SEARCH_TERM}'"
    
    local containers=$(docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Image}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$containers" ]]; then
        print_info "No containers found"
        return
    fi
    
    echo -e "${BOLD}NAME\t\t\t\tSTATUS\t\tIMAGE${NC}"
    echo "$containers" | while read -r line; do
        echo -e "  $line"
    done
    
    CONTAINERS_COUNT=$(echo "$containers" | wc -l | tr -d ' ')
    echo -e "\n  ${YELLOW}Found: ${CONTAINERS_COUNT} container(s)${NC}"
    log_to_file "Found ${CONTAINERS_COUNT} container(s) matching '${SEARCH_TERM}'"
}

find_volumes() {
    print_section "Docker Volumes containing '${SEARCH_TERM}'"
    
    local volumes=$(docker volume ls --format "{{.Name}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$volumes" ]]; then
        print_info "No volumes found"
        return
    fi
    
    echo -e "${BOLD}VOLUME NAME${NC}"
    
    while read -r vol; do
        # Get volume details
        local mountpoint=$(docker volume inspect "$vol" --format '{{.Mountpoint}}' 2>/dev/null || echo "N/A")
        
        # Try to get size (may require sudo)
        local size="unknown"
        if [[ -d "$mountpoint" ]]; then
            size=$(sudo du -sh "$mountpoint" 2>/dev/null | cut -f1 || echo "unknown")
        fi
        
        echo -e "  ${vol}"
        echo -e "    └─ Size: ${size}, Path: ${mountpoint}"
    done <<< "$volumes"
    
    VOLUMES_COUNT=$(echo "$volumes" | wc -l | tr -d ' ')
    echo -e "\n  ${YELLOW}Found: ${VOLUMES_COUNT} volume(s)${NC}"
    log_to_file "Found ${VOLUMES_COUNT} volume(s) matching '${SEARCH_TERM}'"
}

find_networks() {
    print_section "Docker Networks containing '${SEARCH_TERM}'"
    
    local networks=$(docker network ls --format "{{.ID}}\t{{.Name}}\t{{.Driver}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$networks" ]]; then
        print_info "No networks found"
        return
    fi
    
    echo -e "${BOLD}NETWORK ID\t\tNAME\t\t\t\t\tDRIVER${NC}"
    echo "$networks" | while read -r line; do
        echo -e "  $line"
    done
    
    NETWORKS_COUNT=$(echo "$networks" | wc -l | tr -d ' ')
    echo -e "\n  ${YELLOW}Found: ${NETWORKS_COUNT} network(s)${NC}"
    log_to_file "Found ${NETWORKS_COUNT} network(s) matching '${SEARCH_TERM}'"
}

# -----------------------------------------------------------------------------
# Cleanup Functions
# -----------------------------------------------------------------------------

cleanup_containers() {
    local containers=$(docker ps -a --format "{{.Names}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$containers" ]]; then
        return
    fi
    
    echo -e "\n${CYAN}Removing containers...${NC}"
    while read -r container; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove container: $container"
            log_to_file "[DRY RUN] Would remove container: $container"
        else
            if docker rm -f "$container" >/dev/null 2>&1; then
                print_success "Removed container: $container"
                log_to_file "Removed container: $container"
            else
                print_error "Failed to remove container: $container"
                log_to_file "FAILED to remove container: $container"
            fi
        fi
    done <<< "$containers"
}

cleanup_images() {
    local images=$(docker images -a --format "{{.ID}}" --filter "reference=*${SEARCH_TERM}*" || true)
    
    # Also get images by grepping
    local images_grep=$(docker images -a --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -i "${SEARCH_TERM}" | awk '{print $2}' || true)
    
    local all_images=$(echo -e "${images}\n${images_grep}" | sort -u | grep -v '^$' || true)
    
    if [[ -z "$all_images" ]]; then
        return
    fi
    
    echo -e "\n${CYAN}Removing images...${NC}"
    while read -r image; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove image: $image"
            log_to_file "[DRY RUN] Would remove image: $image"
        else
            if docker rmi -f "$image" >/dev/null 2>&1; then
                print_success "Removed image: $image"
                log_to_file "Removed image: $image"
            else
                print_error "Failed to remove image: $image"
                log_to_file "FAILED to remove image: $image"
            fi
        fi
    done <<< "$all_images"
}

cleanup_volumes() {
    local volumes=$(docker volume ls --format "{{.Name}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$volumes" ]]; then
        return
    fi
    
    echo -e "\n${CYAN}Removing volumes...${NC}"
    while read -r volume; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove volume: $volume"
            log_to_file "[DRY RUN] Would remove volume: $volume"
        else
            if docker volume rm -f "$volume" >/dev/null 2>&1; then
                print_success "Removed volume: $volume"
                log_to_file "Removed volume: $volume"
            else
                print_error "Failed to remove volume: $volume"
                log_to_file "FAILED to remove volume: $volume"
            fi
        fi
    done <<< "$volumes"
}

cleanup_networks() {
    local networks=$(docker network ls --format "{{.Name}}" | grep -i "${SEARCH_TERM}" || true)
    
    if [[ -z "$networks" ]]; then
        return
    fi
    
    echo -e "\n${CYAN}Removing networks...${NC}"
    while read -r network; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove network: $network"
            log_to_file "[DRY RUN] Would remove network: $network"
        else
            if docker network rm "$network" >/dev/null 2>&1; then
                print_success "Removed network: $network"
                log_to_file "Removed network: $network"
            else
                print_error "Failed to remove network: $network"
                log_to_file "FAILED to remove network: $network"
            fi
        fi
    done <<< "$networks"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    print_header "Docker Resources Liberator"
    
    echo -e "${BOLD}Search Term:${NC} ${MAGENTA}${SEARCH_TERM}${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BOLD}Mode:${NC} ${YELLOW}DRY RUN (no changes will be made)${NC}"
    fi
    
    # Initialize logging
    init_logging
    print_info "Log file: ${LOG_FILE}"
    
    # Get system resources BEFORE
    get_system_resources "BEFORE"
    
    echo -e "${BOLD}Searching for Docker resources containing '${SEARCH_TERM}'...${NC}"
    
    # Find all resources
    find_images
    find_containers
    find_volumes
    find_networks
    
    # Calculate totals
    local total=$((IMAGES_COUNT + CONTAINERS_COUNT + VOLUMES_COUNT + NETWORKS_COUNT))
    
    # Summary
    print_section "Summary"
    echo -e "  Images:     ${YELLOW}${IMAGES_COUNT}${NC}"
    echo -e "  Containers: ${YELLOW}${CONTAINERS_COUNT}${NC}"
    echo -e "  Volumes:    ${YELLOW}${VOLUMES_COUNT}${NC}"
    echo -e "  Networks:   ${YELLOW}${NETWORKS_COUNT}${NC}"
    echo -e "  ─────────────────────"
    echo -e "  ${BOLD}Total:      ${RED}${total}${NC} ${BOLD}resource(s)${NC}"
    
    log_to_file "Summary: ${IMAGES_COUNT} images, ${CONTAINERS_COUNT} containers, ${VOLUMES_COUNT} volumes, ${NETWORKS_COUNT} networks"
    log_to_file "Total resources to clean: ${total}"
    
    # Exit if nothing found
    if [[ $total -eq 0 ]]; then
        echo -e "\n${GREEN}No Docker resources found matching '${SEARCH_TERM}'. Nothing to clean up!${NC}\n"
        log_to_file "No resources found. Exiting."
        exit 0
    fi
    
    # Confirmation prompt (unless auto-confirm or dry-run)
    if [[ "$AUTO_CONFIRM" != true && "$DRY_RUN" != true ]]; then
        echo ""
        print_warning "This action is IRREVERSIBLE! All data in these resources will be permanently deleted."
        echo ""
        read -p "$(echo -e ${BOLD}${RED}"Do you want to DELETE all ${total} resource(s)? [y/N]: "${NC})" confirm
        
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "\n${YELLOW}Aborted. No resources were deleted.${NC}\n"
            log_to_file "User aborted cleanup."
            exit 0
        fi
    elif [[ "$DRY_RUN" == true ]]; then
        echo -e "\n${YELLOW}DRY RUN: Showing what would be deleted...${NC}"
    else
        echo -e "\n${YELLOW}Auto-confirm enabled. Proceeding with deletion...${NC}"
    fi
    
    log_to_file "Starting cleanup (dry_run=${DRY_RUN})..."
    
    # Perform cleanup (order matters: containers first, then images, volumes, networks)
    print_header "Cleaning Up Resources"
    
    cleanup_containers
    cleanup_images
    cleanup_volumes
    cleanup_networks
    
    # Get system resources AFTER (skip for dry run)
    if [[ "$DRY_RUN" != true ]]; then
        get_system_resources "AFTER"
        show_resource_comparison
    fi
    
    # Final summary
    print_header "Cleanup Complete"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN completed. No resources were actually deleted."
        echo -e "\n${CYAN}Run without --dry-run to perform actual cleanup.${NC}"
    else
        print_success "All Docker resources matching '${SEARCH_TERM}' have been removed!"
        echo -e "\n${CYAN}Tips:${NC}"
        echo -e "  • Run 'docker system prune' to clean up any remaining unused resources"
        echo -e "  • Run 'docker system prune -a --volumes' for a more aggressive cleanup"
    fi
    
    echo -e "\n${MAGENTA}Log file saved to: ${LOG_FILE}${NC}\n"
    
    log_to_file "Cleanup completed successfully."
    log_to_file "═══════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"