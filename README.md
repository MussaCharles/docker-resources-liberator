# Docker Resources Liberator 🐳🧹

A modular bash script to find and remove Docker resources (images, containers, volumes, and networks) matching a specified search term.

## Features

- **Search & Destroy**: Find all Docker resources matching a keyword
- **Comprehensive Cleanup**: Handles images, containers, volumes, and networks
- **Resource Logging**: Logs system resources before and after cleanup
- **Dry Run Mode**: Preview what would be deleted without making changes
- **Auto-Confirm Mode**: Skip confirmation prompt for scripted/automated use
- **Detailed Logs**: Persistent log files with timestamps for auditing

## Project Structure

```
docker-resources-liberator/
├── liberate.sh     # Main script
├── logs/           # Log files directory
│   └── <search_term>_YYYYMMDD_HHMMSS.log
└── README.md       # This file
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
| `-h, --help` | Show help message |

### Examples

```bash
# Find and interactively delete resources matching 'myproject'
./liberate.sh myproject

# Preview what would be deleted (no actual deletion)
./liberate.sh myproject --dry-run

# Auto-confirm deletion (useful for scripts)
./liberate.sh myproject -y

# Combine options
./liberate.sh myproject --dry-run -y
```

## Creating Project-Specific Wrapper Scripts

You can create simple wrapper scripts for frequently cleaned projects. For example, to create a script for cleaning SOFC resources:

### Example: `~/prune_sofc_docker.sh`

```bash
#!/bin/bash
# Wrapper script to clean SOFC Docker resources

~/docker-resources-liberator/liberate.sh sofc "$@"
```

Then make it executable:
```bash
chmod +x ~/prune_sofc_docker.sh
```

Now you can simply run:
```bash
~/prune_sofc_docker.sh           # Interactive mode
~/prune_sofc_docker.sh --dry-run # Preview mode
~/prune_sofc_docker.sh -y        # Auto-confirm mode
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

Log files are automatically created in the `logs/` directory with the naming format:

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

### Example Log Location

```
~/docker-resources-liberator/logs/sofc_20241215_143022.log
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
4. **Detailed Logging**: Full audit trail of all operations
5. **Error Handling**: Reports failed deletions without stopping

## Requirements

- Bash 4.0+
- Docker CLI installed and accessible
- `sudo` access (optional, for volume size calculation)
- Standard Unix utilities: `awk`, `grep`, `sed`, `df`, `free`

## Tips

- Run with `--dry-run` first to preview what will be deleted
- Check the log files for detailed information about each run
- Use `docker system prune` after running for additional cleanup
- Create wrapper scripts for projects you clean frequently

## Troubleshooting

### "Permission denied" errors
Some volume operations may require `sudo`. The script will still work but may show "unknown" for volume sizes.

### Resources not being deleted
- Check if containers are still running (they'll be force-stopped)
- Some resources may be in use by other containers not matching the search term

### Finding the right search term
Run `docker images`, `docker ps -a`, `docker volume ls`, and `docker network ls` to see all resources and identify the correct search term.

## License

MIT License - Feel free to modify and distribute.

## Contributing

Feel free to submit issues and pull requests for improvements!