#!/bin/bash

# =============================================================================
# Test Runner Script
# =============================================================================
# Runs all bats tests for the Docker Resources Liberator

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BOLD}${BLUE}Docker Resources Liberator - Test Runner${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${YELLOW}bats is not installed. Installing bats-core...${NC}\n"

    # Check if we're on macOS with Homebrew
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        echo "Installing via Homebrew..."
        brew install bats-core
    else
        echo -e "${RED}Please install bats manually:${NC}"
        echo "  - macOS: brew install bats-core"
        echo "  - Ubuntu/Debian: sudo apt-get install bats"
        echo "  - Or visit: https://github.com/bats-core/bats-core"
        exit 1
    fi
fi

echo -e "${GREEN}✓ bats is installed${NC}"
echo -e "Version: $(bats --version)\n"

# Run all test files
echo -e "${BOLD}Running tests...${NC}\n"

TEST_FILES=(
    "test_helpers.bats"
    "test_discovery.bats"
    "test_cleanup.bats"
)

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

for test_file in "${TEST_FILES[@]}"; do
    if [[ -f "$test_file" ]]; then
        echo -e "${CYAN}Running ${test_file}...${NC}"
        if bats "$test_file"; then
            echo -e "${GREEN}✓ ${test_file} passed${NC}\n"
        else
            echo -e "${RED}✗ ${test_file} failed${NC}\n"
            ((FAILED_TESTS++))
        fi
    else
        echo -e "${YELLOW}⚠ ${test_file} not found, skipping${NC}\n"
    fi
done

# Summary
echo -e "\n${BOLD}${BLUE}Test Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
