# Alpine nftables mechanisms.

nftables_validate_file() { nft -c -f "$1"; }
nftables_apply_file() { nft -f "$1"; }
