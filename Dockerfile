# syntax=docker/dockerfile:1
FROM ubuntu:latest AS jadx

ARG GITHUB_TOKEN

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV GH_TOKEN=${GITHUB_TOKEN}

# Install OS dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-jdk-headless \
        gh git ca-certificates \
        bash \
        sed && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Get source code of jadx
WORKDIR /app
RUN gh repo clone https://github.com/1013503897/jadx-headless-mcp . -- \
    --branch v0.7.1 \
    --depth 1 \
    --jobs 4 \
    --filter=blob:none \
    --recurse-submodules \
    --remote-submodules \
    --progress

# Enable automatic download of the required Java toolchain
RUN sed -i '1i plugins { id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0" }' settings.gradle.kts

# Build jadx
RUN --mount=type=cache,id=jadx-gradle,target=/root/.gradle,sharing=locked \
    ./gradlew --no-daemon --build-cache --configuration-cache --parallel --max-workers="$(nproc)" shadowJar

RUN set -eux; \
    set -- /app/build/libs/jadx-headless-mcp*-all.jar; \
    [ "$#" -eq 1 ]; \
    [ -f "$1" ]; \
    mkdir -p /opt/jadx; \
    mv "$1" /opt/jadx/jadx-headless-mcp.jar; \
    test -s /opt/jadx/jadx-headless-mcp.jar; \
    jar tf /opt/jadx/jadx-headless-mcp.jar > /tmp/jadx-jar-entries; \
    for entry in jadx/api/JadxDecompiler.class com/google/gson/Gson.class io/modelcontextprotocol/kotlin/sdk/server/Server.class; do \
        grep -Fx "$entry" /tmp/jadx-jar-entries; \
    done; \
    rm /tmp/jadx-jar-entries

ENTRYPOINT ["bash"]

FROM ubuntu:latest AS ghidra

ARG GITHUB_TOKEN

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV GH_TOKEN=${GITHUB_TOKEN}

# Install OS dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-jdk-headless \
        python3 python3-pip python3-venv python3-dev \
        build-essential \
        gh git ca-certificates \
        sed \
        bash \
        unzip && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Get source code of Ghidra
WORKDIR /app
RUN gh repo clone https://github.com/NationalSecurityAgency/ghidra.git . -- \
    --branch Ghidra_12.1.4_build \
    --depth 1 \
    --jobs 4 \
    --filter=blob:none \
    --recurse-submodules \
    --remote-submodules \
    --progress

# Enable automatic Java toolchain downloads
RUN sed -i "1i plugins { id 'org.gradle.toolchains.foojay-resolver-convention' version '1.0.0' }" settings.gradle

# Build Ghidra
# Ghidra tasks capture Project objects, which the configuration cache cannot serialize.
RUN --mount=type=cache,id=ghidra-gradle,target=/root/.gradle,sharing=locked \
    --mount=type=cache,id=ghidra-dependencies,target=/app/dependencies,sharing=locked \
    ./gradlew --no-daemon --build-cache --no-configuration-cache --parallel --max-workers="$(nproc)" -I gradle/support/fetchDependencies.gradle

RUN --mount=type=cache,id=ghidra-gradle,target=/root/.gradle,sharing=locked \
    --mount=type=cache,id=ghidra-dependencies,target=/app/dependencies,sharing=locked \
    ./gradlew --no-daemon --build-cache --no-configuration-cache --parallel --max-workers="$(nproc)" buildGhidra --stacktrace --info

# Extract the built distribution into a stable directory.
RUN set -eux; \
    set -- /app/build/dist/ghidra_*.zip; \
    [ "$#" -eq 1 ]; \
    [ -f "$1" ]; \
    mkdir -p /tmp/ghidra-dist /opt; \
    unzip -q "$1" -d /tmp/ghidra-dist; \
    set -- /tmp/ghidra-dist/ghidra_*; \
    [ "$#" -eq 1 ]; \
    [ -d "$1" ]; \
    mv "$1" /opt/ghidra; \
    rmdir /tmp/ghidra-dist; \
    test -x /opt/ghidra/support/analyzeHeadless

