#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Required configuration
# ==========================
: "${DOMAIN:?DOMAIN is required}"
: "${CADDY_ACME_BASE:?CADDY_ACME_BASE is required}"
: "${CADDY_ACME_CA_DIR:?CADDY_ACME_CA_DIR is required}"
: "${DEST_CERT_DIR:?DEST_CERT_DIR is required}"
: "${RESTART_CONTAINERS:?RESTART_CONTAINERS is required}"

# ==========================
# Optional configuration
# ==========================
DEST_CERT_NAME="${DEST_CERT_NAME:-cert.pem}"
DEST_KEY_NAME="${DEST_KEY_NAME:-key.pem}"
DOCKER_BIN="${DOCKER_BIN:-docker}"

# ==========================
# Paths
# ==========================
SRC_BASE="${CADDY_ACME_BASE}/certificates/${CADDY_ACME_CA_DIR}/${DOMAIN}"

SRC_CERT="${SRC_BASE}/${DOMAIN}.crt"
SRC_KEY="${SRC_BASE}/${DOMAIN}.key"

DEST_CERT="${DEST_CERT_DIR}/${DEST_CERT_NAME}"
DEST_KEY="${DEST_CERT_DIR}/${DEST_KEY_NAME}"

echo "[cert-sync] Checking certificate for ${DOMAIN}"

# ==========================
# Sanity checks
# ==========================
if [[ ! -f "$SRC_CERT" || ! -f "$SRC_KEY" ]]; then
  echo "[cert-sync] ERROR: Source cert or key not found"
  echo "  $SRC_CERT"
  echo "  $SRC_KEY"
  exit 1
fi

# ==========================
# Detect changes
# ==========================
OLD_HASH=""
if [[ -f "$DEST_CERT" ]]; then
  OLD_HASH=$(md5sum "$DEST_CERT" | awk '{print $1}')
fi

NEW_HASH=$(md5sum "$SRC_CERT" | awk '{print $1}')

if [[ "$OLD_HASH" == "$NEW_HASH" ]]; then
  echo "[cert-sync] Certificate unchanged — nothing to do"
  exit 0
fi

# ==========================
# Copy certificates
# ==========================
echo "[cert-sync] Certificate changed — deploying new files"

mkdir -p "$DEST_CERT_DIR"

cp "$SRC_CERT" "$DEST_CERT"
cp "$SRC_KEY" "$DEST_KEY"

chmod 600 "$DEST_CERT" "$DEST_KEY"

echo "[cert-sync] Certificates deployed to ${DEST_CERT_DIR}"

# ==========================
# Restart containers (Mailcow-style hook)
# ==========================
echo "[cert-sync] Restarting affected containers"

for container in ${RESTART_CONTAINERS}; do
  if $DOCKER_BIN ps --format '{{.Names}}' | grep -qx "$container"; then
    echo "[cert-sync] Restarting $container"
    $DOCKER_BIN restart "$container" >/dev/null
  else
    echo "[cert-sync] WARNING: Container '$container' not running"
  fi
done

echo "[cert-sync] Done"
