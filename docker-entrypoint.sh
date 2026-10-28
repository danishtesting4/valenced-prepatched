#!/usr/bin/env bash
set -euo pipefail

ARCH="${ARCH:-arm64_v8a}"
VALENCE_VERSION="${VALENCE_VERSION:-1.2.3}"
DISCORD_VERSION_CODE="${DISCORD_VERSION_CODE:-352206}"
BUNDLE_PUBLIC_KEY="${BUNDLE_PUBLIC_KEY:-db74a921941576bf70cc1c2777741fb202131a76758ffd3ffcc785f9e76ff119}"
DISCORD_MIRROR="${DISCORD_MIRROR:-https://proxy.vd.ushie.dev}"
OUTDIR="${OUTDIR:-/output}"

echo "=== Valenced Pre-patched Discord Builder ==="
echo "Valence version: ${VALENCE_VERSION}"
echo "Discord version code: ${DISCORD_VERSION_CODE}"
echo "Architecture: ${ARCH}"
echo ""

# Download Discord APKs
echo "Downloading Discord APKs..."
mkdir -p downloads/discord
cd downloads/discord
wget -q "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/base" -O base.apk
wget -q "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.${ARCH}" -O "config.${ARCH}.apk"
wget -q "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.en" -O config.en.apk
wget -q "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.xxhdpi" -O config.xxhdpi.apk
echo "Discord APKs downloaded."

# Download Valenced assets
echo ""
echo "Downloading Valenced assets..."
mkdir -p downloads/valenced
VALENCE_BASE="https://github.com/Valenced/valenced/releases/download/${VALENCE_VERSION}"
wget -q "${VALENCE_BASE}/valenced.reseam" -O downloads/valenced/valenced.reseam
wget -q "${VALENCE_BASE}/app-release.apk" -O downloads/valenced/app-release.apk
echo "Valenced assets downloaded."

# Generate signing key
echo ""
echo "Generating signing key..."
mkdir -p keys
reseam bundle keygen --out keys/valenced
echo "Signing key generated."

# Patch Discord
echo ""
echo "Patching Discord with Valenced..."
cd /work
mkdir -p output

reseam patch downloads/discord/base.apk \
  --split "downloads/discord/config.${ARCH}.apk" \
  --split "downloads/discord/config.en.apk" \
  --split "downloads/discord/config.xxhdpi.apk" \
  --bundle "downloads/valenced/valenced.reseam" \
  --trust "${BUNDLE_PUBLIC_KEY}" \
  --preset all \
  --option "Valenced.module=downloads/valenced/app-release.apk" \
  --option "Change package name.packageName=app.valenced" \
  --option "Change app name.appName=Valenced" \
  --key keys/valenced.pk8 \
  --cert keys/valenced.der \
  --output-dir output/

echo ""
echo "=== Build complete ==="
echo "Output files:"
ls -la output/
echo ""
echo "Signing key (keep for future updates):"
ls -la keys/

# Copy to output directory if mounted
if [ -d "${OUTDIR}" ]; then
    cp -v output/*.apk "${OUTDIR}/" 2>/dev/null || true
    echo "APKs copied to ${OUTDIR}"
fi