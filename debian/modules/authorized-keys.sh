# authorized_keys mechanisms.

authorized_keys_validate_line() {
    local line="$1"
    printf '%s\n' "$line" | grep -Eq '^(ssh-ed25519|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com|ssh-rsa) [A-Za-z0-9+/]+={0,3}([[:space:]].*)?$'
}

authorized_keys_install() {
    local user="$1"
    local source_file="$2"
    local home group ssh_dir target

    user_exists "$user" || { die "User does not exist: $user"; return 1; }
    [ -r "$source_file" ] || { die "authorized_keys source is not readable: $source_file"; return 1; }

    local found=0 line
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        authorized_keys_validate_line "$line" || { die "Invalid authorized_keys entry."; return 1; }
        found=1
    done <"$source_file"
    [ "$found" -eq 1 ] || { die "No SSH public key found."; return 1; }

    home="$(getent passwd "$user" | cut -d: -f6)"
    group="$(id -gn "$user")"
    ssh_dir="$home/.ssh"
    target="$ssh_dir/authorized_keys"

    install -d -m 0700 -o "$user" -g "$group" "$ssh_dir"
    install -m 0600 -o "$user" -g "$group" "$source_file" "$target"
}
