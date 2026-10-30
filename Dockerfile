# Dockerfile for building pre-patched Valenced APKs locally
#
# Build:
#   docker build -t valenced-prepatched .
# Run (downloads, patches, and merges into single APK):
#   docker run --rm -v $(pwd)/output:/output -e ARCH=arm64_v8a valenced-prepatched
#

FROM eclipse-temurin:21-jdk

# Install dependencies
RUN apt-get update && apt-get install -y wget curl unzip zip && \
    rm -rf /var/lib/apt/lists/*

# Download Reseam CLI
ARG RESEAM_VERSION=0.30.1
RUN wget -q "https://cdn.reseam.app/engine/v${RESEAM_VERSION}/reseam-linux-x64" -O /usr/local/bin/reseam && \
    chmod +x /usr/local/bin/reseam

# Download APKEditor (for merging split APKs into single APK)
ARG APKEDITOR_VERSION=1.4.9
RUN wget -q "https://github.com/REAndroid/APKEditor/releases/download/V${APKEDITOR_VERSION}/APKEditor-${APKEDITOR_VERSION}.jar" \
    -O /usr/local/bin/APKEditor.jar

# Download Android SDK build-tools (for zipalign and apksigner)
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0
RUN mkdir -p /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION} && \
    wget -q "https://dl.google.com/android/repository/build-tools_${ANDROID_BUILD_TOOLS_VERSION}-linux.zip" -O /tmp/build-tools.zip && \
    cd /opt/android-sdk/build-tools && \
    unzip -q /tmp/build-tools.zip -d /tmp/bt && \
    mv /tmp/bt/${ANDROID_BUILD_TOOLS_VERSION}/* /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/ && \
    rm -rf /tmp/bt /tmp/build-tools.zip

ENV PATH="/opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:${PATH}" \
    ANDROID_HOME="/opt/android-sdk"

# Configuration
ENV VALENCE_VERSION=1.2.3 \
    DISCORD_VERSION_CODE=352206 \
    BUNDLE_PUBLIC_KEY=db74a921941576bf70cc1c2777741fb202131a76758ffd3ffcc785f9e76ff119 \
    DISCORD_MIRROR=https://proxy.vd.ushie.dev \
    ARCH=arm64_v8a \
    OUTDIR=/output

WORKDIR /work

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
