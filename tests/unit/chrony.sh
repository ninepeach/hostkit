source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/chrony.sh"

mock_begin
mock_command systemctl 'case "$1" in is-active) exit 0 ;; *) exit 0 ;; esac'
mock_command chronyc 'printf "Leap status     : Normal\n"'
test_ok "chrony synchronized state" chrony_validate
mock_end
