#!/usr/bin/env bash
#
# patch.sh — Builds a pre-patched Valenced Discord APK from scratch.
#
# This script downloads Discord APKs, the Valenced patch bundle and Xposed module,
# then uses the Reseam CLI to produce a ready-to-install patched APK.
#
# Usage:
#   ./patch.sh                          # Uses default values
#   VALENCE_VERSION=1.2.3 ARCH=arm64_v8a ./patch.sh  # With custom values
#
# Requirements:
#   - Java 17+ on PATH
#   - wget or curl
#
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────

# Valenced release to use
VALENCE_VERSION="${VALENCE_VERSION:-1.2.3}"

# The Discord version that this Valenced release targets.
# From valenced-core: android/patches/apps/discord/patch/src/main/kotlin/app/valenced/patches/discord/Discord.kt
#   val DISCORD: CompatiblePackage = "com.discord"("352.6 - Alpha")
# versionCode = major(352) + typeOrdinal(2 for ALPHA) + minor(06) = 352206
DISCORD_VERSION_CODE="${DISCORD_VERSION_CODE:-352206}"

# Android architecture: arm64_v8i (most modern phones) or armeabi_v7a (older devices)
ARCH="${ARCH:-arm64_v8a}"

# Signing key (generated if not present)
SIGN_KEY_BASE="${SIGN_KEY_BASE:-valenced}"

# Valenced's patch bundle public key (from valenced-manager gradle.properties)
BUNDLE_PUBLIC_KEY="${BUNDLE_PUBLIC_KEY:-db74a921941576bf70cc1c2777741fb202131a76758ffd3ffcc785f9e76ff119}"

# Download mirrors for Discord APKs (from valenced-manager Mirror enum)
DISCORD_MIRROR="${DISCORD_MIRROR:-https://proxy.vd.ushie.dev}"

# Valenced release base URL
VALENCE_BASE="https://github.com/Valenced/valenced/releases/download/${VALENCE_VERSION}"

# Reseam CLI version (keep in sync with Valenced's build config)
RESEAM_VERSION="${RESEAM_VERSION:-0.30.1}"
RESEAM_CLI="${RESEAM_CLI:-./reseam}"

# Working and output directories
WORKDIR="${WORKDIR:-./patch-work}"
OUTDIR="${OUTDIR:-./output}"

# ── Helper Functions ───────────────────────────────────────────────────────

log() {
    echo "[patch] $*" >&2
}

download() {
    local url="$1"
    local output="$2"

    if command -v wget &>/dev/null; then
        wget -q --show-progress "$url" -O "$output"
    elif command -v curl &>/dev/null; then
        curl -fsSL --progress-bar "$url" -o "$output"
    else
        log "Error: Neither wget nor curl found."
        exit 1
    fi
}

download_reseam() {
    local output="$1"
    local os
    os="$(uname -s)"
    case "${os}" in
        Linux*)  local url="https://cdn.reseam.app/engine/v${RESEAM_VERSION}/reseam-linux-x64" ;;
        Darwin*) local url="https://cdn.reseam.app/engine/v${RESEAM_VERSION}/reseam-darwin-arm64" ;;
        *) log "Unsupported OS: ${os}. Please install Reseam CLI manually."; exit 1 ;;
    esac
    download "${url}" "${output}"
    chmod +x "${output}"
}

# ── Main ───────────────────────────────────────────────────────────────────

log "=== Valenced Pre-patched Discord Builder ==="
log "Valence version: ${VALENCE_VERSION}"
log "Discord versionCode: ${DISCORD_VERSION_CODE}"
log "Architecture: ${ARCH}"
log "Reseam CLI version: ${RESEAM_VERSION}"
log ""

mkdir -p "${WORKDIR}" "${OUTDIR}"

# ── Install Reseam CLI ─────────────────────────────────────────────────────

if [ ! -x "${RESEAM_CLI}" ]; then
    log "Downloading Reseam CLI v${RESEAM_VERSION}..."
    download_reseam "${RESEAM_CLI}"
fi

"${RESEAM_CLI}" --version
log ""

# ── Download Discord APKs ──────────────────────────────────────────────────

log "Downloading Discord APKs..."

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/base" \
    "${WORKDIR}/base.apk"
log "  Downloaded base.apk"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.${ARCH}" \
    "${WORKDIR}/config.${ARCH}.apk"
log "  Downloaded config.${ARCH}.apk"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.en" \
    "${WORKDIR}/config.en.apk"
log "  Downloaded config.en.apk"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.xxhdpi" \
    "${WORKDIR}/config.xxhdpi.apk"
log "  Downloaded config.xxhdpi.apk"
log ""

# ── Download Valenced assets ───────────────────────────────────────────────

log "Downloading Valenced assets..."

download "${VALENCE_BASE}/valenced.reseam" \
    "${WORKDIR}/valenced.reseam"
log "  Downloaded valenced.reseam"

download "${VALENCE_BASE}/app-release.apk" \
    "${WORKDIR}/app-release.apk"
log "  Downloaded app-release.apk (Xposed module)"
log ""

# ── Generate signing key (if needed) ───────────────────────────────────────

if [ ! -f "${SIGN_KEY_BASE}.pk8" ] || [ ! -f "${SIGN_KEY_BASE}.der" ]; then
    log "Generating new signing key..."
    "${RESEAM_CLI}" bundle keygen --out "${SIGN_KEY_BASE}"
fi
log ""

# ── Patch Discord ──────────────────────────────────────────────────────────

log "Patching Discord with Valenced..."

"${RESEAM_CLI}" patch "${WORKDIR}/base.apk" \
    --split "${WORKDIR}/config.${ARCH}.apk" \
    --split "${WORKDIR}/config.en.apk" \
    --split "${WORKDIR}/config.xxhdpi.apk" \
    --bundle "${WORKDIR}/valenced.reseam" \
    --trust "${BUNDLE_PUBLIC_KEY}" \
    --preset all \
    --option "Valenced.module=${WORKDIR}/app-release.apk" \
    --option "Change package name.packageName=app.valenced" \
    --option "Change app name.appName=Valenced" \
    --key "${SIGN_KEY_BASE}.pk8" \
    --cert "${SIGN_KEY_BASE}.der" \
    --output-dir "${OUTDIR}/"

log ""
log "=== Done! ==="
log ""
log "Patched APK(s) are in ${OUTDIR}/"
ls -la "${OUTDIR}/"
log ""
log "Install with:"
log "  adb install -r ${OUTDIR}/base-${ARCH}-patched.apk"
log "  or for split APKs: adb install-multiple ${OUTDIR}/*.apk"
log ""
log "Keep your signing key files (${SIGN_KEY_BASE}.pk8, ${SIGN_KEY_BASE}.der) to update the app later."