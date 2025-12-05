#!/usr/bin/env bats

# =============================================================================
# Tests for Discovery Functions (lib/discovery.sh)
# =============================================================================

# Load test helpers
load test_helpers

setup() {
    setup_test_environment
    export SEARCH_TERM="myproject"
    export LOG_FILE="${LOG_DIR}/test_discovery.log"
    touch "$LOG_FILE"
}

teardown() {
    teardown_test_environment
}

# Mock docker commands
docker() {
    case "$1 $2" in
        "images -a")
            mock_docker_images
            ;;
        "ps -a")
            mock_docker_containers
            ;;
        "volume ls")
            mock_docker_volumes
            ;;
        "volume inspect"*)
            echo '{"Mountpoint":"/var/lib/docker/volumes/myproject_data/_data"}'
            ;;
        "network ls")
            mock_docker_networks
            ;;
        *)
            command docker "$@"
            ;;
    esac
}

export -f docker
export -f mock_docker_images
export -f mock_docker_containers
export -f mock_docker_volumes
export -f mock_docker_networks

@test "find_images finds matching images" {
    run find_images
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "myproject-web"
    assert_contains "$stripped" "myproject-api"
    assert_contains "$stripped" "Found: 2 image(s)"
}

@test "find_images is case insensitive" {
    export SEARCH_TERM="MYPROJECT"
    run find_images
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "myproject-web"
}

@test "find_containers finds matching containers" {
    run find_containers
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "myproject-web-1"
    assert_contains "$stripped" "myproject-api-1"
    assert_contains "$stripped" "Found: 2 container(s)"
}

@test "find_volumes finds matching volumes" {
    run find_volumes
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "myproject_data"
    assert_contains "$stripped" "myproject_config"
    assert_contains "$stripped" "Found: 2 volume(s)"
}

@test "find_networks finds matching networks" {
    run find_networks
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "myproject_default"
    assert_contains "$stripped" "Found: 1 network(s)"
}

@test "find functions update counters" {
    find_images
    [ "$IMAGES_COUNT" -eq 2 ]

    find_containers
    [ "$CONTAINERS_COUNT" -eq 2 ]

    find_volumes
    [ "$VOLUMES_COUNT" -eq 2 ]

    find_networks
    [ "$NETWORKS_COUNT" -eq 1 ]
}

@test "find functions handle no results" {
    export SEARCH_TERM="nonexistent"

    run find_images
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "No images found"

    run find_containers
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "No containers found"
}
