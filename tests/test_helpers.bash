#!/bin/bash

# =============================================================================
# Test Helpers
# =============================================================================
# Shared helper functions for tests

# Setup function to load modules
setup_test_environment() {
    # Get the script directory
    export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Source all library modules
    source "${SCRIPT_DIR}/src/config.sh"
    source "${SCRIPT_DIR}/src/helpers.sh"
    source "${SCRIPT_DIR}/src/resources.sh"
    source "${SCRIPT_DIR}/src/discovery.sh"
    source "${SCRIPT_DIR}/src/cleanup.sh"

    # Set test-specific configurations
    export LOG_DIR="${SCRIPT_DIR}/tests/test_logs"
    export TIMESTAMP="test_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$LOG_DIR"
}

# Cleanup function
teardown_test_environment() {
    # Clean up test logs if they exist
    if [[ -d "${SCRIPT_DIR}/tests/test_logs" ]]; then
        rm -rf "${SCRIPT_DIR}/tests/test_logs"
    fi
}

# Mock docker commands for testing
mock_docker_images() {
    cat <<'EOF'
myproject-web:latest	abc123	100MB
myproject-api:v1.0	def456	50MB
otherproject:latest	ghi789	75MB
EOF
}

mock_docker_containers() {
    cat <<'EOF'
myproject-web-1	Up 2 hours	myproject-web:latest
myproject-api-1	Up 1 hour	myproject-api:v1.0
otherproject-db-1	Up 3 hours	postgres:14
EOF
}

mock_docker_volumes() {
    cat <<'EOF'
myproject_data
myproject_config
otherproject_data
EOF
}

mock_docker_networks() {
    cat <<'EOF'
abc123def	myproject_default	bridge
ghi789jkl	otherproject_network	bridge
mno456pqr	bridge	bridge
EOF
}

# Strip ANSI color codes from output
strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Check if a string contains a substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Expected to find '$needle' in output"
        return 1
    fi
}

# Check if a string does not contain a substring
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "Did not expect to find '$needle' in output"
        return 1
    fi
}
