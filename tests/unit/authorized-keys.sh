source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/authorized-keys.sh"

test_ok "ed25519 public key syntax" authorized_keys_validate_line "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexamplekeymaterial user@example"
test_ok "RSA public key syntax" authorized_keys_validate_line "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexample user@example"
test_not_ok "private-key marker rejected" authorized_keys_validate_line "-----BEGIN OPENSSH PRIVATE KEY-----"
test_not_ok "random text rejected" authorized_keys_validate_line "hello world"

tmp="$(mktemp)"
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexamplekeymaterial user@example' >"$tmp"
test_ok "valid key file accepted" authorized_keys_validate_file "$tmp"
printf '%s\n' 'not-a-key' >"$tmp"
test_not_ok "invalid key file rejected" authorized_keys_validate_file "$tmp"
: >"$tmp"
test_not_ok "empty key file rejected" authorized_keys_validate_file "$tmp"
rm -f "$tmp"

tmpdir="$(mktemp -d)"
home="$tmpdir/home"
mkdir -p "$home"
user_exists() { return 0; }
getent() { printf 'admin:x:1000:1000::%s:/bin/bash\n' "$home"; }
id() {
    if [ "$1" = "-gn" ]; then printf '%s\n' admin; return 0; fi
    command id "$@"
}
install() {
    if [ "$1" = "-d" ]; then
        local target
        for target in "$@"; do :; done
        mkdir -p "$target"
        return 0
    fi
    command install "$@"
}
chown() { return 0; }

keys="$tmpdir/keys"
target="$home/.ssh/authorized_keys"
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexisting existing' >"$keys"
mkdir -p "$home/.ssh"
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEold old' >"$target"
test_ok "authorized key appended without replacing existing keys" authorized_keys_ensure admin "$keys"
test_ok "existing authorized key preserved" grep -Fqx 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEold old' "$target"
test_ok "new authorized key added" grep -Fqx 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexisting existing' "$target"
test_ok "authorized key ensure is idempotent" authorized_keys_ensure admin "$keys"
test_eq "authorized key not duplicated" "1" "$(grep -Fc 'AAAAC3NzaC1lZDI1NTE5AAAAIEexisting' "$target")"
rm -rf "$tmpdir"
