#!/usr/bin/env bash
set -euo pipefail

CODEBERG_OWNER="ideumi"
FLAKE_NIX="flake.nix"

CI=false
ONLY_CHECK=false
CODEBERG_REPO=""
FLAKE_INPUT=""
VERSION_KEY=""

usage() {
  echo "Usage: ${0##*/} --repo <codeberg-repo> --input <flake-input> --key <version-key> [--ci] [--only-check]" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) CODEBERG_REPO="${2:-}"; shift 2 ;;
    --input) FLAKE_INPUT="${2:-}"; shift 2 ;;
    --key) VERSION_KEY="${2:-}"; shift 2 ;;
    --ci) CI=true; shift ;;
    --only-check) ONLY_CHECK=true; shift ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

if [ -z "$CODEBERG_REPO" ] || [ -z "$FLAKE_INPUT" ] || [ -z "$VERSION_KEY" ]; then
  usage
fi

BASE_URL="git+https://codeberg.org/${CODEBERG_OWNER}/${CODEBERG_REPO}"
API="https://codeberg.org/api/v1/repos/${CODEBERG_OWNER}/${CODEBERG_REPO}"

set_output() {
  if $CI; then echo "$1=$2" >> "$GITHUB_OUTPUT"; fi
}

# Report "nothing to do" and exit successfully. A transient upstream problem
# must never turn the workflow red - it just means we retry on the next run.
skip() {
  echo "$1"
  set_output should_update false
  exit 0
}

# Echo the response body only if it is valid JSON, otherwise echo the fallback.
# curl -f already rejects HTTP >=400, but Codeberg can also answer 200 with a
# non-JSON body (maintenance / anti-bot page). Piping that straight into jq
# aborts the script under `set -euo pipefail` with jq's exit code 5.
fetch_json() {
  local url="$1" fallback="$2" body
  body=$(curl -sfL --retry 3 --retry-delay 2 --max-time 30 \
           -H 'Accept: application/json' "$url" 2>/dev/null) || body=""
  if [ -n "$body" ] && printf '%s' "$body" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$body"
  else
    printf '%s' "$fallback"
  fi
}

LATEST_TAG=$(fetch_json "${API}/releases/latest" '{}' | jq -r '.tag_name // empty')

# Fall back to tags if no releases exist
if [ -z "$LATEST_TAG" ]; then
  LATEST_TAG=$(fetch_json "${API}/tags?limit=1" '[]' | jq -r '.[0].name // empty')
fi

if [ -z "$LATEST_TAG" ]; then
  skip "Could not determine latest version for ${CODEBERG_REPO}"
fi

# The tag is interpolated into sed expressions and a flake URL below, so refuse
# anything outside a conservative character set.
if ! printf '%s' "$LATEST_TAG" | grep -qE '^[A-Za-z0-9._/-]+$'; then
  skip "Refusing suspicious tag for ${CODEBERG_REPO}: ${LATEST_TAG}"
fi

LATEST_VERSION=$(printf '%s' "$LATEST_TAG" | sed 's/^[Vv]-\{0,1\}//')

CURRENT_VERSION=$(grep "${VERSION_KEY} = \"" "${FLAKE_NIX}" | sed 's/.*"\(.*\)".*/\1/') || true
if [ -z "$CURRENT_VERSION" ]; then
  skip "Could not find a '${VERSION_KEY}' version in ${FLAKE_NIX}"
fi

echo "Current: ${CURRENT_VERSION}  Latest: ${LATEST_VERSION}"

if [ "${CURRENT_VERSION}" = "${LATEST_VERSION}" ]; then
  skip "Already up to date."
fi

echo "Update available: ${CURRENT_VERSION} -> ${LATEST_VERSION}"

# Exported so a later step can name the version in a failure report.
set_output current_version "$CURRENT_VERSION"
set_output latest_version "$LATEST_VERSION"

if $ONLY_CHECK; then
  set_output should_update true
  exit 0
fi

# Update version string
sed -i "s/${VERSION_KEY} = \"${CURRENT_VERSION}\"/${VERSION_KEY} = \"${LATEST_VERSION}\"/" "${FLAKE_NIX}"

# Pin flake input to the new tag
sed -i "s|url = \"${BASE_URL}[^\"]*\"|url = \"${BASE_URL}?ref=refs/tags/${LATEST_TAG}\"|" "${FLAKE_NIX}"

# Update lock file
nix flake update "${FLAKE_INPUT}"

set_output should_update true
set_output commit_message "chore: update ${VERSION_KEY} to ${LATEST_VERSION}"

echo "Updated ${VERSION_KEY} to ${LATEST_VERSION}"
