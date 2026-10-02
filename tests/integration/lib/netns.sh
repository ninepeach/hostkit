#!/usr/bin/env bash

netns_supported() {
    command -v ip >/dev/null || return 1
    ip netns add "hostkit-probe-$$" >/dev/null 2>&1 || return 1
    ip netns del "hostkit-probe-$$" >/dev/null 2>&1
}

netns_create_pair() {
    local ns="$1" host_if="$2" ns_if="$3"
    ip netns add "$ns"
    ip link add "$host_if" type veth peer name "$ns_if"
    ip link set "$ns_if" netns "$ns"
    ip link set "$host_if" up
    ip -n "$ns" link set lo up
    ip -n "$ns" link set "$ns_if" up
}

netns_delete() {
    local ns="$1"
    ip netns del "$ns" >/dev/null 2>&1 || true
}
