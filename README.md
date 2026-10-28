# Valenced Prepatched

[![Build](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/build.yml/badge.svg)](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/build.yml)
[![Release](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/release.yml/badge.svg)](https://github.com/danishtesting4/valenced-prepatched/releases/latest)
[![License](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://github.com/Valenced/valenced)

**[Valenced](https://valenced.app)** is a client modification for Discord mobile, allowing custom themes and plugins. This repository provides **pre-patched Discord APKs** — Discord already modified with Valenced, ready to install without the Valenced Manager app.

> **⚠️ Disclaimers**
> 
> 1. This is a **community project**, not an official Valenced release. It uses the same patch bundles and modules from the [Valenced releases](https://github.com/Valenced/valenced/releases).
> 2. Using client modifications may violate Discord's Terms of Service. Proceed at your own risk.
> 3. Each release pins a **specific Discord version** (currently **352.6 - Alpha**). Discord updates ahead of Valenced will cause crashes — keep Discord at the pinned version.

## Quick Start

1. Download the latest archive from the [Releases](https://github.com/danishtesting4/valenced-prepatched/releases/latest) page.
2. Extract all APK files to the same folder on your computer.
3. Install the APK set:
   
   **Option A** — via ADB (recommended):
   ```bash
   adb install-multiple -r *.apk
   ```
   
   **Option B** — via a split APK installer app (e.g., [APKMirror Installer](https://play.google.com/store/apps/details?id=com.apkmirror.helper.filecryptor) or [Split APKs Installer](https://play.google.com/store/apps/details?id=apk.installer)):
   - Open the app and select all the extracted APK files.
   - Follow the prompts.

4. Open the app, log in, and go to **Settings → Valenced** to install plugins and themes.

## Available Builds

| Variant | Architecture | Devices |
|---------|-------------|---------|
| `arm64_v8a` | ARM64 (64-bit) | Most modern phones/tablets (recommended) |
| `armeabi_v7a` | ARM (32-bit) | Older devices |

## What's Inside

Each release archive contains:

| File | Description |
|------|-------------|
| `base.apk` | Main Discord APK with Valenced loader injected |
| `config.{arch}.apk` | Native libraries for your CPU architecture |
| `config.en.apk` | Language resources |
| `config.xxhdpi.apk` | App resources (images, fonts, etc.) |
| `signing.pk8` / `signing.der` | Signing keys for future updates |
| `INSTALL.txt` | Installation instructions |

### Patches Applied

All patches from the Valenced bundle are enabled:

- ✅ **Valenced** — Core patch that loads the Valenced bundle into Discord
- ✅ **Change package name** — Installs as `app.valenced` to run alongside the official Discord app
- ✅ **Change app name** — Shows as "Valenced" in the launcher
- ✅ **Valenced icon** — Custom cyan icon to distinguish from official Discord
- ✅ **Enable debugging** — Disabled (can be enabled if needed)

## How It Works

```
Official Discord APK (352.6 - Alpha, versionCode 352206)
  ───────────────────────────────────────────┐
                                             │
Valenced patch bundle (valenced.reseam)      ├→ Applies patches
Valenced Xposed module (app-release.apk)     ├→ Injects Valenced code
                                             │
                                             ▼
                    Pre-patched Discord APK ← [Valenced]
                    (package: app.valenced)
```

### Source Repositories

- **[Valenced](https://github.com/Valenced/valenced)** — Core Valenced code (bundle, Xposed module)
- **[Valenced-Manager](https://github.com/Valenced/valenced-manager)** — The official installer app
- **[Reseam](https://reseam.app)** — The patch engine used by Valenced

## Building Locally

### Prerequisites

- **Java 17+** (Java 21 recommended — LSPatch requires class file version 65.0)
- **Linux or macOS** (the Reseam CLI is not available for Windows)
- `wget` or `curl`
- `zip` (for packaging)

### One-command Build

```bash
# Clone this repo
git clone https://github.com/danishtesting4/valenced-prepatched
cd valenced-prepatched

# Make the script executable
chmod +x patch.sh

# Build for arm64_v8a (most phones)
./patch.sh

# Or build for armeabi_v7a (older devices)
ARCH=armeabi_v7a ./patch.sh
```

### Manual Build

1. Download the Reseam CLI:

```bash
wget -q https://cdn.reseam.app/engine/v0.30.1/reseam-linux-x64 -O reseam
chmod +x reseam
```

2. Download Discord APKs:

```bash
mkdir downloads && cd downloads
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/base -O base.apk
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/config.arm64_v8a -O config.arm64_v8a.apk
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/config.en -O config.en.apk
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/config.xxhdpi -O config.xxhdpi.apk
```

3. Download Valenced assets:

```bash
cd ../downloads
wget -q https://github.com/Valenced/valenced/releases/download/1.2.3/valenced.reseam -O valenced.reseam
wget -q https://github.com/Valenced/valenced/releases/download/1.2.3/app-release.apk -O app-release.apk
```

4. Generate signing key:

```bash
reseam bundle keygen --out signing
```

5. Patch:

```bash
mkdir output
reseam patch base.apk \
  --split config.arm64_v8a.apk \
  --split config.en.apk \
  --split config.xxhdpi.apk \
  --bundle valenced.reseam \
  --trust db74a921941576bf70cc1c2777741fb202131a76758ffd3ffcc785f9e76ff119 \
  --preset all \
  --option "Valenced.module=app-release.apk" \
  --option "Change package name.packageName=app.valenced" \
  --option "Change app name.appName=Valenced" \
  --key signing.pk8 \
  --cert signing.der \
  --output-dir output/
```

6. Install:

```bash
cd output
adb install-multiple -r *.apk
```

### Docker Build

A Docker image is also available for Linux users:

```bash
docker build -t valenced-prepatched .
docker run --rm -v $(pwd)/output:/output valenced-prepatched
```

## GitHub Actions

This repo has two workflows:

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **Build** | Push/PR | Validates the build process, produces split APK artifacts |
| **Release** | `workflow_dispatch` or GitHub Release | Creates a release archive with all APKs and signing keys |

## Updating

When a new Valenced version is released:

1. Check the [Valenced releases](https://github.com/Valenced/valenced/releases) for the new version.
2. Update `VALENCE_VERSION` in the workflow files and `patch.sh`.
3. The Discord version may also change — update `DISCORD_VERSION_CODE` accordingly.

When updating an existing installation:

1. Download the new pre-patched APK set from the [Releases](https://github.com/danishtesting4/valenced-prepatched/releases) page.
2. Use the **same signing key** (`signing.pk8` / `signing.der`) from your previous build:
   ```bash
   reseam patch base.apk \
     --key signing.pk8 \
     --cert signing.der \
     ...
   ```
3. Install with `adb install-multiple -r *.apk` (the `-r` flag preserves app data).

> ⚠️ If you lose the signing key, you must uninstall the old app first, as Android requires the same signing key for updates.

## Troubleshooting

- **"INSTALL_FAILED_UPDATE_INCOMPATIBLE"**: The installed app was signed with a different key. Uninstall the old version and reinstall.
- **"INSTALL_FAILED_CONFLICTING_PERMISSION"**: Another app with the same package name is installed. Uninstall the conflicting app.
- **App crashes on startup**: Make sure you downloaded the correct architecture variant.
- **Discord won't connect**: Try clearing the app cache/data in Android Settings → Apps → Valenced.
- **Version mismatch**: Valenced pins to a specific Discord version. Don't update Discord ahead of Valenced.

## Architecture Notes

The Valenced architecture consists of three parts:

1. **`bundle`** — Hermes JavaScript bytecode that runs inside Discord (the plugin system and UI)
2. **`core`** — Shared Kotlin Multiplatform code for the plugin system
3. **`android`** — The Android Xposed module that injects Valenced into Discord

The patch bundle (`valenced.reseam`) contains both the core patches (which modify Discord's code) and the bundle (JavaScript that provides the plugin/theme features). The Xposed module (`app-release.apk`) is loaded inside Discord and acts as the bridge between the native code and the JavaScript bundle.

## License

This repository is licensed under GPL-3.0. It does not contain any copyrighted code from Valenced — it only provides automation scripts and workflows that download and combine publicly available assets.

- Valenced: [GPL-3.0](https://github.com/Valenced/valenced/blob/master/LICENSE)
- Valenced patches: [AGPL-3.0](https://github.com/Valenced/valenced/blob/master/android/patches/LICENSE)
- Reseam: [AGPL-3.0](https://reseam.app)