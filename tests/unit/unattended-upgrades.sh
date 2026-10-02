source "$ROOT_DIR/debian/modules/unattended-upgrades.sh"

# File mutation is integration-tested; unit scope verifies exported API exists.
test_ok "enable function exported" declare -F unattended_upgrades_enable
test_ok "validate function exported" declare -F unattended_upgrades_validate
