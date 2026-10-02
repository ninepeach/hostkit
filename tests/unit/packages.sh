source "$ROOT_DIR/debian/modules/packages.sh"

test_ok "base package list is populated" test "${#HOSTKIT_INIT_BASE_PACKAGES[@]}" -gt 0
test_ok "network package list is populated" test "${#HOSTKIT_INIT_NETWORK_PACKAGES[@]}" -gt 0
