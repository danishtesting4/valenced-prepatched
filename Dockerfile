# Dockerfile for building pre-patched Valenced APKs locally
#
# Build:
#   docker build -t valenced-prepatched .
# Run (downloads and patches Discord):
#   docker run --rm -v $(pwd)/output:/output -e ARCH=arm64_v8a valenced-prepatched
#

FROM eclipse-temurin:17-jdk

# Install dependencies
RUN apt-get update && apt-get install -y wget curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Download Reseam CLI
ARG RESEAM_VERSION=0.30.1
RUN wget -q "https://cdn.reseam.app/engine/v${RESEAM_VERSION}/reseam-linux-x64" -O /usr/local/bin/reseam && \
    chmod +x /usr/local/bin/reseam

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