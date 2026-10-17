# syntax=docker/dockerfile:1
FROM ubuntu:latest AS jadx

# Install JAVA, gradle and set JAVA_HOME
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-jdk-headless && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install git
ARG GITHUB_TOKEN
ENV GH_TOKEN=${GITHUB_TOKEN}
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gh git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash && \
    rm -rf /var/lib/apt/lists/*

# Install sed
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sed && \
    rm -rf /var/lib/apt/lists/*

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
RUN --mount=type=cache,id=jadx-gradle,target=/root/.gradle,sharing=locked ./gradlew --no-daemon installDist

ENTRYPOINT ["bash"]

FROM ubuntu:latest AS ghidra

# Install JAVA, gradle and set JAVA_HOME
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-jdk-headless && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install build-essential for compiling native code
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install git
ARG GITHUB_TOKEN
ENV GH_TOKEN=${GITHUB_TOKEN}
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gh git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install sed
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sed && \
    rm -rf /var/lib/apt/lists/*

# Install bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash && \
    rm -rf /var/lib/apt/lists/*

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
RUN --mount=type=cache,id=ghidra-gradle,target=/root/.gradle,sharing=locked ./gradlew --no-daemon -I gradle/support/fetchDependencies.gradle
RUN --mount=type=cache,id=ghidra-gradle,target=/root/.gradle,sharing=locked \
    ./gradlew --no-daemon buildGhidra --stacktrace --info

ENTRYPOINT ["bash"]

FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Use HTTP for APT repositories for better local caching
RUN find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) \
    -exec sed -i 's|https://|http://|g' {} +

# Install JAVA and set JAVA_HOME
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-jdk-headless && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install node and npm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nodejs npm && \
    ln -s "$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")" /opt/java && \
    rm -rf /var/lib/apt/lists/*

# Install python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash && \
    rm -rf /var/lib/apt/lists/*

# Install github copilot CLI
ARG GITHUB_TOKEN
ENV COPILOT_GITHUB_TOKEN=${GITHUB_TOKEN}
ENV GITHUB_TOKEN=${GITHUB_TOKEN}
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*
RUN npm install -g @github/copilot && \
    npm cache clean --force && \
    copilot --version
# Manual test with: copilot -p "Reply with only OK. Do not use tools." -s

# Install rea dependency - jadx
COPY --from=jadx /app/build/libs/jadx-headless-mcp-0.7.1-all.jar /app/jadx-headless-mcp-0.7.1-all.jar
ENV REA_JADX_MCP_JAR=/app/jadx-headless-mcp-0.7.1-all.jar

# Install rea dependency - IDA
## Not possible now due to no free tier that support local binary installation

# Install rea-agents
RUN npm install -g rea-agents && \
    npm cache clean --force && \
    rea-agents --version
#RUN rea setup --full-output --yes --client copilot_cli --skill=true --install-hopper

WORKDIR /app

COPY ["original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk", "/app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk"]

ENTRYPOINT ["bash"]
