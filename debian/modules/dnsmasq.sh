# dnsmasq mechanisms.

dnsmasq_validate() {
    dnsmasq --test --conf-file="$1" >/dev/null 2>&1
}

dnsmasq_reload() {
    systemctl reload dnsmasq.service
}

dnsmasq_is_active() {
    systemctl is-active --quiet dnsmasq.service
}
