# Docker Resources Liberator 🐳🧹

A modular bash script to find and remove Docker resources (images, containers, volumes, and networks) matching a specified search term.

## Features

- **Search & Destroy**: Find all Docker resources matching a keyword
- **Comprehensive Cleanup**: Handles images, containers, volumes, and networks
- **Dry Run Mode**: Preview what would be deleted without making changes
- **Auto-Confirm Mode**: Skip confirmation prompt for scripted/automated use
- **Optional Logging**: Save detailed log files for auditing when needed

## Project Structure

```
docker-resources-liberator/
├── liberate.sh           # Main entry point
├── src/                  # Modular source files
│   ├── config.sh         # Configuration & global variables
│   ├── helpers.sh        # Output formatting & logging
│   ├── resources.sh      # System resource tracking
│   ├── discovery.sh      # Docker resource discovery
│   └── cleanup.sh        # Docker resource cleanup
├── tests/                # Unit tests (bats)
├── logs/                 # Log files (when --log is used)
└── README.md             # This file
```

## Installation

1. Clone or copy the project to your desired location:
   ```bash
   git clone https://github.com/MussaCharles/docker-resources-liberator.git
   ```

2. Make the script executable:
   ```bash
   chmod +x ~/docker-resources-liberator/liberate.sh
   ```

## Usage

### Basic Usage

```bash
./liberate.sh <search_term> [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-y, --yes` | Skip confirmation prompt (auto-confirm deletion) |
| `-d, --dry-run` | Show what would be deleted without actually deleting |
| `-l, --log` | Save output to a log file in logs/ directory |
| `-h, --help` | Show help message |

### Examples

```bash
# Find and interactively delete resources matching 'myproject'
./liberate.sh myproject

# Preview what would be deleted (no actual deletion)
./liberate.sh myproject --dry-run

# Auto-confirm deletion (useful for scripts)
./liberate.sh myproject -y

# Save a log file for auditing
./liberate.sh myproject --log

# Combine options
./liberate.sh myproject --dry-run -y --log
```

## What Gets Cleaned

The script searches for and removes:

| Resource Type | Search Method |
|---------------|---------------|
| **Images** | Repository name or tag containing the search term |
| **Containers** | Container name containing the search term |
| **Volumes** | Volume name containing the search term |
| **Networks** | Network name containing the search term |

### Cleanup Order

Resources are removed in a specific order to handle dependencies:

1. **Containers** (first, as they may depend on images/volumes/networks)
2. **Images** (after containers that use them are removed)
3. **Volumes** (after containers that mount them are removed)
4. **Networks** (after containers that use them are removed)

## Log Files

Logging is **disabled by default**. Use `-l` or `--log` to enable it.

When enabled, log files are created in the `logs/` directory with the naming format:

```
<search_term>_YYYYMMDD_HHMMSS.log
```

### Log Contents

- Timestamp and host information
- System resources before cleanup (disk, memory, Docker usage)
- List of resources found
- Deletion results (success/failure for each resource)
- System resources after cleanup
- Resource comparison (space freed)

### Example

```bash
./liberate.sh myproject --log
# Creates: ~/docker-resources-liberator/logs/myproject_20241215_143022.log
```

## System Resources Tracked

### Before & After Comparison

- **Disk Usage**: Root filesystem and Docker filesystem (if separate)
- **Memory Usage**: Total, used, free, available RAM
- **Docker Usage**: Images, containers, volumes size breakdown
- **Space Freed**: Calculated difference after cleanup

## Safety Features

1. **Confirmation Prompt**: By default, requires explicit `y` confirmation
2. **Dry Run Mode**: Test what would happen without making changes
3. **Case-Insensitive Search**: Catches variations in naming
4. **Optional Logging**: Enable audit trail when needed with `--log`
5. **Error Handling**: Reports failed deletions without stopping

## Requirements

- Bash 4.0+
- Docker CLI installed and accessible
- Standard Unix utilities: `awk`, `grep`, `sed`, `df`
- Works on both macOS and Linux

## Tips

- Run with `--dry-run` first to preview what will be deleted
- Use `--log` when you need an audit trail
- Use `docker system prune` after running for additional cleanup
- Create wrapper scripts for projects you clean frequently

## Troubleshooting

### Volume sizes not showing
On macOS with Docker Desktop, volume sizes are retrieved from Docker's internal data. If sizes show as "N/A", ensure Docker is running.

### Resources not being deleted
- Check if containers are still running (they'll be force-stopped)
- Some resources may be in use by other containers not matching the search term

### Finding the right search term
Run `docker images`, `docker ps -a`, `docker volume ls`, and `docker network ls` to see all resources and identify the correct search term.

## License

MIT License - Feel free to modify and distribute.

## Contributing

Feel free to submit issues and pull requests for improvements!