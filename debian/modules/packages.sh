# INIT package policy data and package-state helpers.

HOSTKIT_INIT_BASE_PACKAGES=(
    ca-certificates
    curl
    vim
    git
    jq
    rsync
    unzip
    less
)

HOSTKIT_INIT_NETWORK_PACKAGES=(
    iproute2
    iputils-ping
    dnsutils
    mtr-tiny
    tcpdump
    ethtool
    netcat-openbsd
    iperf3
    lsof
)

packages_missing() {
    local package
    for package in "$@"; do
        dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -qx 'ii ' || printf '%s\n' "$package"
    done
}
