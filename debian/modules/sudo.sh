# sudo mechanisms.

sudo_validate_file() {
    visudo -cf "$1" >/dev/null
}

sudo_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] &&
        IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

sudo_install_admin_rule() {
    local user="$1"
    local source_file="$2"
    local path="/etc/sudoers.d/90-hostkit-$user"
    local tmp

    user_validate_name "$user" || { die "Invalid user name: $user"; return 1; }
    [ -r "$source_file" ] || { die "sudo source file is not readable: $source_file"; return 1; }

    tmp="$(mktemp)"
    {
        printf '%s\n' '# Managed by HostKit. Do not edit manually.'
        cat "$source_file"
    } >"$tmp"

    sudo_validate_file "$tmp" || { rm -f "$tmp"; die "Invalid sudoers configuration."; return 1; }

    if [ -e "$path" ] && ! sudo_hostkit_owned "$path"; then
        rm -f "$tmp"
        die "Refusing to overwrite sudoers file not owned by HostKit: $path"
        return 1
    fi

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi

    install -m 0440 "$tmp" "$path" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    sudo_validate_file "$path"
}
