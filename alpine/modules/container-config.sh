# HostKit Alpine CONTAINER configuration parser.
# Sourcing this file must not change host or caller shell state.

container_config_reset() {
    INOTIFY_MAX_USER_WATCHES=keep
    INOTIFY_MAX_USER_INSTANCES=keep
    INOTIFY_MAX_QUEUED_EVENTS=keep
    SOMAXCONN=keep
    NF_CONNTRACK_MAX=keep
    CONTAINER_CONFIG_SEEN_KEYS=
}

container_config_mark_seen() {
    local key="$1"
    case " $CONTAINER_CONFIG_SEEN_KEYS " in
        *" $key "*) die "Duplicate key: $key"; return 1 ;;
    esac
    CONTAINER_CONFIG_SEEN_KEYS="$CONTAINER_CONFIG_SEEN_KEYS $key"
}

container_config_valid_value() {
    local value="$1"
    [ "$value" = keep ] && return 0
    case "$value" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$value" -ge 1 ] 2>/dev/null
}

container_config_set() {
    local key="$1" value="$2"
    container_config_valid_value "$value" ||
        { die "Invalid value for $key: $value"; return 1; }

    case "$key" in
        INOTIFY_MAX_USER_WATCHES|INOTIFY_MAX_USER_INSTANCES|INOTIFY_MAX_QUEUED_EVENTS|SOMAXCONN|NF_CONNTRACK_MAX) ;;
        *) die "Unknown container tuning key: $key"; return 1 ;;
    esac
    container_config_mark_seen "$key" || return 1

    case "$key" in
        INOTIFY_MAX_USER_WATCHES) INOTIFY_MAX_USER_WATCHES="$value" ;;
        INOTIFY_MAX_USER_INSTANCES) INOTIFY_MAX_USER_INSTANCES="$value" ;;
        INOTIFY_MAX_QUEUED_EVENTS) INOTIFY_MAX_QUEUED_EVENTS="$value" ;;
        SOMAXCONN) SOMAXCONN="$value" ;;
        NF_CONNTRACK_MAX) NF_CONNTRACK_MAX="$value" ;;
    esac
}

container_config_parse() {
    local path="$1" line key value
    [ -r "$path" ] || { die "Container configuration is not readable: $path"; return 1; }
    container_config_reset

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        case "$line" in
            *[![:print:]]*) die "Control character in container configuration."; return 1 ;;
        esac
        case "$line" in
            *=*) key="${line%%=*}"; value="${line#*=}" ;;
            *) die "Invalid container configuration line: $line"; return 1 ;;
        esac
        [ -n "$key" ] && [ -n "$value" ] ||
            { die "Invalid container configuration line: $line"; return 1; }
        container_config_set "$key" "$value" || return 1
    done <"$path"
}
