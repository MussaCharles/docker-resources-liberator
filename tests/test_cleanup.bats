#!/usr/bin/env bats

# =============================================================================
# Tests for Cleanup Functions (lib/cleanup.sh)
# =============================================================================

# Load test helpers
load test_helpers

setup() {
    setup_test_environment
    export SEARCH_TERM="myproject"
    export LOG_FILE="${LOG_DIR}/test_cleanup.log"
    export DRY_RUN=true
    touch "$LOG_FILE"
}

teardown() {
    teardown_test_environment
}

# Mock docker commands
docker() {
    case "$1 $2" in
        "ps -a")
            mock_docker_containers
            ;;
        "images -a")
            mock_docker_images
            ;;
        "volume ls")
            mock_docker_volumes
            ;;
        "network ls")
            mock_docker_networks
            ;;
        "rm -f"*)
            echo "Removed: $3"
            return 0
            ;;
        "rmi -f"*)
            echo "Removed: $3"
            return 0
            ;;
        "volume rm"*)
            echo "Removed: $3"
            return 0
            ;;
        "network rm"*)
            echo "Removed: $2"
            return 0
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

@test "cleanup_containers in dry run mode" {
    run cleanup_containers
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "[DRY RUN]"
    assert_contains "$stripped" "myproject-web-1"
    assert_contains "$stripped" "myproject-api-1"
}

@test "cleanup_images in dry run mode" {
    run cleanup_images
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "[DRY RUN]"
}

@test "cleanup_volumes in dry run mode" {
    run cleanup_volumes
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "[DRY RUN]"
    assert_contains "$stripped" "myproject_data"
}

@test "cleanup_networks in dry run mode" {
    run cleanup_networks
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "[DRY RUN]"
    assert_contains "$stripped" "myproject_default"
}

@test "cleanup functions respect DRY_RUN flag" {
    export DRY_RUN=true

    run cleanup_containers
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "[DRY RUN]"

    run cleanup_volumes
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "[DRY RUN]"
}

@test "cleanup functions log to file" {
    cleanup_containers
    grep -q "DRY RUN" "$LOG_FILE"
    grep -q "myproject" "$LOG_FILE"
}

@test "cleanup functions handle empty results" {
    export SEARCH_TERM="nonexistent"

    run cleanup_containers
    [ "$status" -eq 0 ]

    run cleanup_images
    [ "$status" -eq 0 ]
}
