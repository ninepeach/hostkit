source "$ROOT_DIR/debian/modules/system-health.sh"

mock_begin
mock_command systemctl 'printf "a.service loaded failed failed A\nb.service loaded failed failed B\n"'
mock_command df 'printf "Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/test 1000 400 600 40%% /\n"'
test_eq "failed units counted" "2" "$(health_failed_units_count)"
test_eq "root free space parsed" "600" "$(health_root_free_kb)"
mock_end

mock_begin
mock_command systemctl 'exit 0'
test_eq "zero failed units" "0" "$(health_failed_units_count)"
mock_end
