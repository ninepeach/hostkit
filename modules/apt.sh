set -euo pipefail

install_base_packages() {
  export DEBIAN_FRONTEND=noninteractive

  info "apt: updating & upgrading"
  apt-get update
  apt-get dist-upgrade -y

  info "apt: installing base/security packages"
  apt-get install -y --no-install-recommends \
    sudo ca-certificates gnupg lsb-release \
    software-properties-common needrestart \
    rsyslog man-db bash-completion \
    unattended-upgrades apt-config-auto-update \
    chrony openssh-server

  info "apt: installing common utilities"
  apt-get install -y --no-install-recommends \
    vim nano less tree \
    htop tmux screen \
    curl wget rsync \
    unzip zip tar jq \
    net-tools iproute2 dnsutils \
    strace lsof ncdu mtr-tiny traceroute nmap \
    build-essential pkg-config make cmake \
    python3 python3-pip \
    git
}
