# nftables mechanisms.

nft_validate() {
    nft --check --file "$1"
}

nft_backup() {
    local target="$1"
    nft list ruleset >"$target"
}

nft_apply() {
    nft --file "$1"
}

nft_ruleset() {
    nft list ruleset
}
