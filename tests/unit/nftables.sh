source "$ROOT_DIR/debian/modules/nftables.sh"

tmp="$(mktemp)"
backup="$(mktemp)"
: >"$tmp"

mock_begin
mock_command nft 'case "$*" in "--check --file "*|"--file "*) exit 0 ;; "list ruleset") printf "table inet hostkit {}\n"; exit 0 ;; *) exit 1 ;; esac'
test_ok "nft validation success" nft_validate "$tmp"
test_ok "nft apply success" nft_apply "$tmp"
test_ok "nft backup success" nft_backup "$backup"
test_eq "nft backup captures ruleset" "table inet hostkit {}" "$(cat "$backup")"
test_eq "ruleset reader" "table inet hostkit {}" "$(nft_ruleset)"
mock_end

mock_begin
mock_command nft 'exit 1'
test_not_ok "nft validation failure propagated" nft_validate "$tmp"
test_not_ok "nft apply failure propagated" nft_apply "$tmp"
mock_end

rm -f "$tmp" "$backup"
