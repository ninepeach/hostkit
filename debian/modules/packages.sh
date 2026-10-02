# Package-state mechanisms.

packages_missing() {
    local package
    for package in "$@"; do
        dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -qx 'ii ' || printf '%s\n' "$package"
    done
}
