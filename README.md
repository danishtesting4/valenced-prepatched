# Valenced Prepatched

[![Build](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/build.yml/badge.svg)](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/build.yml)
[![Release](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/release.yml/badge.svg)](https://github.com/danishtesting4/valenced-prepatched/releases/latest)
[![License](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://github.com/Valenced/valenced)

**[Valenced](https://valenced.app)** is a client modification for Discord mobile, allowing custom themes and plugins. This repository provides **pre-patched Discord APKs** — Discord that's already been patched with Valenced, ready to install without the Valenced Manager app.

> **⚠️ Disclaimer**
> 
> This is a community project, not an official Valenced release. It uses the same patch bundles and modules from the [Valenced releases](https://github.com/Valenced/valenced/releases). This simply automates the patching process so you get a ready-to-install APK.
> 
> Using client modifications may violate Discord's Terms of Service. Proceed at your own risk.

## Quick Start

1. Download the latest pre-patched APK from the [Releases](https://github.com/danishtesting4/valenced-prepatched/releases/latest) page.
2. Uninstall the official Discord app (or keep both — the pre-patched version installs under `app.valenced`).
3. Install the APK on your Android device.
4. Open it, log in, and head to **Settings → Valenced** to install plugins and themes.

## What's Included

Each release provides a pre-patched Discord APK that includes:

- **Valenced loader** – Patches Discord's code to load the Valenced bundle
- **Valenced bundle** – The JavaScript plugin system and core logic
- **Package rename** – Installs as `app.valenced` to run alongside the official Discord app
- **Valenced icon** – Custom icon so you can tell them apart
- **All patches enabled** – Themes, plugins, and other Valenced features

### Architectures

Pre-patched APKs are available for the most common Android architectures:

| Variant | Architecture | Devices |
|---------|-------------|---------|
| `arm64-v8a` | ARM64 (64-bit) | Most modern phones/tablets (recommended) |
| `armeabi-v7a` | ARM (32-bit) | Older devices |

## How It Works

```
Discord APK ← [Reseam patch engine] ← [Valenced patch bundle (.reseam)]
                    │
                    └─── Xposed module (Valenced loader)
                    └─── Package name: app.valenced
                    └─── App name: Valenced
                    └─── Custom icon
                    └─── Debuggable: false
                    └─── Sign with a fresh key
```

The workflow:

1. Downloads Discord APK splits for the supported version (352.6 - Alpha, versionCode `352206`)
2. Downloads the Valenced patch bundle (`valenced.reseam`) and Xposed module (`app-release.apk`) from the Valenced GitHub releases
3. Applies all patches using the [Reseam CLI](https://reseam.app/docs/cli/patch/)
4. Signs the APK with a generated key

## Building Locally

### Prerequisites

- **Java 17+** (Temurin or OpenJDK)
- **Linux or macOS** (the reseam CLI is Linux/macOS; use WSL on Windows)

### Steps

1. Download the [Reseam CLI](https://cdn.reseam.app/engine/v0.30.1/reseam-linux-x64):

```bash
curl -fsSLo reseam https://cdn.reseam.app/engine/v0.30.1/reseam-linux-x64
chmod +x reseam
```

2. Download the dependencies. You can use the provided script:

```bash
ARCH=arm64_v8a  # or armeabi_v7a
./patch.sh
```

Or manually download everything:

```bash
# Discord splits (version 352.6 - Alpha, versionCode 352206)
VALENCE_VERSION=1.2.3
DISCORD_VERSION_CODE=352206
MIRROR=https://proxy.vd.ushie.dev
DISCORD_BASE=https://github.com/Valenced/valenced/releases/download

# Download Discord
wget -O base.apk $MIRROR/tracker/download/$DISCORD_VERSION_CODE/base
wget -O config.$ARCH.apk $MIRROR/tracker/download/$DISCORD_VERSION_CODE/config.$ARCH
wget -O config.en.apk $MIRROR/tracker/download/$DISCORD_VERSION_CODE/config.en
wget -O config.xxhdpi.apk $MIRROR/tracker/download/$DISCORD_VERSION_CODE/config.xxhdpi

# Download Valenced
wget -O valenced.reseam $DISCORD_BASE/$VALENCE_VERSION/valenced.reseam
wget -O app-release.apk $DISCORD_BASE/$VALENCE_VERSION/app-release.apk
```

3. Generate a signing key (only need to do this once):

```bash
reseam bundle keygen --out valenced.pk8
# Note the public key it prints — you'll need to trust it
```

4. Patch:

```bash
reseam patch base.apk \
  --split config.$ARCH.apk \
  --split config.en.apk \
  --split config.xxhdpi.apk \
  --bundle valenced.reseam \
  --trust <public-key-from-keygen> \
  --preset all \
  --option "Valenced.module=app-release.apk" \
  --option "Change package name.packageName=app.valenced" \
  --option "Change app name.appName=Valenced" \
  --key valenced.pk8 \
  --cert valenced.der \
  --output-dir output/
```

5. The patched APK(s) will be in `output/`. Install with:

```bash
adb install -r output/base-arm64_v8a-patched.apk
# or for split APKs:
adb install-multiple output/*.apk
```

## Manual Patching

This repo also includes a `patch.sh` script for manual patching:

```bash
# Default values
VALENCE_VERSION=1.2.3
DISCORD_VERSION=352.6 - Alpha
ARCH=arm64_v8a

# Run with custom values
VALENCE_VERSION=1.2.3 ARCH=armeabi_v7a ./patch.sh
```

## Updating

When a new Valenced version is released:

1. This repo's workflow will automatically build and release the new patched APK
2. Uninstall the old Valenced Discord app
3. Install the new APK from [Releases](https://github.com/danishtesting4/valenced-prepatched/releases)

## Troubleshooting

- **Install failed**: Make sure you uninstalled any previous version or use `adb install-multiple` for split APKs
- **App crashes on startup**: Ensure you downloaded the correct architecture variant
- **Discord won't connect**: Try clearing the app cache/data in Android Settings → Apps → Valenced
- **Version mismatch**: Valenced pins to specific Discord versions. Check the [Valenced releases](https://github.com/Valenced/valenced/releases) for the supported version

## Credits

- [Valenced](https://github.com/Valenced) — Client modification for Discord mobile
- [Reseam](https://reseam.app) — Patch engine used by Valenced
- [LSPatch](https://github.com/LSPosed/LSPatch) — Underlying patching library

This project is licensed under GPL-3.0. Valenced's `android/patches` module is licensed under AGPL-3.0.