# Tests

Unit tests for Docker Resources Liberator using the [bats-core](https://github.com/bats-core/bats-core) testing framework.

## Quick Start

```bash
# Install bats (if not already installed)
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Run all tests
cd tests && ./run_tests.sh

# Run specific test file
bats test_helpers.bats
bats test_discovery.bats
bats test_cleanup.bats
```

## Test Files

### test_helpers.bash
Shared test utilities and helper functions:
- `setup_test_environment()` - Loads all library modules and sets up test configuration
- `teardown_test_environment()` - Cleans up test artifacts
- `mock_docker_*()` - Mock functions that simulate Docker command outputs
- `strip_ansi()` - Removes ANSI color codes from output for assertions
- `assert_contains()` / `assert_not_contains()` - Custom assertion helpers

### test_helpers.bats
Tests for helper functions (src/helpers.sh):
- Output formatting functions (print_header, print_section, etc.)
- Logging functionality
- Usage/help message display

### test_discovery.bats
Tests for discovery functions (src/discovery.sh):
- Finding images, containers, volumes, and networks
- Case-insensitive searching
- Counter updates
- Handling empty results

### test_cleanup.bats
Tests for cleanup functions (src/cleanup.sh):
- Dry-run mode behavior
- Resource cleanup operations
- Logging of cleanup actions
- Handling empty results

## Writing New Tests

When adding new features or modifying existing ones:

1. **Add test cases** to the appropriate test file
2. **Use descriptive test names** that explain what's being tested
3. **Mock Docker commands** using the provided mock functions
4. **Clean up** in teardown to avoid test pollution

Example test:

```bash
@test "function_name does something specific" {
    # Arrange
    export SEARCH_TERM="myproject"

    # Act
    run function_name

    # Assert
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "expected string"
}
```

## Test Philosophy

- **Unit tests focus on individual functions**, not end-to-end workflows
- **Mock external dependencies** (Docker commands) to ensure tests are fast and reliable
- **Use DRY_RUN=true** for cleanup tests to avoid actual Docker operations
- **Test both success and failure paths** where applicable
- **Keep tests simple and focused** on one behavior per test

## CI/CD Integration

To integrate these tests into a CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Install bats
  run: |
    if [ "$RUNNER_OS" == "Linux" ]; then
      sudo apt-get update
      sudo apt-get install -y bats
    elif [ "$RUNNER_OS" == "macOS" ]; then
      brew install bats-core
    fi

- name: Run tests
  run: cd tests && ./run_tests.sh
```

## Troubleshooting

### "bats: command not found"
Install bats-core using your package manager (see Quick Start above).

### Tests fail with "docker: command not found"
The tests use mocked Docker commands, so Docker doesn't need to be installed. If you see this error, check that the mock functions are being exported correctly in test_helpers.bash.

### Permission errors
Ensure the test runner script is executable:
```bash
chmod +x tests/run_tests.sh
```
