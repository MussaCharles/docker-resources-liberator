#!/usr/bin/env bats

# =============================================================================
# Tests for Helper Functions (src/helpers.sh)
# =============================================================================

# Load test helpers
load test_helpers

setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}

@test "print_header outputs formatted header" {
    run print_header "Test Header"
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "Test Header"
}

@test "print_section outputs formatted section" {
    run print_section "Test Section"
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "Test Section"
}

@test "print_success outputs success message" {
    run print_success "Success message"
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "✓ Success message"
}

@test "print_warning outputs warning message" {
    run print_warning "Warning message"
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "⚠ Warning message"
}

@test "print_error outputs error message" {
    run print_error "Error message"
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "✗ Error message"
}

@test "print_info outputs info message" {
    run print_info "Info message"
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "ℹ Info message"
}

@test "log_to_file creates log entry" {
    export ENABLE_LOG=true
    export LOG_FILE="${LOG_DIR}/test.log"

    log_to_file "Test log message"

    [ -f "$LOG_FILE" ]
    grep -q "Test log message" "$LOG_FILE"
}

@test "usage displays help message" {
    run usage
    [ "$status" -eq 0 ]
    stripped=$(strip_ansi "$output")
    assert_contains "$stripped" "Docker Resources Liberator"
    assert_contains "$stripped" "Usage:"
    assert_contains "$stripped" "--help"
    assert_contains "$stripped" "--dry-run"
    assert_contains "$stripped" "--yes"
}
