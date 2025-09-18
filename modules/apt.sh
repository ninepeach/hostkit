set -euo pipefail

install_base_packages() {
  export DEBIAN_FRONTEND=noninteractive
  info "apt: updating & upgrading"
  apt-get update -y
  apt-get dist-upgrade -y

  info "apt: installing base/security packages"

  apt-get install -y --no-install-recommends \
    sudo iptables iptables-persistent fail2ban chrony \
    unattended-upgrades apt-config-auto-update ca-certificates gnupg \
    lsb-release software-properties-common openssh-server needrestart

  info "apt: installing common utilities"
  apt-get install -y --no-install-recommends \
    vim nano less htop tmux screen \
    curl wget rsync git unzip zip tar jq \
    net-tools iproute2 dnsutils \
    build-essential pkg-config make cmake \
    python3 python3-pip \
    man-db bash-completion tree \
    rsyslog strace
}
