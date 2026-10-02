# Timezone mechanisms.

timezone_validate() {
    local value="$1"
    [ -n "$value" ] || return 1

    # Timezone names are relative zoneinfo identifiers, never filesystem paths.
    case "$value" in
        /*|*'..'*|*//*|*\\*) return 1 ;;
    esac
    printf '%s' "$value" | grep -Eq '^[A-Za-z0-9._+-]+(/[A-Za-z0-9._+-]+)*$' || return 1

    [ -e "/usr/share/zoneinfo/$value" ] || return 1
    [ ! -d "/usr/share/zoneinfo/$value" ]
}

timezone_set() {
    local value="$1"
    timezone_validate "$value" || { die "Invalid timezone: $value"; return 1; }
    [ "$(timedatectl show -p Timezone --value 2>/dev/null)" = "$value" ] && return 0
    timedatectl set-timezone "$value"
}
