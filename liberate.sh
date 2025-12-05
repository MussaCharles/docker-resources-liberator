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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library modules
source "${SCRIPT_DIR}/src/config.sh"
source "${SCRIPT_DIR}/src/helpers.sh"
source "${SCRIPT_DIR}/src/resources.sh"
source "${SCRIPT_DIR}/src/discovery.sh"
source "${SCRIPT_DIR}/src/cleanup.sh"

# -----------------------------------------------------------------------------
# Argument Parsing
# -----------------------------------------------------------------------------

# Parse arguments
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
        -l|--log)
            ENABLE_LOG=true
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

# Set log file with search term in name (only if logging enabled)
if [[ "$ENABLE_LOG" == true ]]; then
    LOG_FILE="${LOG_DIR}/${SEARCH_TERM}_${TIMESTAMP}.log"
fi

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    print_header "Docker Resources Liberator"

    print_line "Search Term: ${SEARCH_TERM}"

    if [[ "$DRY_RUN" == true ]]; then
        print_line "Mode: DRY RUN (no changes will be made)"
    fi

    # Initialize logging (only if enabled)
    if [[ "$ENABLE_LOG" == true ]]; then
        init_logging
        print_info "Log file: ${LOG_FILE}"
    fi

    # Get system resources BEFORE
    get_system_resources "BEFORE"

    print_line "Searching for Docker resources containing '${SEARCH_TERM}'..."

    # Find all resources
    find_images
    find_containers
    find_volumes
    find_networks

    # Calculate totals
    local total=$((IMAGES_COUNT + CONTAINERS_COUNT + VOLUMES_COUNT + NETWORKS_COUNT))

    # Summary
    print_section "Summary"
    print_line "  Images:     ${IMAGES_COUNT}"
    print_line "  Containers: ${CONTAINERS_COUNT}"
    print_line "  Volumes:    ${VOLUMES_COUNT}"
    print_line "  Networks:   ${NETWORKS_COUNT}"
    print_line "  ─────────────────────"
    print_line "  Total:      ${total} resource(s)"

    # Exit if nothing found
    if [[ $total -eq 0 ]]; then
        print_success "No Docker resources found matching '${SEARCH_TERM}'. Nothing to clean up!"
        print_line ""
        exit 0
    fi

    # Confirmation prompt (unless auto-confirm or dry-run)
    if [[ "$AUTO_CONFIRM" != true && "$DRY_RUN" != true ]]; then
        print_line ""
        print_warning "This action is IRREVERSIBLE! All data in these resources will be permanently deleted."
        print_line ""
        read -p "$(echo -e ${BOLD}${RED}"Do you want to DELETE all ${total} resource(s)? [y/N]: "${NC})" confirm

        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            print_warning "Aborted. No resources were deleted."
            print_line ""
            exit 0
        fi
        log_to_file "User confirmed deletion."
    elif [[ "$DRY_RUN" == true ]]; then
        print_line ""
        print_info "DRY RUN: Showing what would be deleted..."
    else
        print_line ""
        print_info "Auto-confirm enabled. Proceeding with deletion..."
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
        print_line ""
        print_line "Run without --dry-run to perform actual cleanup."
    else
        print_success "All Docker resources matching '${SEARCH_TERM}' have been removed!"
        print_line ""
        print_line "Tips:"
        print_line "  • Run 'docker system prune' to clean up any remaining unused resources"
        print_line "  • Run 'docker system prune -a --volumes' for a more aggressive cleanup"
    fi

    if [[ "$ENABLE_LOG" == true ]]; then
        print_line ""
        print_info "Log file saved to: ${LOG_FILE}"
        log_to_file ""
        log_to_file "═══════════════════════════════════════════════════════════════"
    fi
    print_line ""
}

# Run main function
main "$@"
