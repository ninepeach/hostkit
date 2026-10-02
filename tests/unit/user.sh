source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/user.sh"

test_ok "normal user" user_validate_name admin
test_ok "hyphenated user" user_validate_name ops-user
test_not_ok "uppercase user rejected" user_validate_name Root
test_not_ok "space rejected" user_validate_name "bad user"

tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/home"

user_exists() { [ "$1" = existing ]; }
getent() {
    [ "$1" = passwd ] || return 1
    case "$2" in
        existing) printf 'existing:x:1000:1000::%s:/bin/bash\n' "$tmpdir/home" ;;
        *) return 2 ;;
    esac
}
test_ok "compatible existing admin accepted" user_is_compatible_admin existing
test_ok "ensure accepts compatible existing admin" user_ensure existing

getent() {
    [ "$1" = passwd ] || return 1
    printf 'existing:x:1000:1000::%s:/usr/sbin/nologin\n' "$tmpdir/home"
}
test_not_ok "nologin existing user rejected" user_is_compatible_admin existing
test_not_ok "ensure refuses incompatible existing user" user_ensure existing

rm -rf "$tmpdir"
