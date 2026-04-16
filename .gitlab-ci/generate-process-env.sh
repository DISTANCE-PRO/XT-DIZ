#!/bin/sh
# Extract excluded processes from FDPG BPE process configuration and write a .env file
# used for generating a config-map in fdpg/bpe/server/kustomization.yaml.
set -eu

plugins_yaml="fdpg/bpe/server/process-plugins.yaml"
out_env="fdpg/bpe/server/process-excluded.env"

if [ ! -f "$plugins_yaml" ]; then
  echo "Input file '$plugins_yaml' not found." >&2
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "Required command 'yq' not found." >&2
  exit 1
fi

excluded="$(yq -r '[.processPlugins[]?.excludedProcesses[]?] | join(",")' "$plugins_yaml")"
printf 'DEV_DSF_BPE_PROCESS_EXCLUDED=%s\n' "$excluded" > "$out_env"

echo "Wrote $out_env"
