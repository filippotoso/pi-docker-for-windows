#!/bin/bash
set -euo pipefail

args=()

if [[ -n "${MODEL:-}" ]]; then
  args+=(--model "$MODEL")
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model=*)
      args+=(--model "${1#--model=}")
      shift
      ;;
    --model)
      if [[ $# -lt 2 ]]; then
        echo "Error: --model requires a value" >&2
        exit 1
      fi
      args+=(--model "$2")
      shift 2
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

exec pi "${args[@]}"
