source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/transaction.sh"

test_ok "default timeout" transaction_validate_timeout 180
test_ok "minimum timeout" transaction_validate_timeout 30
test_ok "maximum timeout" transaction_validate_timeout 3600
test_not_ok "too-short timeout rejected" transaction_validate_timeout 10
test_not_ok "too-long timeout rejected" transaction_validate_timeout 3601
test_not_ok "non-numeric timeout rejected" transaction_validate_timeout abc

test_ok "simple transaction name" transaction_validate_name security
test_ok "hyphenated transaction name" transaction_validate_name router-apply
test_not_ok "empty transaction name rejected" transaction_validate_name ""
test_not_ok "space in transaction name rejected" transaction_validate_name "router apply"
test_not_ok "slash in transaction name rejected" transaction_validate_name "../router"
test_not_ok "uppercase transaction name rejected" transaction_validate_name SECURITY

rollback="$(mktemp)"
cat >"$rollback" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 700 "$rollback"

test_not_ok "arm requires begin" transaction_arm "$rollback" 180
test_ok "begin transaction" transaction_begin security

mock_begin
mock_command systemd-run 'exit 0'
mock_command systemctl 'exit 0'
test_ok "arm transaction" transaction_arm "$rollback" 180
test_eq "armed state recorded" "1" "$HOSTKIT_TRANSACTION_ARMED"
test_ok "rollback guard exists while armed" test -e "$HOSTKIT_TRANSACTION_GUARD"
test_ok "rollback wrapper exists while armed" test -x "$HOSTKIT_TRANSACTION_WRAPPER"
guard="$HOSTKIT_TRANSACTION_GUARD"
test_not_ok "double arm rejected" transaction_arm "$rollback" 180
test_ok "commit disarms transaction" transaction_commit
test_eq "commit clears armed state" "0" "$HOSTKIT_TRANSACTION_ARMED"
test_not_ok "commit removes rollback guard" test -e "$guard"
mock_end

transaction_begin router
mock_begin
mock_command systemd-run 'exit 1'
test_not_ok "systemd-run failure leaves transaction unarmed" transaction_arm "$rollback" 180
test_eq "failed arm remains unarmed" "0" "$HOSTKIT_TRANSACTION_ARMED"
mock_end

transaction_begin router
mock_begin
mock_command systemd-run 'exit 0'
mock_command systemctl 'case "$*" in "stop "*.timer) exit 1 ;; "status "*.timer) exit 0 ;; *) exit 0 ;; esac'
transaction_arm "$rollback" 180
test_not_ok "timer stop failure makes commit fail" transaction_commit
test_eq "failed disarm remains armed" "1" "$HOSTKIT_TRANSACTION_ARMED"
mock_end

transaction_begin collected
mock_begin
mock_command systemd-run 'exit 0'
mock_command systemctl 'case "$*" in "stop "*.timer) exit 1 ;; "status "*.timer) exit 1 ;; *) exit 0 ;; esac'
transaction_arm "$rollback" 180
test_ok "already-collected timer does not make commit fail" transaction_commit
test_eq "collected timer commit clears armed state" "0" "$HOSTKIT_TRANSACTION_ARMED"
mock_end

test_not_ok "rollback requires armed transaction after fresh begin" bash -c '
    source "'"$ROOT_DIR"'/debian/modules/core.sh"
    source "'"$ROOT_DIR"'/debian/modules/transaction.sh"
    transaction_begin test
    transaction_rollback "'"$rollback"'"
'

rm -f "$rollback"
