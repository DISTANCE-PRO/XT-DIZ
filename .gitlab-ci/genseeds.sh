#!/bin/bash
set -euo pipefail

# Builds the TF_VAR_password_seeds JSON map from the .dizs anchor in
# .gitlab-ci.yml. For each DIZ, looks up its PASSWORD_SEED_<DIZ> env var and
# emits {"<diz>": "<seed>", ...} on stdout.
#
# Runs as its own bash process so the GitLab before_script (which executes
# under /bin/sh) never needs bashisms like here-strings or indirect
# expansion.

seeds="{}"
for diz in $(yq -r '.".dizs"[]' .gitlab-ci.yml); do
  # Map the DIZ slug to its seed var: uppercase, `-` -> `_`, prefix.
  # e.g. test-1 -> PASSWORD_SEED_TEST_1
  seed_var="PASSWORD_SEED_$(echo "${diz^^}" | tr '-' '_')"
  if [[ -z "${!seed_var:-}" ]]; then
    echo "Error: $seed_var is unset for DIZ $diz" >&2
    exit 1
  fi
  seeds="$(jq -c --arg k "$diz" --arg v "${!seed_var}" '.[$k]=$v' <<<"$seeds")"
done

echo "$seeds"
