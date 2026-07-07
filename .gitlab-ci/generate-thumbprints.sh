#!/bin/sh
# Generate SHA-512 fingerprints for all RP DSF client certificates.
# The thumbprints file is used by the RP DSF mailbox to allow access
# with multiple client certificates.
set -eu

secretsDir="${1:?Usage: $0 <secrets-dir> <thumbprint-file>}"
thumbprintFile="${2:?Usage: $0 <secrets-dir> <thumbprint-file>}"

for cert in $(find "$secretsDir" -name "rp-dsf-ext*-client-cert.pem"); do
  openssl x509 --fingerprint --sha512 --noout --in "$cert" \
    | tr -d ":" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/.*fingerprint=(.*)/\1/'
done > "$thumbprintFile"
