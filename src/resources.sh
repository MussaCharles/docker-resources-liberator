#!/bin/bash

# =============================================================================
# System Resource Functions Module
# =============================================================================
# Handles system resource tracking, logging initialization, and comparisons

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

    # Timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    print_line "Timestamp: ${timestamp}"

    # Disk usage for root filesystem
    print_line ""
    print_line "Disk Usage:"
    print_line "  Root filesystem (/):"
    local root_disk=$(df -h / | tail -1)
    local root_used=$(echo "$root_disk" | awk '{print $3}')
    local root_total=$(echo "$root_disk" | awk '{print $2}')
    local root_avail=$(echo "$root_disk" | awk '{print $4}')
    local root_pct=$(echo "$root_disk" | awk '{print $5}')
    print_line "    Total: ${root_total}, Used: ${root_used} (${root_pct}), Available: ${root_avail}"

    # Check if /var/lib/docker is a separate mount
    if mountpoint -q /var/lib/docker 2>/dev/null; then
        print_line "  Docker filesystem (/var/lib/docker):"
        local docker_disk=$(df -h /var/lib/docker | tail -1)
        local docker_used=$(echo "$docker_disk" | awk '{print $3}')
        local docker_total=$(echo "$docker_disk" | awk '{print $2}')
        local docker_avail=$(echo "$docker_disk" | awk '{print $4}')
        local docker_pct=$(echo "$docker_disk" | awk '{print $5}')
        print_line "    Total: ${docker_total}, Used: ${docker_used} (${docker_pct}), Available: ${docker_avail}"
    fi

    # Memory usage (platform-specific)
    print_line ""
    print_line "Memory Usage:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local mem_total=$(sysctl -n hw.memsize | awk '{printf "%.1fG", $1/1024/1024/1024}')
        local mem_used=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} END {printf "%.1fG", (active+wired)*4096/1024/1024/1024}' | tr -d '.')
        print_line "  Total: ${mem_total}, Used: ${mem_used}"
    else
        # Linux
        local mem_total=$(free -h | grep "^Mem:" | awk '{print $2}')
        local mem_used=$(free -h | grep "^Mem:" | awk '{print $3}')
        local mem_free=$(free -h | grep "^Mem:" | awk '{print $4}')
        local mem_avail=$(free -h | grep "^Mem:" | awk '{print $7}')
        print_line "  Total: ${mem_total}, Used: ${mem_used}, Free: ${mem_free}, Available: ${mem_avail}"

        # Swap usage (Linux only)
        local swap_total=$(free -h | grep "^Swap:" | awk '{print $2}')
        local swap_used=$(free -h | grep "^Swap:" | awk '{print $3}')
        if [[ "$swap_total" != "0B" && "$swap_total" != "0" ]]; then
            print_line "  Swap: Total: ${swap_total}, Used: ${swap_used}"
        fi
    fi

    # Docker system disk usage
    print_line ""
    print_line "Docker Disk Usage:"

    # Get docker system df output
    local docker_df
    docker_df=$(docker system df 2>/dev/null)

    # Parse and display docker disk usage
    echo "$docker_df" | while IFS= read -r line; do
        print_line "  $line"
    done

    # Store values for comparison (in bytes)
    if [[ "$label" == "BEFORE" ]]; then
        # Use -k for kilobytes (compatible with both macOS and Linux) and convert to bytes
        DISK_BEFORE=$(df -k / | tail -1 | awk '{print $4 * 1024}')
        DOCKER_IMAGES_BEFORE=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '1p')
        DOCKER_CONTAINERS_BEFORE=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '2p')
        DOCKER_VOLUMES_BEFORE=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '3p')
    else
        # Use -k for kilobytes (compatible with both macOS and Linux) and convert to bytes
        DISK_AFTER=$(df -k / | tail -1 | awk '{print $4 * 1024}')
        DOCKER_IMAGES_AFTER=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '1p')
        DOCKER_CONTAINERS_AFTER=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '2p')
        DOCKER_VOLUMES_AFTER=$(docker system df --format '{{.Size}}' 2>/dev/null | sed -n '3p')
    fi

    print_line ""
}

show_resource_comparison() {
    print_section "Resource Comparison (Before → After)"

    print_line "Disk Space Changes:"

    # Calculate disk space freed
    if [[ -n "$DISK_BEFORE" && -n "$DISK_AFTER" ]]; then
        local disk_freed=$((DISK_AFTER - DISK_BEFORE))

        if [[ $disk_freed -gt 0 ]]; then
            local disk_freed_human=$(numfmt --to=iec-i --suffix=B $disk_freed 2>/dev/null || echo "${disk_freed} bytes")
            print_success "Disk space freed: ${disk_freed_human}"
        elif [[ $disk_freed -lt 0 ]]; then
            local disk_used=$((-disk_freed))
            local disk_used_human=$(numfmt --to=iec-i --suffix=B $disk_used 2>/dev/null || echo "${disk_used} bytes")
            print_warning "Additional disk used: ${disk_used_human}"
        else
            print_info "No change in disk space"
        fi
    fi

    # Docker resource changes
    print_line ""
    print_line "Docker Resource Changes:"
    print_line "  Images:     ${DOCKER_IMAGES_BEFORE:-N/A} → ${DOCKER_IMAGES_AFTER:-N/A}"
    print_line "  Containers: ${DOCKER_CONTAINERS_BEFORE:-N/A} → ${DOCKER_CONTAINERS_AFTER:-N/A}"
    print_line "  Volumes:    ${DOCKER_VOLUMES_BEFORE:-N/A} → ${DOCKER_VOLUMES_AFTER:-N/A}"

    # Current Docker disk usage (detailed)
    print_line ""
    print_line "Current Docker Disk Usage:"
    local docker_df=$(docker system df 2>/dev/null)
    echo "$docker_df" | while IFS= read -r line; do
        print_line "  $line"
    done

    # Reclaimable space
    print_line ""
    print_line "Reclaimable Space:"
    docker system df | grep -v "TYPE" | while read -r type total active size reclaimable; do
        if [[ -n "$reclaimable" ]]; then
            print_line "  ${type}: ${reclaimable}"
        fi
    done
}
