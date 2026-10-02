# Hostname mechanisms.

hostname_validate_label() {
    local label="$1"
    [ -n "$label" ] || return 1
    [ "${#label}" -le 63 ] || return 1
    printf '%s' "$label" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$'
}

hostname_validate() {
    local value="$1"
    [ -n "$value" ] || return 1
    [ "${#value}" -le 253 ] || return 1

    local label rest="$value"
    while :; do
        case "$rest" in
            *.*) label="${rest%%.*}"; rest="${rest#*.}" ;;
            *) label="$rest"; rest= ;;
        esac
        hostname_validate_label "$label" || return 1
        [ -z "$rest" ] && break
    done
}

hostname_set() {
    local value="$1"
    hostname_validate "$value" || { die "Invalid hostname: $value"; return 1; }
    [ "$(hostnamectl --static 2>/dev/null)" = "$value" ] && return 0
    hostnamectl set-hostname "$value"
}
