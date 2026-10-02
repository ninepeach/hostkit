source "$ROOT_DIR/debian/modules/authorized-keys.sh"

test_ok "ed25519 public key syntax" authorized_keys_validate_line "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexamplekeymaterial user@example"
test_ok "RSA public key syntax" authorized_keys_validate_line "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexample user@example"
test_not_ok "private-key marker rejected" authorized_keys_validate_line "-----BEGIN OPENSSH PRIVATE KEY-----"
test_not_ok "random text rejected" authorized_keys_validate_line "hello world"
