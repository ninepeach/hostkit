# authorized_keys mechanisms.

authorized_keys_validate_line() {
    local line="$1"
    printf '%s\n' "$line" | grep -Eq '^(ssh-ed25519|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com|ssh-rsa) [A-Za-z0-9+/]+={0,3}([[:space:]].*)?$'
}

authorized_keys_validate_file() {
    local source_file="$1"
    [ -r "$source_file" ] || return 1

    local found=0 line
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        authorized_keys_validate_line "$line" || return 1
        found=1
    done <"$source_file"
    [ "$found" -eq 1 ]
}

authorized_keys_ensure() {
    local user="$1"
    local source_file="$2"
    local home group ssh_dir target line

    user_exists "$user" || { die "User does not exist: $user"; return 1; }
    authorized_keys_validate_file "$source_file" || { die "Invalid or empty authorized_keys source."; return 1; }

    home="$(getent passwd "$user" | cut -d: -f6)"
    group="$(id -gn "$user")"
    [ -n "$home" ] && [ -n "$group" ] || { die "Cannot resolve user home/group: $user"; return 1; }

    ssh_dir="$home/.ssh"
    target="$ssh_dir/authorized_keys"
    install -d -m 0700 -o "$user" -g "$group" "$ssh_dir"

    touch "$target" || return 1
    chown "$user:$group" "$target" || return 1
    chmod 0600 "$target" || return 1

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        grep -Fqx -- "$line" "$target" || printf '%s\n' "$line" >>"$target" || return 1
    done <"$source_file"
}

authorized_keys_install() {
    authorized_keys_ensure "$@"
}
