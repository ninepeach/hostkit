# Locale mechanisms.

locale_validate_name() {
    local value="$1"
    [ -n "$value" ] && printf '%s' "$value" | grep -Eq '^[A-Za-z0-9_.@-]+$'
}

locale_is_available() {
    local value="$1"
    locale -a 2>/dev/null | grep -Fxiq "$value"
}

locale_generate() {
    local value="$1"
    locale_validate_name "$value" || { die "Invalid locale: $value"; return 1; }
    locale_is_available "$value" && return 0
    locale-gen "$value"
}

locale_set_default() {
    local value="$1"
    locale_validate_name "$value" || { die "Invalid locale: $value"; return 1; }
    locale_is_available "$value" || { die "Locale is not available: $value"; return 1; }
    update-locale LANG="$value"
}
