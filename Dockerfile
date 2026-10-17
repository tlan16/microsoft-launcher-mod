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

# Install bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash && \
    rm -rf /var/lib/apt/lists/*

# Install github copilot CLI
ARG COPILOT_GITHUB_TOKEN
ENV COPILOT_GITHUB_TOKEN=${COPILOT_GITHUB_TOKEN}
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*
RUN npm install -g @github/copilot && \
    npm cache clean --force && \
    copilot --version
# Manual test with: copilot -p "Reply with only OK. Do not use tools." -s

# Install rea dependency - jadx
COPY ["jadx-headless-mcp-0.7.1-all.jar", "/app/jadx-headless-mcp-0.7.1-all.jar"]
ENV REA_JADX_MCP_JAR=/app/jadx-headless-mcp-0.7.1-all.jar

# Install rea-agents
RUN npm install -g rea-agents && \
    npm cache clean --force && \
    rea-agents --version
RUN rea setup --yes --client copilot_cli --skill=true

WORKDIR /app

COPY ["original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk", "/app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk"]

ENTRYPOINT ["bash"]
