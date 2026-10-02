source "$ROOT_DIR/debian/modules/pppoe.sh"

test_ok "normal PPPoE user" pppoe_validate_user user@example.com
test_not_ok "empty PPPoE user rejected" pppoe_validate_user ""
test_not_ok "control character in PPPoE user rejected" pppoe_validate_user $'user\nname'

tmpdir="$(mktemp -d)"
secret="$tmpdir/secret"
printf '%s\n' password >"$secret"
chmod 600 "$secret"
test_ok "regular readable secret accepted" pppoe_validate_secret_file "$secret"

ln -s "$secret" "$tmpdir/link"
test_not_ok "symlink secret rejected" pppoe_validate_secret_file "$tmpdir/link"
test_not_ok "missing secret rejected" pppoe_validate_secret_file "$tmpdir/missing"

rm -rf "$tmpdir"
