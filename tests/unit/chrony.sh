source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/chrony.sh"

mock_begin
mock_command systemctl 'exit 0'
mock_command chronyc 'printf "Leap status     : Normal\n"'
test_ok "chrony synchronized state" chrony_validate
mock_end

mock_begin
mock_command systemctl 'exit 1'
test_not_ok "inactive chrony is failure" chrony_validate
mock_end

mock_begin
mock_command systemctl 'exit 0'
mock_command chronyc 'printf "Leap status     : Not synchronised\n"'
chrony_rc=0
chrony_validate >/dev/null 2>&1 || chrony_rc=$?
test_eq "unsynchronized chrony is pending" "2" "$chrony_rc"
mock_end
