#!/usr/bin/env bash
set -eu

image="$1"
result_path="${2:-/dev/stdout}"

function config-hide-identity {
    jq '. + { Identity: { PeerID: "REDACTED", PrivKey: "REDACTED" } }'
}
function config-normalize {
    jq -S '. + { Bootstrap: .Bootstrap | sort_by(.) }'
}

podman run --rm --entrypoint /bin/sh "$image" -c 'ipfs init >/dev/null && cat "$IPFS_PATH/config"' \
| config-hide-identity \
| config-normalize \
> "$result_path"

