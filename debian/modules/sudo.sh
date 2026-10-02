# sudo mechanisms.

sudo_validate_file() {
    visudo -cf "$1" >/dev/null
}

sudo_install_admin_rule() {
    local user="$1"
    local source_file="$2"
    local path="/etc/sudoers.d/90-hostkit-$user"

    user_validate_name "$user" || { die "Invalid user name: $user"; return 1; }
    [ -r "$source_file" ] || { die "sudo source file is not readable: $source_file"; return 1; }
    sudo_validate_file "$source_file" || { die "Invalid sudoers configuration."; return 1; }

    install -m 0440 "$source_file" "$path"
    sudo_validate_file "$path"
}
