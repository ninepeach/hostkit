# Alpine Tailscale inspection mechanisms.
# HostKit does not authenticate or join a tailnet automatically.

tailscale_installed() { command -v tailscale >/dev/null 2>&1 && command -v tailscaled >/dev/null 2>&1; }

tailscale_service_running() {
    rc-service tailscale status >/dev/null 2>&1
}

tailscale_report_state() {
    tailscale status >/dev/null 2>&1
}
