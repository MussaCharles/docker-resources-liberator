# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Resources Liberator is a standalone bash script that searches for and removes Docker resources (images, containers, volumes, and networks) matching a specified search term. It provides detailed logging, dry-run capabilities, and resource usage tracking.

## Script Execution

**Main script**: `./liberate.sh <search_term> [options]`

**Available options**:
- `-y, --yes` - Skip confirmation prompt (auto-confirm deletion)
- `-d, --dry-run` - Preview what would be deleted without making changes
- `-l, --log` - Save output to a log file in logs/ directory
- `-h, --help` - Show help message

**Examples**:
```bash
./liberate.sh myproject              # Interactive cleanup
./liberate.sh myproject --dry-run    # Preview mode
./liberate.sh myproject -y           # Auto-confirm mode
./liberate.sh myproject --log        # Save log file for auditing
```

## Architecture

The codebase is organized into a modular structure with separate library files:

```
docker-resources-liberator/
├── liberate.sh           # Main entry point (argument parsing & orchestration)
├── src/                  # Modular source files
│   ├── config.sh         # Configuration & global variables
│   ├── helpers.sh        # Output formatting & logging helpers
│   ├── resources.sh      # System resource tracking functions
│   ├── discovery.sh      # Docker resource discovery functions
│   └── cleanup.sh        # Docker resource cleanup functions
├── tests/                # Unit tests using bats
│   ├── test_helpers.bash # Shared test utilities
│   ├── test_helpers.bats # Tests for helper functions
│   ├── test_discovery.bats # Tests for discovery functions
│   ├── test_cleanup.bats # Tests for cleanup functions
│   └── run_tests.sh      # Test runner script
└── logs/                 # Generated log files
```

### Module Breakdown

#### 1. **src/config.sh** - Configuration & Global Variables
- Color definitions for terminal output (`RED`, `GREEN`, `YELLOW`, etc.)
- Script directory and log file path configuration
- Global counters (`IMAGES_COUNT`, `CONTAINERS_COUNT`, etc.)
- Resource tracking variables for before/after comparison
- Command-line argument variables (`SEARCH_TERM`, `AUTO_CONFIRM`, `DRY_RUN`)

#### 2. **src/helpers.sh** - Output Formatting & Logging
- `print_header()`, `print_section()` - Formatted headers and sections
- `print_success()`, `print_warning()`, `print_error()`, `print_info()` - Status messages with icons
- `log_to_file()` - Timestamps and appends messages to log file
- `usage()` - Displays help message

#### 3. **src/resources.sh** - System Resource Tracking
- `init_logging()` - Creates log directory and initializes log file with metadata
- `get_system_resources(label)` - Captures disk, memory, swap, and Docker resource usage; called with "BEFORE" and "AFTER" labels
- `show_resource_comparison()` - Calculates and displays space freed and resource changes

#### 4. **src/discovery.sh** - Docker Resource Discovery
- `find_images()` - Case-insensitive grep on repository/tag names
- `find_containers()` - Case-insensitive grep on container names
- `find_volumes()` - Case-insensitive grep on volume names; attempts to calculate size
- `find_networks()` - Case-insensitive grep on network names
- Each function updates global counters (`IMAGES_COUNT`, etc.)

#### 5. **src/cleanup.sh** - Docker Resource Cleanup
- `cleanup_containers()` - Uses `docker rm -f` to force-remove containers
- `cleanup_images()` - Uses `docker rmi -f` to force-remove images; searches by filter and grep
- `cleanup_volumes()` - Uses `docker volume rm -f` to remove volumes
- `cleanup_networks()` - Uses `docker network rm` to remove networks
- Cleanup order is critical: containers → images → volumes → networks (to handle dependencies)
- All functions respect the `DRY_RUN` flag

#### 6. **liberate.sh** - Main Entry Point
- Sources all modules from `src/`
- Parses command-line arguments (`-y`, `-d`, `-h`)
- Validates that exactly one search term is provided
- Orchestrates the workflow via `main()` function:
  1. Initialize logging
  2. Capture "BEFORE" system resources
  3. Discover all matching Docker resources
  4. Display summary and request confirmation (unless auto-confirm or dry-run)
  5. Execute cleanup functions in dependency order
  6. Capture "AFTER" system resources and show comparison
  7. Display completion message and log file location

## Important Implementation Details

### Resource Cleanup Order
The cleanup order is critical to avoid dependency errors:
1. **Containers first** - They may depend on images, volumes, and networks
2. **Images second** - After containers using them are removed
3. **Volumes third** - After containers mounting them are removed
4. **Networks last** - After containers using them are removed

### Search Method
All searches are case-insensitive (`grep -i`) and match partial strings. For images, the script uses both `docker images --filter` and grep to ensure comprehensive matching.

### Dry Run Mode
When `--dry-run` is enabled:
- All discovery functions run normally
- Cleanup functions only log what would be deleted (no actual deletion)
- System resource comparison is skipped (no "AFTER" snapshot taken)

### Logging
Logging is **disabled by default**. Use `-l` or `--log` to enable it.

When enabled, log files are stored in `logs/` directory with the format: `<search_term>_YYYYMMDD_HHMMSS.log`

Each log includes:
- Execution metadata (timestamp, host, user, search term, dry run flag)
- System resources before and after cleanup
- List of found resources
- Success/failure status for each deletion operation
- Resource comparison and space freed calculation

## Testing

### Running Tests

The project includes unit tests using the [bats-core](https://github.com/bats-core/bats-core) testing framework:

```bash
# Run all tests
cd tests && ./run_tests.sh

# Run specific test file
bats tests/test_helpers.bats
bats tests/test_discovery.bats
bats tests/test_cleanup.bats
```

### Test Structure

- **tests/test_helpers.bash** - Shared test utilities (setup, teardown, mocking, assertions)
- **tests/test_helpers.bats** - Tests for output formatting and logging functions
- **tests/test_discovery.bats** - Tests for Docker resource discovery functions
- **tests/test_cleanup.bats** - Tests for cleanup functions (uses mocked Docker commands)

### Installing bats

If bats is not installed:
- **macOS**: `brew install bats-core`
- **Ubuntu/Debian**: `sudo apt-get install bats`
- **Manual**: See https://github.com/bats-core/bats-core

### Testing Best Practices

When making changes:
1. **Run unit tests** - Execute `tests/run_tests.sh` to verify all tests pass
2. **Test with `--dry-run` first** - Verify search results without making changes
3. **Use a safe test search term** - Match resources you can afford to delete
4. **Verify log file creation** - Check the `logs/` directory
5. **Test error handling** - Attempt to delete resources that don't exist or are in use
6. **Test all flag combinations**: no flags, `-y`, `-d`, `-y -d`
7. **Add new tests** - When adding features, create corresponding test cases

## Common Wrapper Pattern

Users often create wrapper scripts for frequently cleaned projects:

```bash
#!/bin/bash
~/docker-resources-liberator/liberate.sh <project_name> "$@"
```

This allows passing through all flags while fixing the search term.
