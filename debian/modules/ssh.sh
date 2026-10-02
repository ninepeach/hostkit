# OpenSSH server mechanisms.

ssh_validate_port() {
    local value="$1"
    case "$value" in ''|*[!0-9]*) return 1 ;; esac
    [ "$value" -ge 1 ] && [ "$value" -le 65535 ]
}

ssh_validate_config() {
    sshd -t -f "$1"
}

ssh_validate_installed_config() {
    sshd -t
}

ssh_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] &&
        IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

ssh_install_dropin() {
    local source_file="$1"
    local path="${HOSTKIT_SSH_DROPIN_PATH:-/etc/ssh/sshd_config.d/90-hostkit.conf}"
    local tmp

    [ -r "$source_file" ] || { die "SSH source file is not readable: $source_file"; return 1; }
    tmp="$(mktemp)"
    {
        printf '%s\n' '# Managed by HostKit. Do not edit manually.'
        cat "$source_file"
    } >"$tmp"

    if [ -e "$path" ] && ! ssh_hostkit_owned "$path"; then
        rm -f "$tmp"
        die "Refusing to overwrite SSH file not owned by HostKit: $path"
        return 1
    fi
    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi

    install -m 0644 "$tmp" "$path" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    ssh_validate_installed_config
}

ssh_render_admin_dropin() {
    local port="$1"
    ssh_validate_port "$port" || { die "Invalid SSH port: $port"; return 1; }
    cat <<EOF
Port $port
PubkeyAuthentication yes
EOF
}

ssh_effective_port() {
    sshd -T 2>/dev/null | awk '$1 == "port" {print $2; exit}'
}

ssh_effective_port_is() {
    local expected="$1"
    [ "$(ssh_effective_port)" = "$expected" ]
}

ssh_reload() {
    systemctl reload ssh.service
}

ssh_is_active() {
    systemctl is-active --quiet ssh.service
}
