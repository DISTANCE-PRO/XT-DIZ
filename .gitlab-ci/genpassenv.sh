#!/bin/bash
set -euo pipefail

# Maps a DIZ slug to its CI/CD seed-var name.
# The transform is: uppercase, then `-` -> `_`, prefix with `PASSWORD_SEED_`.
# e.g. test-1 -> PASSWORD_SEED_TEST_1, leipzig-1 -> PASSWORD_SEED_LEIPZIG_1
seed_var_name() {
  local diz="${1:?usage: seed_var_name <DIZ_NAME>}"
  # shellcheck disable=SC2001
  echo "PASSWORD_SEED_$(echo "${diz^^}" | sed 's/-/_/g')"
}

var="${1:?usage: genpassenv.sh <SECRET_NAME>}"
seed_var="$(seed_var_name "${DIZ_NAME:?DIZ_NAME must be set}")"

# `set -u` does not catch unset vars under indirect expansion, so guard
# explicitly. Without this, a missing/typoed seed var silently produces
# sha256(":SECRET_NAME") and breaks OIDC auth at runtime.
: "${!seed_var:?seed var $seed_var is unset for DIZ_NAME=$DIZ_NAME}"

pass="$(echo -n "${!seed_var}:${var}" | sha256sum | head -c 32)"

echo "${var}=${pass}"
