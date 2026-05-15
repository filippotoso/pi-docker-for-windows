#!/bin/bash
set -euo pipefail

secret_path=/run/secrets/cursor_api_key

if [[ ! -e "$secret_path" ]]; then
	echo "pi-entrypoint: missing $secret_path (mount your API key file here)" >&2
	exit 1
fi
if [[ ! -f "$secret_path" ]]; then
	echo "pi-entrypoint: $secret_path is not a regular file" >&2
	exit 1
fi
if [[ ! -r "$secret_path" ]]; then
	echo "pi-entrypoint: cannot read $secret_path" >&2
	exit 1
fi

key=$(sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$secret_path")
if [[ -z "$key" ]]; then
	echo "pi-entrypoint: secret file is empty" >&2
	exit 1
fi

provider="${PI_AUTH_PROVIDER:-opencode}"
agent_dir=/home/sandbox/.pi/agent
auth_json="$agent_dir/auth.json"

mkdir -p "$agent_dir"
if [[ ! -f "$auth_json" ]]; then
	echo '{}' >"$auth_json"
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
jq --arg p "$provider" --arg k "$key" '.[$p] = {type: "api_key", key: $k}' "$auth_json" >"$tmp"
install -m 600 -o sandbox -g sandbox "$tmp" "$auth_json"

chown -R sandbox:sandbox /home/sandbox/.pi

unset CURSOR_API_KEY OPENCODE_API_KEY || true

exec gosu sandbox pi "$@"
