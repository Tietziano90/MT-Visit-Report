#!/usr/bin/env bash
set -euo pipefail

# ================================================================================
# MT RECORD SUGGESTION - Lightning Web Component
# ================================================================================
# Author: Michael Tietze, Principal AI Architect
# Contact: mtietze@salesforce.com
# Created: December 2025
# Version: 1.5
#
# COPYRIGHT AND DISTRIBUTION
# Copyright © 2025 Salesforce, Inc. All rights reserved.
#
# INTERNAL USE ONLY - This code may not be shared externally or distributed
# outside of Salesforce without prior written approval from Michael Tietze
# (mtietze@salesforce.com).
# ================================================================================

usage() {
  echo "Usage: $0 <org-alias-or-username> [--wait N]"
  echo ""
  echo "Deploys full force-app/ to the target org using a conflict-tolerant strategy."
  exit 1
}

ORG="${1:-}"
WAIT="${WAIT:-60}"

if [[ -z "${ORG}" ]]; then
  usage
fi

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --wait)
      WAIT="${2:-60}"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ ! -d "force-app" ]]; then
  echo "ERROR: force-app/ not found in ${ROOT_DIR}"
  exit 2
fi

echo "Deploying force-app/ to org: ${ORG} (wait=${WAIT}s)"

# Note: --ignore-conflicts keeps local source as the source of truth.
sf project deploy start \
  --source-dir force-app \
  --target-org "${ORG}" \
  --ignore-conflicts \
  --wait "${WAIT}"














