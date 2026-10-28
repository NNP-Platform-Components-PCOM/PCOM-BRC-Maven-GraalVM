# syntax=docker/dockerfile:1.7
#
# PCOM - BRC - Maven GraalVM
# --------------------------
# Maven build image on the PCOM GraalVM JDK 21 runtime image. Used by CI to
# compile and package Java applications with the same JDK that runs them.
# Part of the Nubo Native Platform (NNP) build components.
#
# Build:
#   docker build -t pcom-brc-maven-graalvm:3.9.11-graalvm21-v1 .

# Base image: the PCOM GraalVM runtime image. Overridable at build time.
ARG base_image=docker.io/nubonativesolution/pcom-brc-graalvm
ARG base_version=21

FROM ${base_image}:${base_version}

# --- OCI image metadata (populated by CI, overridable at build time) ---------
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION="3.9.11-graalvm21-v1"
ARG MAVEN_VERSION=3.9.11
ARG USER_HOME_DIR=/home/appuser

LABEL org.opencontainers.image.title="pcom-brc-maven-graalvm" \
      org.opencontainers.image.description="Maven ${MAVEN_VERSION} build image on GraalVM Community JDK 21." \
      org.opencontainers.image.vendor="Nubo Native Platform" \
      org.opencontainers.image.source="https://github.com/NNP-Platform-Components-PCOM/PCOM-BRC-Maven-GraalVM" \
      org.opencontainers.image.url="https://github.com/NNP-Platform-Components-PCOM/PCOM-BRC-Maven-GraalVM" \
      org.opencontainers.image.base.name="${base_image}:${base_version}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"

USER root

# Tooling needed to unpack Maven and for CI checkouts (git). The GraalVM base is
# Oracle Linux, so packages come from microdnf.
RUN microdnf install -y --setopt=install_weak_deps=0 tar gzip git shadow-utils \
    && (command -v curl >/dev/null || microdnf install -y curl-minimal) \
    && microdnf clean all

# Unprivileged build user.
RUN groupadd --system appgroup \
    && useradd --system --gid appgroup --create-home --home-dir ${USER_HOME_DIR} appuser

# Install Maven from the official Apache distribution, verifying the published
# SHA-512 checksum. Mirrors are tried in order; the checksum always comes from
# the Apache origin.
RUN set -eux; \
    mkdir -p /usr/share/maven /usr/share/maven/ref; \
    f="apache-maven-${MAVEN_VERSION}-bin.tar.gz"; \
    p="maven/maven-3/${MAVEN_VERSION}/binaries/${f}"; \
    for base in https://dlcdn.apache.org https://downloads.apache.org https://archive.apache.org/dist; do \
        curl -fsSL -o /tmp/maven.tar.gz "${base}/${p}" && break; \
    done; \
    for base in https://downloads.apache.org https://archive.apache.org/dist; do \
        curl -fsSL -o /tmp/maven.sha512 "${base}/${p}.sha512" && break; \
    done; \
    echo "$(cut -d' ' -f1 /tmp/maven.sha512)  /tmp/maven.tar.gz" | sha512sum -c -; \
    tar -xzf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1; \
    rm -f /tmp/maven.tar.gz /tmp/maven.sha512; \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME=/usr/share/maven \
    MAVEN_USER_HOME=${USER_HOME_DIR} \
    MAVEN_CONFIG=${USER_HOME_DIR}/.m2

RUN mkdir -p ${USER_HOME_DIR}/.m2 /data \
    && chown -R appuser:appgroup ${USER_HOME_DIR} /data

USER appuser
WORKDIR /data

RUN java --version && mvn --version