ENTRYPOINT ["bash"]

FROM ubuntu:latest AS apktool

ARG APKTOOL_VERSION=3.0.3

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install OS dependencies.
# The repository includes the Gradle wrapper; no system Gradle is needed.
# Gradle 8.14.x cannot run on Java 25; use Java 21 for this stage.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-21-jdk-headless \
        git ca-certificates \
        bash && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Get source code of Apktool.
# This public repository does not require a GitHub token.
WORKDIR /app
RUN git clone \
    --branch "v${APKTOOL_VERSION}" \
    --depth 1 \
    --single-branch \
    https://github.com/iBotPeaches/Apktool.git .

# Build and test Apktool, producing the standalone JAR without R8.
RUN --mount=type=cache,id=apktool-gradle,target=/root/.gradle,sharing=locked \
    ./gradlew --no-daemon --build-cache --no-configuration-cache \
        --parallel --max-workers="$(nproc)" \
        build shadowJar

# Install the built JAR and official Linux wrapper together.
RUN set -eux; \
    test -s /app/brut.apktool/apktool-cli/build/libs/apktool-cli.jar; \
    install -m 0755 \
        /app/brut.apktool/apktool-cli/build/libs/apktool-cli.jar \
        /usr/local/bin/apktool.jar; \
    install -m 0755 \
        /app/scripts/linux/apktool \
        /usr/local/bin/apktool; \
    apktool --version

ENTRYPOINT ["bash"]

FROM ubuntu:latest

ARG GITHUB_TOKEN

ENV COPILOT_GITHUB_TOKEN=${GITHUB_TOKEN}
ENV GITHUB_TOKEN=${GITHUB_TOKEN}
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV REA_JADX_HEAP_MIB=8192
ENV REA_JADX_ACTIVE_PROCESSOR_COUNT=4
ENV JAVA_TOOL_OPTIONS=-Xmx8g
ENV REA_JADX_OPERATION_TIMEOUT_MS=600000
ENV COPILOT_ALLOW_ALL=true

# Use HTTP for APT repositories for better local caching
RUN find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) \
    -exec sed -i 's|https://|http://|g' {} +

# Install OS dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-jdk-headless \
        nodejs npm \
        python3 python3-pip python3-venv python3-dev \
        jq yq \
        bash \
        ca-certificates && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install rea dependency - github copilot CLI
RUN npm install -g @github/copilot && \
    npm cache clean --force && \
    copilot --version
# Manual test with: copilot -p "Reply with only OK. Do not use tools." -s --context long_context

# Install rea dependency - jadx
COPY --from=jadx /opt/jadx/jadx-headless-mcp.jar /opt/jadx/jadx-headless-mcp.jar
ENV REA_JADX_MCP_JAR=/opt/jadx/jadx-headless-mcp.jar

# Install rea dependency - ghidra
COPY --from=ghidra /opt/ghidra /opt/ghidra
ENV GHIDRA_INSTALL_DIR=/opt/ghidra

# Install rea dependency - apktool
COPY --from=apktool /usr/local/bin/apktool.jar /usr/local/bin/apktool.jar
COPY --from=apktool /usr/local/bin/apktool /usr/local/bin/apktool
RUN apktool --version

# Install rea dependency - IDA
## Not possible now due to no free tier that support local binary installation

# Install rea-agents
RUN npm install -g rea-agents && \
    npm cache clean --force && \
    rea-agents --version
RUN apt-get update && \
    rea setup --full-output --yes --client copilot_cli --skill=true --install-hopper && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ["original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk", "/app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk"]

ENTRYPOINT ["bash"]

# rea inspect-android-package original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24\(arm64-v8a\,armeabi-v7a\)\(nodpi\)_apkmirror.com.apk
