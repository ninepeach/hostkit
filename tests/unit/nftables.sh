source "$ROOT_DIR/debian/modules/nftables.sh"

mock_begin
mock_command nft 'exit 0'
tmp="$(mktemp)"
: >"$tmp"
test_ok "nft syntax wrapper propagates success" nft_validate "$tmp"
rm -f "$tmp"
mock_end
