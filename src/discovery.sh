#!/bin/bash

# =============================================================================
# Discovery Functions Module
# =============================================================================
# Functions to find Docker resources matching the search term

find_images() {
    print_section "Docker Images containing '${SEARCH_TERM}'"

    local images=$(docker images -a --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$images" ]]; then
        print_info "No images found"
        return
    fi

    print_line "REPOSITORY:TAG                          IMAGE ID        SIZE"
    echo "$images" | while read -r line; do
        print_line "  $line"
    done

    IMAGES_COUNT=$(echo "$images" | wc -l | tr -d ' ')
    print_line ""
    print_line "  Found: ${IMAGES_COUNT} image(s)"
}

find_containers() {
    print_section "Docker Containers containing '${SEARCH_TERM}'"

    local containers=$(docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Image}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$containers" ]]; then
        print_info "No containers found"
        return
    fi

    print_line "NAME                            STATUS          IMAGE"
    echo "$containers" | while read -r line; do
        print_line "  $line"
    done

    CONTAINERS_COUNT=$(echo "$containers" | wc -l | tr -d ' ')
    print_line ""
    print_line "  Found: ${CONTAINERS_COUNT} container(s)"
}

find_volumes() {
    print_section "Docker Volumes containing '${SEARCH_TERM}'"

    local volumes=$(docker volume ls --format "{{.Name}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$volumes" ]]; then
        print_info "No volumes found"
        return
    fi

    print_line "VOLUME NAME"

    while read -r vol; do
        # Get volume size using docker system df -v (works on all platforms including Docker Desktop)
        local size=$(docker system df -v 2>/dev/null | grep "^$vol" | awk '{print $3}' || echo "")

        if [[ -z "$size" ]]; then
            size="N/A"
        fi

        print_line "  ${vol}"
        print_line "    └─ Size: ${size}"
    done <<< "$volumes"

    VOLUMES_COUNT=$(echo "$volumes" | wc -l | tr -d ' ')
    print_line ""
    print_line "  Found: ${VOLUMES_COUNT} volume(s)"
}

find_networks() {
    print_section "Docker Networks containing '${SEARCH_TERM}'"

    local networks=$(docker network ls --format "{{.ID}}\t{{.Name}}\t{{.Driver}}" | grep -i "${SEARCH_TERM}" || true)

    if [[ -z "$networks" ]]; then
        print_info "No networks found"
        return
    fi

    print_line "NETWORK ID              NAME                            DRIVER"
    echo "$networks" | while read -r line; do
        print_line "  $line"
    done

    NETWORKS_COUNT=$(echo "$networks" | wc -l | tr -d ' ')
    print_line ""
    print_line "  Found: ${NETWORKS_COUNT} network(s)"
}
