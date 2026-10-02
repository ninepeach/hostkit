source "$ROOT_DIR/debian/modules/apt.sh"

mock_begin
mock_command apt-get 'printf "%s\n" "$*" >"$HOSTKIT_MOCK_DIR/call"'
apt_update >/dev/null
test_eq "apt_update command" "update" "$(cat "$HOSTKIT_MOCK_DIR/call")"
apt_install curl jq >/dev/null
test_eq "apt_install command" "install -y --no-install-recommends curl jq" "$(cat "$HOSTKIT_MOCK_DIR/call")"
mock_end
