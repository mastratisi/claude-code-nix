#!/usr/bin/env bash
# Rewrite release.json from Anthropic's release manifest.
# The hashes are the checksums Anthropic publishes next to the binaries, not hashes of
# whatever this script downloaded.
set -euo pipefail
cd "$(dirname "$0")"

base=https://downloads.claude.ai/claude-code-releases
version=$(curl -fsS "$base/latest")
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "unexpected version: $version" >&2; exit 1; }

if [[ -f release.json && $(jq -r .version release.json) == "$version" ]]; then
  echo "up to date: $version"
  exit 0
fi

manifest=$(curl -fsS "$base/$version/manifest.json")
[[ $(jq -r .version <<<"$manifest") == "$version" ]] || { echo "manifest is for another version" >&2; exit 1; }

hashes='{}'
for platform in linux-x64 linux-arm64 darwin-x64 darwin-arm64; do
  hex=$(jq -er --arg p "$platform" '.platforms[$p].checksum' <<<"$manifest")
  [[ $hex =~ ^[0-9a-f]{64}$ ]] || { echo "bad checksum for $platform" >&2; exit 1; }
  sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  hashes=$(jq --arg p "$platform" --arg h "$sri" '. + {($p): $h}' <<<"$hashes")
done

jq -n --arg v "$version" --argjson h "$hashes" '{version: $v, hashes: $h}' > release.json
echo "updated to $version"
