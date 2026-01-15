#!/usr/bin/env bash
set -e

INTERVAL="${CHECK_INTERVAL:-3600}"

echo "[cert-sync] Loop started (interval: ${INTERVAL}s)"

while true; do
  /opt/cert-copy/deploy-certs.sh || true
  sleep "$INTERVAL"
done
