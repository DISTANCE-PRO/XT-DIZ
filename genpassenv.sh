#!/bin/bash
set -euo pipefail

var="${1}"

pass="$(echo -n "${PASSWORD_SEED}:${var}" | sha256sum | base64 -w0 | head -c 32)"

echo "${var}=${pass}"
