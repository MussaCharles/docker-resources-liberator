#!/bin/bash

# =============================================================================
# Cleanup Functions Module
# =============================================================================
# Functions to remove Docker resources matching the search term

cleanup_containers() {
    local containers=$(docker ps -a --format "{{.Names}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$containers" ]]; then
        return
    fi

    print_line ""
    print_line "Removing containers..."
    while read -r container; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove container: $container"
        else
            if docker rm -f "$container" >/dev/null 2>&1; then
                print_success "Removed container: $container"
            else
                print_error "Failed to remove container: $container"
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

    print_line ""
    print_line "Removing images..."
    while read -r image; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove image: $image"
        else
            if docker rmi -f "$image" >/dev/null 2>&1; then
                print_success "Removed image: $image"
            else
                print_error "Failed to remove image: $image"
            fi
        fi
    done <<< "$all_images"
}

cleanup_volumes() {
    local volumes=$(docker volume ls --format "{{.Name}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$volumes" ]]; then
        return
    fi

    print_line ""
    print_line "Removing volumes..."
    while read -r volume; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove volume: $volume"
        else
            if docker volume rm -f "$volume" >/dev/null 2>&1; then
                print_success "Removed volume: $volume"
            else
                print_error "Failed to remove volume: $volume"
            fi
        fi
    done <<< "$volumes"
}

cleanup_networks() {
    local networks=$(docker network ls --format "{{.Name}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$networks" ]]; then
        return
    fi

    print_line ""
    print_line "Removing networks..."
    while read -r network; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would remove network: $network"
        else
            if docker network rm "$network" >/dev/null 2>&1; then
                print_success "Removed network: $network"
            else
                print_error "Failed to remove network: $network"
            fi
        fi
    done <<< "$networks"
}
