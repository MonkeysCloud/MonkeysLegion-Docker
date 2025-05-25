#!/usr/bin/env bash
set -euo pipefail

STATUS="$(curl -fsS --max-time 2 http://localhost/healthz || true)"
if [[ "$STATUS" == "OK" ]]; then
  exit 0
fi
echo "Healthcheck failed: $STATUS"
exit 1