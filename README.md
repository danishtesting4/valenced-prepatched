
# Valenced Prepatched

[![Build](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/build.yml/badge.svg)](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/build.yml)
[![Release](https://github.com/danishtesting4/valenced-prepatched/actions/workflows/release.yml/badge.svg)](https://github.com/danishtesting4/valenced-prepatched/releases/latest)
[![License](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://github.com/Valenced/valenced)

[Valenced](https://valenced.app) brings themes and plugins to Discord on Android. This project makes getting started easier by providing **pre-patched Discord APKs with Valenced already installed**, so you don't have to set everything up through the Valenced Manager yourself.

Download a release, extract the APK files, install them, and you're good to go.

## Before you install

A few things to keep in mind:

- **This is a community project.** It's not an official Valenced release. It uses patch bundles and modules from the [Valenced releases](https://github.com/Valenced/valenced/releases).
- **Client modifications have risks.** They may violate Discord's Terms of Service, so use them at your own discretion.
- **Discord versions matter.** Each build targets a specific Discord version. The current target is **352.6 Alpha (version code 352206)**. If Discord updates beyond the version supported by Valenced, the app may crash or stop working properly.

## Getting started

1. Download the latest archive from the [Releases page](https://github.com/danishtesting4/valenced-prepatched/releases/latest).
2. Extract the archive on your computer. Keep all the APK files together in the same folder.
3. Install the APKs using one of the methods below.

   **Option A: ADB (recommended)**

   Connect your Android device with USB debugging enabled, open a terminal in the folder containing the APKs, and run:

   ```bash
   adb install-multiple -r *.apk
   ```

   **Option B: Split APK installer**

   You can also use [APKMirror Installer](https://play.google.com/store/apps/details?id=com.apkmirror.helper.filecryptor) or [Split APKs Installer](https://play.google.com/store/apps/details?id=apk.installer).

   Open the installer, select all the extracted APK files, and follow the instructions.

4. Launch Valenced and log in. Open **Settings → Valenced** to explore the available plugins and themes.

## Available builds

Choose the version that matches your device's CPU architecture.

| Variant | Architecture | Suitable devices |
|---|---|---|
| `arm64_v8a` | ARM64, 64-bit | Most modern Android phones and tablets |
| `armeabi_v7a` | ARM, 32-bit | Older or 32-bit Android devices |

If you're unsure, `arm64_v8a` is the best starting point for most modern devices.

## What's included?

Each release archive contains these files:

| File | Description |
|---|---|
| `base.apk` | The main Discord APK, patched to load Valenced |
| `config.{arch}.apk` | Native libraries for the selected CPU architecture |
| `config.en.apk` | English language resources |
| `config.xxhdpi.apk` | Resources for the app's display density |
| `signing.pk8` / `signing.der` | Signing files used to sign builds and support future updates |
| `INSTALL.txt` | Installation instructions |

### Patches

The build uses the Valenced patch bundle with the following configuration:

- **Valenced:** Loads the Valenced bundle into Discord.
- **Change package name:** Changes the package name to `app.valenced`, allowing it to coexist with the official Discord app when Android's signing and installation requirements are met.
- **Change app name:** Displays `Valenced` as the app name.
- **Valenced icon:** Uses a cyan icon to distinguish it from regular Discord.
- **Enable debugging:** Disabled in the resulting build.

## How it works

The build takes the required Discord APKs and Valenced assets, applies the selected patches through Reseam, and packages the result into a release archive.

```text
Discord APKs (352.6 Alpha, versionCode 352206)
                 |
                 v
       Reseam patching process
                 ^
                 |
       +---------+---------+
       |                   |
 Valenced bundle      Xposed module
 (valenced.reseam)    (app-release.apk)
       |                   |
       +---------+---------+
                 |
                 v
       Pre-patched APK set
          Package: app.valenced
                 |
                 v
          Release archive
```

### Related projects

This repository relies on work maintained by other projects:

- [Valenced](https://github.com/Valenced/valenced) — The core project, including its patch bundle and Android module.
- [Valenced Manager](https://github.com/Valenced/valenced-manager) — The official installer and management app.
- [Reseam](https://reseam.app) — The patching engine used to apply the bundle.

Check those projects for their source code, documentation, and release history.

## Building locally

Want to build the APKs yourself? You can use the build script or run the steps manually.

### Requirements

- **Java 17 or newer** (Java 21 is recommended for the relevant tooling).
- **Linux or macOS.** The Reseam CLI used by this project isn't available for Windows in this setup.
- `wget` or `curl` for downloading files.
- `zip` for packaging the output.

### Quick build

Clone the repository and run the build script:

```bash
git clone https://github.com/danishtesting4/valenced-prepatched.git
cd valenced-prepatched

chmod +x patch.sh

# Build for most modern Android devices
./patch.sh

# Build for older 32-bit ARM devices
ARCH=armeabi_v7a ./patch.sh
```

The script handles the build steps for you. Check its configuration if you need to change the target versions or other build options.

### Manual build

If you prefer to run each step yourself, follow these instructions.

**1. Download the Reseam CLI**

For Linux x86-64:

```bash
wget -q https://cdn.reseam.app/engine/v0.30.1/reseam-linux-x64 -O reseam
chmod +x reseam
```

**2. Download the Discord APKs**

The following example uses the ARM64 build:

```bash
mkdir -p downloads
cd downloads

wget -q https://proxy.vd.ushie.dev/tracker/download/352206/base -O base.apk
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/config.arm64_v8a -O config.arm64_v8a.apk
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/config.en -O config.en.apk
wget -q https://proxy.vd.ushie.dev/tracker/download/352206/config.xxhdpi -O config.xxhdpi.apk
```

**3. Download the Valenced assets**

These commands use Valenced version `1.2.3` as an example:

```bash
wget -q https://github.com/Valenced/valenced/releases/download/1.2.3/valenced.reseam -O valenced.reseam
wget -q https://github.com/Valenced/valenced/releases/download/1.2.3/app-release.apk -O app-release.apk
```

Make sure the bundle and module versions match the versions expected by your build configuration.

**4. Generate a signing key**

Run the following command using the Reseam executable you downloaded:

```bash
./reseam bundle keygen --out signing
```

Keep the generated signing files somewhere safe if you intend to update the same installation later.

**5. Apply the patches**

From the directory containing the downloaded APKs and Valenced assets, run:

```bash
mkdir -p output

../reseam patch base.apk \
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

Adjust the executable path if you placed `reseam` somewhere else. The APKs and Valenced assets must also be available at the paths specified by the command.

**6. Install the result**

```bash
cd output
adb install-multiple -r *.apk
```

### Docker build

A Docker image is also available for Linux-based builds:

```bash
docker build -t valenced-prepatched .
mkdir -p output
docker run --rm -v "$(pwd)/output:/output" valenced-prepatched
```

The container's build configuration determines where the generated files are written. Make sure it uses `/output` for the mounted output directory.

## GitHub Actions

GitHub Actions handles the build and release process, so you don't have to run everything locally.

| Trigger | What happens |
|---|---|
| Push to `main` | Runs a CI build and uploads artifacts for inspection |
| Pull request | Builds the project to check for errors |
| Published GitHub Release | Builds the APKs and uploads the release archive |
| Manual dispatch | Starts a workflow run manually, with an optional `publish` flag |

When a release is published, the workflow:

1. Downloads the required Discord APKs and Valenced assets.
2. Applies the configured patches using Reseam.
3. Packages the resulting APKs and signing files into a ZIP archive.
4. Uploads the archive to the GitHub Release.

You can check the [Actions tab](https://github.com/danishtesting4/valenced-prepatched/actions) to see build results and logs.

## Updating Valenced or Discord

When a new Valenced version becomes available, check whether the build configuration needs updating.

1. Check the [Valenced releases](https://github.com/Valenced/valenced/releases).
2. Update `VALENCE_VERSION` in the relevant workflow files and `patch.sh`.
3. If the supported Discord version has changed, update `DISCORD_VERSION_CODE` as well.
4. Run a build and verify that the APKs install and launch correctly before publishing.

### Updating an existing installation

Android requires updates to use a compatible signing key. To update an existing installation:

1. Download the new APK set from the [latest release](https://github.com/danishtesting4/valenced-prepatched/releases/latest).
2. Make sure the new build uses the same signing key as your existing installation.
3. Install the APKs with:

   ```bash
   adb install-multiple -r *.apk
   ```

The `-r` flag reinstalls the app while attempting to preserve its data.

**Keep your signing key safe.** If a new build uses a different key, Android will reject it as an update. You'll need to uninstall the existing app before installing the differently signed build, which can result in losing its local data.

## Troubleshooting

| Problem | What to try |
|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | The installed app and new APKs were signed with different keys. Use the original signing key or uninstall the old installation before reinstalling. |
| `INSTALL_FAILED_CONFLICTING_PERMISSION` | Check for an existing installation or package conflict, then remove the conflicting app if necessary. |
| The app crashes on startup | Check that you installed every required split APK and selected the correct architecture. Also verify that the Discord and Valenced versions are compatible. |
| Discord won't connect | Check your internet connection first. If the issue persists, try clearing Valenced's cache or data in Android Settings → Apps → Valenced. Clearing data may remove local app data. |
| The build uses an incompatible version | Check the pinned Discord version and the Valenced version used by the release. Avoid updating Discord independently of the supported build. |

## Architecture notes

Valenced is made up of a few components that work together:

1. **`bundle`** — Contains Hermes JavaScript bytecode for the plugin system and user interface.
2. **`core`** — Shared Kotlin Multiplatform code used by the plugin system.
3. **`android`** — The Android-side Xposed module responsible for injecting Valenced into Discord.

The `valenced.reseam` bundle provides the patches and JavaScript functionality, while `app-release.apk` supplies the Android module that connects the native side to the JavaScript bundle.

Reseam brings these pieces together and produces the patched APK set.

## License and attribution

The automation scripts and workflows in this repository are licensed under **GPL-3.0**.

This repository automates the process of downloading and combining assets from external projects. It does not claim ownership of Valenced's code, patches, or other third-party assets. Those components remain subject to their respective licenses and terms.

- **Valenced:** [GPL-3.0](https://github.com/Valenced/valenced/blob/master/LICENSE)
- **Valenced patches:** [AGPL-3.0](https://github.com/Valenced/valenced/blob/master/android/patches/LICENSE)
- **Reseam:** [AGPL-3.0](https://reseam.app)

Check the upstream projects for the complete license terms applicable to their code and assets.
