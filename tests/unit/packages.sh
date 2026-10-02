source "$ROOT_DIR/debian/modules/packages.sh"

mock_begin
mock_command dpkg-query 'case "$*" in *installed*) printf "ii \n"; exit 0 ;; *) exit 1 ;; esac'

test_eq "missing packages are reported" "missing" "$(packages_missing installed missing)"
test_eq "installed package omitted" "" "$(packages_missing installed)"
mock_end
