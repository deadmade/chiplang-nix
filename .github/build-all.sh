#!/usr/bin/env bash
set -euo pipefail

nix flake check

packages=$(nix flake show --json 2>/dev/null | jq -r '.packages."x86_64-linux" | keys | .[]')

for package in $packages; do
  echo "Building .#${package}"
  nix build --system 'x86_64-linux' ".#${package}"
done
