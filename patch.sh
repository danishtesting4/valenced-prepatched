#!/usr/bin/env bash
#
# patch.sh — Builds a pre-patched Valenced Discord APK from scratch.
#
# Usage:
#   ./patch.sh                          # Uses default values
#   VALENCE_VERSION=1.2.3 ARCH=arm64_v8a ./patch.sh  # With custom values
#
# Requirements:
#   - Java 17+ on PATH (Java 21 recommended for LSPatch and APKEditor)
#   - Android SDK build-tools (zipalign, apksigner) on PATH
#   - wget or curl
#   - zip
#   - Linux or macOS (Reseam CLI is not available for Windows)
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

# Android architecture: arm64_v8a (most modern phones) or armeabi_v7a (older devices)
ARCH="${ARCH:-arm64_v8a}"

# Signing key base path
SIGN_KEY_BASE="${SIGN_KEY_BASE:-signing}"

# Valenced's patch bundle public key (from valenced-manager gradle.properties)
BUNDLE_PUBLIC_KEY="${BUNDLE_PUBLIC_KEY:-db74a921941576bf70cc1c2777741fb202131a76758ffd3ffcc785f9e76ff119}"

# Download mirrors for Discord APKs (from valenced-manager Mirror enum)
DISCORD_MIRROR="${DISCORD_MIRROR:-https://proxy.vd.ushie.dev}"

# Valenced release base URL
VALENCE_BASE="https://github.com/Valenced/valenced/releases/download/${VALENCE_VERSION}"

# Reseam CLI version (keep in sync with Valenced's android/patches/settings.gradle.kts)
RESEAM_VERSION="${RESEAM_VERSION:-0.30.1}"
RESEAM_CLI="${RESEAM_CLI:-./reseam}"

# APKEditor version (used to merge split APKs into a single APK)
APKEDITOR_VERSION="${APKEDITOR_VERSION:-1.4.9}"
APKEDITOR_JAR="${APKEDITOR_JAR:-./APKEditor.jar}"

# Working and output directories
WORKDIR="${WORKDIR:-./work}"
OUTDIR="${OUTDIR:-./output}"

# ── Helper Functions ───────────────────────────────────────────────────────

log() {
    echo "[patch] $*"
}

download() {
    local url="$1"
    local output="$2"

    if command -v wget &>/dev/null; then
        wget -q --show-progress "${url}" -O "${output}"
    elif command -v curl &>/dev/null; then
        curl -fsSL --progress-bar "${url}" -o "${output}"
    else
        log "Error: Neither wget nor curl found."
        exit 1
    fi
}

# ── Main ───────────────────────────────────────────────────────────────────

log "=== Valenced Pre-patched Discord Builder ==="
log "Valence version: ${VALENCE_VERSION}"
log "Discord versionCode: ${DISCORD_VERSION_CODE}"
log "Architecture: ${ARCH}"
log "Reseam CLI version: ${RESEAM_VERSION}"
log "APKEditor version: ${APKEDITOR_VERSION}"
log ""

mkdir -p "${WORKDIR}" "${OUTDIR}"

# ── Download Reseam CLI ────────────────────────────────────────────────────

if [ ! -x "${RESEAM_CLI}" ]; then
    log "Downloading Reseam CLI v${RESEAM_VERSION}..."
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)  RESEAM_URL="https://cdn.reseam.app/engine/v${RESEAM_VERSION}/reseam-linux-x64" ;;
        Darwin*) RESEAM_URL="https://cdn.reseam.app/engine/v${RESEAM_VERSION}/reseam-darwin-arm64" ;;
        *) log "Unsupported OS: ${OS}. Please install Reseam CLI manually."; exit 1 ;;
    esac
    download "${RESEAM_URL}" "${RESEAM_CLI}"
    chmod +x "${RESEAM_CLI}"
fi

"${RESEAM_CLI}" --version
log ""

