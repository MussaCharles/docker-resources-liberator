# Contributing to Docker Resources Liberator

Thank you for your interest in contributing to Docker Resources Liberator! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Your environment (OS, Docker version, Bash version)
- Any relevant log output

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:

- A clear description of the feature
- The problem it solves or use case it addresses
- Any implementation ideas you have

### Submitting Changes

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the code style guidelines below
3. **Add tests** if applicable (see `tests/` directory)
4. **Run the test suite** to ensure all tests pass:
   ```bash
   cd tests && ./run_tests.sh
   ```
5. **Test manually** with `--dry-run` to verify your changes work correctly
6. **Submit a pull request** with a clear description of your changes

## Code Style Guidelines

### Bash Best Practices

- Use `[[ ]]` for conditionals instead of `[ ]`
- Quote variables to prevent word splitting: `"$variable"`
- Use lowercase for local variables, uppercase for exported/global variables
- Add comments for complex logic
- Use meaningful function and variable names

### Project Structure

- `liberate.sh` - Main entry point (keep minimal, delegate to modules)
- `src/config.sh` - Configuration and global variables
- `src/helpers.sh` - Output formatting and logging utilities
- `src/resources.sh` - System resource tracking
- `src/discovery.sh` - Docker resource discovery functions
- `src/cleanup.sh` - Docker resource cleanup functions

### Adding New Features

When adding new features:

1. Determine which module the feature belongs in
2. Follow the existing patterns in that module
3. Update `src/helpers.sh` if new output formatting is needed
4. Add corresponding tests in `tests/`
5. Update documentation (README.md, CLAUDE.md) as needed

## Testing

We use [bats-core](https://github.com/bats-core/bats-core) for testing.

### Running Tests

```bash
# Run all tests
cd tests && ./run_tests.sh

# Run specific test file
bats tests/test_helpers.bats
```

### Writing Tests

- Add tests to the appropriate file (`test_helpers.bats`, `test_discovery.bats`, `test_cleanup.bats`)
- Use descriptive test names
- Mock Docker commands using the helpers in `test_helpers.bash`
- Test both success and failure cases

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Add a clear description of your changes
4. Link any related issues
5. Wait for review and address any feedback

## Code of Conduct

Please note that this project has a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to abide by its terms.

## Questions?

If you have questions about contributing, feel free to open an issue for discussion.

Thank you for contributing!
