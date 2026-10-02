# APT mechanisms.

apt_update() {
    log_info "Updating APT package metadata."
    DEBIAN_FRONTEND=noninteractive apt-get update
}

apt_install() {
    [ "$#" -gt 0 ] || return 0
    log_info "Ensuring required packages are installed."
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}
