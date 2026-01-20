#!/usr/bin/env bash
set -euo pipefail

# Wrapper kept for course compatibility.
# Canonical IAM bootstrap lives at repo root: scripts/bootstrap_iam.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
while [[ "$DIR" != "/" && ! -f "$DIR/env.common.sh" ]]; do
  DIR="$(dirname "$DIR")"
done

if [[ ! -f "$DIR/env.common.sh" ]]; then
  echo "ERROR: Could not find env.common.sh in parent directories."
  exit 1
fi

bash "$DIR/scripts/bootstrap_iam.sh"
