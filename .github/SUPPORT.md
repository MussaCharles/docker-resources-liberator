# Support

## Getting Help

If you need help with Docker Resources Liberator, here are some resources:

### Documentation

- [**README.md**](../README.md) - Overview, installation, and usage instructions
- [**tests/README.md**](../tests/README.md) - Information about running and writing tests

### Common Issues

#### Script not found or permission denied

Make sure the script is executable:
```bash
chmod +x liberate.sh
```

#### Volume sizes showing as "N/A"

On macOS with Docker Desktop, ensure Docker is running. Volume sizes are retrieved from Docker's internal data.

#### Resources not being deleted

- Some resources may be in use by other containers
- Containers will be force-stopped before removal
- Check for typos in your search term

#### Tests failing

Ensure bats-core is installed:
```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats
```

### Getting More Help

If your issue isn't covered above:

1. **Search existing issues** - Your question may already be answered
2. **Open a new issue** - Provide as much detail as possible:
   - What you're trying to do
   - What's happening instead
   - Your environment (OS, Docker version, Bash version)
   - Any error messages or log output

### Reporting Bugs

Please report bugs by opening a GitHub issue with:
- Clear steps to reproduce
- Expected vs actual behavior
- Environment details
- Relevant log output (use `--log` flag)

### Feature Requests

Feature requests are welcome! Open an issue describing:
- The feature you'd like
- Why it would be useful
- Any implementation ideas

## Security Issues

If you discover a security vulnerability, please open a GitHub issue. For sensitive security issues, please note this in the issue and we will coordinate disclosure appropriately.
