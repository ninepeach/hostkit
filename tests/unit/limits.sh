source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/limits.sh"

test_not_ok "non-numeric nofile rejected" limits_configure_nofile invalid
test_not_ok "low nofile rejected" limits_configure_nofile 100

tmpdir="$(mktemp -d)"
export HOSTKIT_LIMITS_PATH="$tmpdir/90-hostkit.conf"

test_ok "managed limits file created" limits_configure_nofile 65535
test_ok "managed limits file validates" limits_validate_nofile 65535
test_ok "identical limits configuration is idempotent" limits_configure_nofile 65535

printf '%s\n' '# administrator owned' >"$HOSTKIT_LIMITS_PATH"
test_not_ok "foreign limits file is preserved" limits_configure_nofile 65535
test_eq "foreign limits content unchanged" '# administrator owned' "$(cat "$HOSTKIT_LIMITS_PATH")"

rm -rf "$tmpdir"
