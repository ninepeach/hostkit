#!/usr/bin/env bash
# iptables (IPv4 + IPv6) with persistence
set -euo pipefail

firewall_iptables_apply() {
  info "Applying iptables rules (IPv4)..."
  iptables -F
  iptables -X
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT

  iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

  # SSH with light rate-limit
  if [[ "${SSH_PORT}" == "22" ]]; then
    # only 22 with rate-limit
    iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
             -m hashlimit --hashlimit-name ssh --hashlimit 10/min --hashlimit-burst 20 --hashlimit-mode srcip \
             -j ACCEPT
  else
    # new SSH port with rate-limit
    iptables -A INPUT -p tcp --dport "${SSH_PORT}" -m conntrack --ctstate NEW \
             -m hashlimit --hashlimit-name ssh --hashlimit 10/min --hashlimit-burst 20 --hashlimit-mode srcip \
             -j ACCEPT
    # keep 22 with rate-limit
    iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
  fi


  [[ "${ALLOW_HTTP}" == "true"  ]] && iptables -A INPUT -p tcp --dport 80  -j ACCEPT
  [[ "${ALLOW_HTTPS}" == "true" ]] && iptables -A INPUT -p tcp --dport 443 -j ACCEPT

  if [[ -n "${EXTRA_TCP_PORTS}" ]]; then
    IFS=',' read -ra ports <<< "$EXTRA_TCP_PORTS"
    for p in "${ports[@]}"; do
      iptables -A INPUT -p tcp --dport "$p" -j ACCEPT
    done
  fi

  iptables -A INPUT -j DROP

  info "Applying ip6tables rules (IPv6)..."
  ip6tables -F
  ip6tables -X
  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
  ip6tables -P OUTPUT ACCEPT

  ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP
  ip6tables -A INPUT -i lo -j ACCEPT
  ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

  # SSH with light rate-limit
  if [[ "${SSH_PORT}" == "22" ]]; then
    ip6tables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
              -m hashlimit --hashlimit-name ssh6 --hashlimit 10/min --hashlimit-burst 20 --hashlimit-mode srcip \
              -j ACCEPT
  else
    ip6tables -A INPUT -p tcp --dport "${SSH_PORT}" -m conntrack --ctstate NEW \
              -m hashlimit --hashlimit-name ssh6 --hashlimit 10/min --hashlimit-burst 20 --hashlimit-mode srcip \
              -j ACCEPT
    ip6tables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
  fi

  [[ "${ALLOW_HTTP}" == "true"  ]] && ip6tables -A INPUT -p tcp --dport 80  -j ACCEPT
  [[ "${ALLOW_HTTPS}" == "true" ]] && ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

  if [[ -n "${EXTRA_TCP_PORTS}" ]]; then
    IFS=',' read -ra ports6 <<< "$EXTRA_TCP_PORTS"
    for p in "${ports6[@]}"; do
      ip6tables -A INPUT -p tcp --dport "$p" -j ACCEPT
    done
  fi

  ip6tables -A INPUT -j DROP

  info "Persisting firewall rules..."
  netfilter-persistent save || true
  systemctl enable netfilter-persistent || true
  systemctl start netfilter-persistent || true
}
