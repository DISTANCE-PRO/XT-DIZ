#!/bin/sh
# Download secret credentials (private key, client certificate) for DSF instances
# from GitLab Secure Files and extract them into <output-dir>/extracted/.
set -eu

DIZ_NAME="${1:?Usage: $0 <diz-name> <output-dir>}"
OUTPUT_DIR="${2:?Usage: $0 <diz-name> <output-dir>}"
ARCHIVE="$(mktemp -d)/${DIZ_NAME}-secrets.tar.gz"

mkdir -p "${OUTPUT_DIR}"


glab auth login \
  --job-token "$CI_JOB_TOKEN" \
  --hostname "$CI_SERVER_FQDN" \
  --api-protocol "$CI_SERVER_PROTOCOL"

SECURE_FILE_ID="$(glab securefile list -P 100 \
  | jq ".[] | select(.name==\"${DIZ_NAME}-secrets.tar.gz\") | .id" \
  | head -n1)"

test -n "$SECURE_FILE_ID" \
  || { echo "Secure file '${DIZ_NAME}-secrets.tar.gz' not found"; exit 1; }

glab securefile download "$SECURE_FILE_ID" --path="$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$OUTPUT_DIR"
