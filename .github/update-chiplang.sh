#!/usr/bin/env bash
set -euo pipefail

CODEBERG_OWNER="ideumi"
CODEBERG_REPO="chippy"
FLAKE_INPUT="chip-go"
VERSION_KEY="chiplang"
FLAKE_NIX="flake.nix"
BASE_URL="git+https://codeberg.org/${CODEBERG_OWNER}/${CODEBERG_REPO}"

CI=false
ONLY_CHECK=false

for arg in "$@"; do
  case "$arg" in
    --ci) CI=true ;;
    --only-check) ONLY_CHECK=true ;;
  esac
done

# Fetch latest release from Codeberg (Gitea API)
LATEST_RESPONSE=$(curl -sfL "https://codeberg.org/api/v1/repos/${CODEBERG_OWNER}/${CODEBERG_REPO}/releases/latest" 2>/dev/null || echo "{}")
LATEST_TAG=$(echo "$LATEST_RESPONSE" | jq -r '.tag_name // empty')

# Fall back to tags if no releases exist
if [ -z "$LATEST_TAG" ]; then
  TAGS_RESPONSE=$(curl -sfL "https://codeberg.org/api/v1/repos/${CODEBERG_OWNER}/${CODEBERG_REPO}/tags?limit=1" 2>/dev/null || echo "[]")
  LATEST_TAG=$(echo "$TAGS_RESPONSE" | jq -r '.[0].name // empty')
fi

if [ -z "$LATEST_TAG" ]; then
  echo "Could not determine latest version for ${CODEBERG_REPO}"
  if $CI; then echo "should_update=false" >> "$GITHUB_OUTPUT"; fi
  exit 0
fi

LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^[Vv]-\{0,1\}//')
CURRENT_VERSION=$(grep "${VERSION_KEY} = \"" "${FLAKE_NIX}" | sed 's/.*"\(.*\)".*/\1/')

echo "Current: ${CURRENT_VERSION}  Latest: ${LATEST_VERSION}"

if [ "${CURRENT_VERSION}" = "${LATEST_VERSION}" ]; then
  echo "Already up to date."
  if $CI; then echo "should_update=false" >> "$GITHUB_OUTPUT"; fi
  exit 0
fi

echo "Update available: ${CURRENT_VERSION} -> ${LATEST_VERSION}"

if $ONLY_CHECK; then
  if $CI; then echo "should_update=true" >> "$GITHUB_OUTPUT"; fi
  exit 0
fi

# Update version string
sed -i "s/${VERSION_KEY} = \"${CURRENT_VERSION}\"/${VERSION_KEY} = \"${LATEST_VERSION}\"/" "${FLAKE_NIX}"

# Pin flake input to the new tag
sed -i "s|url = \"${BASE_URL}[^\"]*\"|url = \"${BASE_URL}?ref=refs/tags/${LATEST_TAG}\"|" "${FLAKE_NIX}"

# Update lock file
nix flake update "${FLAKE_INPUT}"

if $CI; then
  echo "should_update=true" >> "$GITHUB_OUTPUT"
  echo "commit_message=chore: update chiplang to ${LATEST_VERSION}" >> "$GITHUB_OUTPUT"
fi

echo "Updated chiplang to ${LATEST_VERSION}"