# ── Download APKEditor (for merging split APKs into single APK) ──────────────

if [ ! -f "${APKEDITOR_JAR}" ]; then
    log "Downloading APKEditor v${APKEDITOR_VERSION}..."
    download "https://github.com/REAndroid/APKEditor/releases/download/V${APKEDITOR_VERSION}/APKEditor-${APKEDITOR_VERSION}.jar" "${APKEDITOR_JAR}"
    log "APKEditor downloaded: ${APKEDITOR_JAR}"
else
    log "APKEditor already downloaded: ${APKEDITOR_JAR}"
fi
log ""

# ── Download Discord APKs ──────────────────────────────────────────────────

log "Downloading Discord APKs..."

DOWNLOADS_DISCORD="${WORKDIR}/downloads/discord"
mkdir -p "${DOWNLOADS_DISCORD}"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/base" \
    "${DOWNLOADS_DISCORD}/base.apk"
log "  Downloaded base.apk"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.${ARCH}" \
    "${DOWNLOADS_DISCORD}/config.${ARCH}.apk"
log "  Downloaded config.${ARCH}.apk"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.en" \
    "${DOWNLOADS_DISCORD}/config.en.apk"
log "  Downloaded config.en.apk"

download "${DISCORD_MIRROR}/tracker/download/${DISCORD_VERSION_CODE}/config.xxhdpi" \
    "${DOWNLOADS_DISCORD}/config.xxhdpi.apk"
log "  Downloaded config.xxhdpi.apk"
log ""

# ── Download Valenced assets ───────────────────────────────────────────────

log "Downloading Valenced assets..."

DOWNLOADS_VALENCE="${WORKDIR}/downloads/valenced"
mkdir -p "${DOWNLOADS_VALENCE}"

download "${VALENCE_BASE}/valenced.reseam" \
    "${DOWNLOADS_VALENCE}/valenced.reseam"
log "  Downloaded valenced.reseam"

download "${VALENCE_BASE}/app-release.apk" \
    "${DOWNLOADS_VALENCE}/app-release.apk"
log "  Downloaded app-release.apk (Xposed module)"
log ""

# ── Generate signing key (if needed) ───────────────────────────────────────

KEYS_DIR="${WORKDIR}/keys"
mkdir -p "${KEYS_DIR}"

if [ ! -f "${KEYS_DIR}/${SIGN_KEY_BASE}.pk8" ] || [ ! -f "${KEYS_DIR}/${SIGN_KEY_BASE}.der" ]; then
    log "Generating new signing key..."
    "${RESEAM_CLI}" bundle keygen --out "${KEYS_DIR}/${SIGN_KEY_BASE}"
else
    log "Using existing signing key from ${KEYS_DIR}/${SIGN_KEY_BASE}.pk8"
fi
log ""

# ── Patch Discord ──────────────────────────────────────────────────────────

PATCH_OUTPUT="${WORKDIR}/patched"
rm -rf "${PATCH_OUTPUT}"
mkdir -p "${PATCH_OUTPUT}"

log "Patching Discord with Valenced..."

"${RESEAM_CLI}" patch "${DOWNLOADS_DISCORD}/base.apk" \
    --split "${DOWNLOADS_DISCORD}/config.${ARCH}.apk" \
    --split "${DOWNLOADS_DISCORD}/config.en.apk" \
    --split "${DOWNLOADS_DISCORD}/config.xxhdpi.apk" \
    --bundle "${DOWNLOADS_VALENCE}/valenced.reseam" \
    --trust "${BUNDLE_PUBLIC_KEY}" \
    --preset all \
    --option "Valenced.module=${DOWNLOADS_VALENCE}/app-release.apk" \
    --option "Change package name.packageName=app.valenced" \
    --option "Change app name.appName=Valenced" \
    --key "${KEYS_DIR}/${SIGN_KEY_BASE}.pk8" \
    --cert "${KEYS_DIR}/${SIGN_KEY_BASE}.der" \
    --output-dir "${PATCH_OUTPUT}/"

