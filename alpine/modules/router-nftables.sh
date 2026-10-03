# Alpine persistent nftables ownership.

router_nftables_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] && IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

router_nftables_install() {
    local source="$1" path="${HOSTKIT_NFT_PATH:-/etc/nftables.d/90-hostkit-router.nft}"
    nftables_validate_file "$source" || { die "Invalid nftables ruleset."; return 1; }
    mkdir -p "$(dirname "$path")"
    if [ -e "$path" ] && ! router_nftables_hostkit_owned "$path"; then
        die "Refusing to overwrite nftables file not owned by HostKit: $path"; return 1
    fi
    local tmp; tmp="$(mktemp)"
    { printf '%s\n' '# Managed by HostKit. Do not edit manually.'; cat "$source"; } >"$tmp"
    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then rm -f "$tmp"; return 0; fi
    install -m 0644 "$tmp" "$path"
    rm -f "$tmp"
}
