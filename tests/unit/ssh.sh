source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/ssh.sh"

test_ok "port 22" ssh_validate_port 22
test_ok "port 65535" ssh_validate_port 65535
test_not_ok "port zero rejected" ssh_validate_port 0
test_not_ok "port 65536 rejected" ssh_validate_port 65536
test_not_ok "non-numeric port rejected" ssh_validate_port abc
test_eq "SSH dropin render" $'Port 10220\nPubkeyAuthentication yes' "$(ssh_render_admin_dropin 10220)"

tmpdir="$(mktemp -d)"
export HOSTKIT_SSH_DROPIN_PATH="$tmpdir/90-hostkit.conf"
src="$tmpdir/source"
printf '%s\n' 'Port 22' >"$src"

ssh_validate_installed_config() { return 0; }
test_ok "managed SSH dropin installed" ssh_install_dropin "$src"
test_ok "managed SSH dropin ownership detected" ssh_hostkit_owned "$HOSTKIT_SSH_DROPIN_PATH"
test_ok "managed SSH dropin idempotent" ssh_install_dropin "$src"

printf '%s\n' '# administrator owned' >"$HOSTKIT_SSH_DROPIN_PATH"
test_not_ok "foreign SSH dropin preserved" ssh_install_dropin "$src"
test_eq "foreign SSH content unchanged" '# administrator owned' "$(cat "$HOSTKIT_SSH_DROPIN_PATH")"
rm -rf "$tmpdir"
