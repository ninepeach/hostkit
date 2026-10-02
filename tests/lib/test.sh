# Minimal HostKit unit-test helpers.

TEST_PASSED=0
TEST_FAILED=0

test_pass() {
    TEST_PASSED=$((TEST_PASSED + 1))
    printf 'PASS  %s\n' "$1"
}

test_fail() {
    TEST_FAILED=$((TEST_FAILED + 1))
    printf 'FAIL  %s\n' "$1" >&2
}

test_ok() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then test_pass "$name"; else test_fail "$name"; fi
}

test_not_ok() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then test_fail "$name"; else test_pass "$name"; fi
}

test_eq() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        test_pass "$name"
    else
        test_fail "$name"
        printf '      expected: %s\n      actual:   %s\n' "$expected" "$actual" >&2
    fi
}

test_summary() {
    printf '\n%d passed\n%d failed\n\n' "$TEST_PASSED" "$TEST_FAILED"
    if [ "$TEST_FAILED" -eq 0 ]; then
        printf 'STATUS PASS\n'
        return 0
    fi
    printf 'STATUS FAIL\n'
    return 1
}
