source "$ROOT_DIR/debian/modules/ssh.sh"

test_ok "port 22" ssh_validate_port 22
test_ok "port 65535" ssh_validate_port 65535
test_not_ok "port zero rejected" ssh_validate_port 0
test_not_ok "port 65536 rejected" ssh_validate_port 65536
test_not_ok "non-numeric port rejected" ssh_validate_port abc
