# Alpine persistent nftables ownership.

router_nftables_install() {
    local source="$1" path="${HOSTKIT_NFT_PATH:-/etc/nftables.d/90-hostkit-router.nft}"
    nftables_validate_file "$source" || { die "Invalid nftables ruleset."; return 1; }
    mkdir -p "$(dirname "$path")"
    if [ -e "$path" ] && ! grep -qx '# Managed by HostKit. Do not edit manually.' "$path"; then
        die "Refusing to overwrite nftables file not owned by HostKit: $path"; return 1
    fi
    local tmp; tmp="$(mktemp)"
    { printf '%s\n' '# Managed by HostKit. Do not edit manually.'; cat "$source"; } >"$tmp"
    install -m 0644 "$tmp" "$path"; rm -f "$tmp"
}
