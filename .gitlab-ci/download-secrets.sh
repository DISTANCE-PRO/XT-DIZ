#!/bin/sh
# Download secret credentials (private key, client certificate) for DSF instances
# from GitLab Secure Files and extract them into <output-dir>/.
set -eu

DIZ_NAME="${1:?Usage: $0 <diz-name> <output-dir>}"
OUTPUT_DIR="${2:?Usage: $0 <diz-name> <output-dir>}"
ARCHIVE="${DIZ_NAME}-secrets.tar.gz"

mkdir -p "${OUTPUT_DIR}"

glab auth login \
  --job-token "$CI_JOB_TOKEN" \
  --hostname "$CI_SERVER_FQDN" \
  --api-protocol "$CI_SERVER_PROTOCOL"

glab securefile download --name "${DIZ_NAME}-secrets.tar.gz" --path="${OUTPUT_DIR}/${ARCHIVE}"
tar -xzf "${OUTPUT_DIR}/${ARCHIVE}" -C "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/${ARCHIVE}"