log ""
log "=== Merging split APKs into single APK ==="
log ""

MERGE_DIR="${WORKDIR}/merge"
rm -rf "${MERGE_DIR}"
mkdir -p "${MERGE_DIR}"

log "Copying split APKs to merge directory..."
cp "${PATCH_OUTPUT}"/base.apk "${MERGE_DIR}/"
cp "${PATCH_OUTPUT}"/"config.${ARCH}.apk" "${MERGE_DIR}/"
cp "${PATCH_OUTPUT}"/config.en.apk "${MERGE_DIR}/"
cp "${PATCH_OUTPUT}"/config.xxhdpi.apk "${MERGE_DIR}/"

log "Merging with APKEditor..."
SINGLE_APK="${WORKDIR}/valenced-${ARCH}.apk"
java -jar "${APKEDITOR_JAR}" m -i "${MERGE_DIR}/" -o "${SINGLE_APK}"

log "Merge complete: ${SINGLE_APK}"

# ── Zipalign and sign the single APK ────────────────────────────────────────

log ""
log "=== Signing the single APK ==="
log ""

# Zipalign (force 4-byte alignment)
ALIGNED_APK="${WORKDIR}/valenced-${ARCH}-aligned.apk"
log "Zipaligning APK..."
zipalign -f -4 "${SINGLE_APK}" "${ALIGNED_APK}"

# Sign with apksigner using the same key as Reseam
log "Signing APK with apksigner..."
apksigner sign --key "${KEYS_DIR}/${SIGN_KEY_BASE}.pk8" --cert "${KEYS_DIR}/${SIGN_KEY_BASE}.der" "${ALIGNED_APK}"

signed_apk="${WORKDIR}/valenced-${ARCH}-signed.apk"
cp "${ALIGNED_APK}" "${signed_apk}"

# Verify the signature
log "Verifying signature..."
apksigner verify "${signed_apk}"

log ""
log "=== Build Complete ==="
log ""

# ── Package output ─────────────────────────────────────────────────────────

log "Packaging single APK..."

PACKAGE_DIR="${WORKDIR}/package"
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

cp "${signed_apk}" "${PACKAGE_DIR}/valenced.apk"

# Copy signing keys for future updates
cp "${KEYS_DIR}/${SIGN_KEY_BASE}.pk8" "${PACKAGE_DIR}/signing.pk8"
cp "${KEYS_DIR}/${SIGN_KEY_BASE}.der" "${PACKAGE_DIR}/signing.der"

# Create installation instructions
cat > "${PACKAGE_DIR}/INSTALL.txt" << EOF
Pre-patched Discord with Valenced
=================================

Valence version: ${VALENCE_VERSION}
Discord version: 352.6 - Alpha
Architecture: ${ARCH}

Installation:
  1. Extract valenced.apk from the archive
  2. Install directly on your Android device:
     adb install -r valenced.apk

  Or copy the APK to your phone and open it with any file manager.

Signing key:
  - signing.pk8 / signing.der
  - Keep these files! You need them to update the app later (same signing key required)
  - If you lose them, you will need to uninstall and reinstall the app

Notes:
  - This installs alongside the official Discord app as "Valenced" (package: app.valenced)
  - Do NOT update Discord from the Play Store — it will break Valenced
EOF

# Create ZIP archive
ZIP_NAME="valenced-discord-${VALENCE_VERSION}-${ARCH}.zip"
cd "${PACKAGE_DIR}"
zip -r "${OUTDIR}/${ZIP_NAME}" .
log ""

log "Single APK package created:"
ls -la "${OUTDIR}/${ZIP_NAME}"
log ""
log "Install with:"
log "  adb install -r ${PACKAGE_DIR}/valenced.apk"
log ""
log "Or extract the ZIP and install valenced.apk with any APK installer app."
