## Ory Hydra Reference Java - Ubuntu 24.04 LTS Setup Guide

Complete guide for setting up the Ory Hydra reference Java project on **Ubuntu 24.04 LTS (Noble Numbat)**.

 **Optimized for Ubuntu 24.04 LTS** 

## Quick Setup (Copy-Paste)

For experienced users, here's the complete setup in one script:

```plaintext
# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 21
sudo apt install -y openjdk-21-jdk openjdk-21-jre

# Install Docker
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
newgrp docker

# Install tools
sudo apt install -y jq curl wget git

# Install Playwright dependencies (Ubuntu 24.04 specific)
sudo apt install -y \
    libgstreamer-plugins-bad1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer1.0-0 \
    libenchant-2-2 \
    libsecret-1-0 \
    libhyphen0 \
    libmanette-0.2-0 \
    libflite1 \
    libgles2 \
    libegl1 \
    libnotify4 \
    libxslt1.1 \
    libevent-2.1-7t64 \
    libopus0 \
    libwoff1 \
    libharfbuzz-icu0 \
    libgstreamer-gl1.0-0 \
    libvpx9 \
    libwebpdemux2 \
    libwebp7

# Clone and build
cd ~/Projects
git clone https://github.com/Post2Fix/ory-hydra-refrence-java
cd ory-hydra-refrence-java
chmod +x gradlew
./gradlew build -x test

echo "✅ Setup complete! Run: ./gradlew bootRun"
```

## Detailed Prerequisites Installation

### System Information

Check your Ubuntu version:

```plaintext
# Verify Ubuntu 24.04
lsb_release -a
# Expected: Ubuntu 24.04 LTS (Noble Numbat)

# Check architecture
uname -m
# Expected: x86_64 or aarch64
```

### 1\. Update System Packages

```plaintext
# Update package lists
sudo apt update

# Upgrade existing packages
sudo apt upgrade -y

# Install essential build tools
sudo apt install -y build-essential software-properties-common
```

### 2\. Install Java 21 (Ubuntu 24.04 Native)

Ubuntu 24.04 includes OpenJDK 21 in the default repositories!

```plaintext
# Install OpenJDK 21 (native in Ubuntu 24.04)
sudo apt install -y openjdk-21-jdk openjdk-21-jre

# Verify installation
java -version
# Expected output: openjdk version "21.0.x" 2024-xx-xx

javac -version
# Expected output: javac 21.0.x

# Check Java location
which java
# Expected: /usr/bin/java

# View Java alternatives
sudo update-alternatives --display java
```

#### Set JAVA\_HOME (Ubuntu 24.04)

```plaintext
# Find Java installation path
readlink -f $(which java)
# Typical output: /usr/lib/jvm/java-21-openjdk-amd64/bin/java

# Set JAVA_HOME in ~/.bashrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

# Reload configuration
source ~/.bashrc

# Verify
echo $JAVA_HOME
# Expected: /usr/lib/jvm/java-21-openjdk-amd64

java -version
```

### 3\. Install Docker (Ubuntu 24.04 Method)

Ubuntu 24.04 has updated Docker packages in the repositories.

#### Method A: Install from Ubuntu Repositories (Recommended for 24.04)

```plaintext
# Install Docker from Ubuntu repos
sudo apt install -y docker.io docker-compose-v2

# Verify installation
docker --version
# Expected: Docker version 24.x.x or higher

docker compose version
# Expected: Docker Compose version v2.x.x

# Check Docker service
sudo systemctl status docker
```

#### Method B: Install from Docker Official Repository (Latest Version)

```plaintext
# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt remove -y docker-compose-v2
sudo apt -f install
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Verify
docker --version
sudo docker run hello-world
```

#### Configure Docker Permissions

```plaintext
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes immediately
newgrp docker

# Verify you can run docker without sudo
docker ps

# If still having issues, logout and login again
```

#### Enable Docker Service

```plaintext
# Enable Docker to start on boot
sudo systemctl enable docker

# Start Docker service
sudo systemctl start docker

# Check status
sudo systemctl status docker

# Test Docker
docker run hello-world
```

### 4\. Install Additional Tools

```plaintext
# Install jq (JSON processor)
sudo apt install -y jq

# Install curl and wget
sudo apt install -y curl wget

# Install Git
sudo apt install -y git

# Verify installations
jq --version
curl --version
wget --version
git --version
```

### 5\. Install Playwright Dependencies (Ubuntu 24.04 Specific)

Ubuntu 24.04 has updated library versions. Here are the correct packages:

```plaintext
# Core Playwright dependencies for Ubuntu 24.04
sudo apt install -y \
    libgstreamer-plugins-bad1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer1.0-0 \
    libgstreamer1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav

# Additional libraries for Ubuntu 24.04
sudo apt install -y \
    libenchant-2-2 \
    libsecret-1-0 \
    libhyphen0 \
    libgles2 \
    libegl1 \
    libnotify4 \
    libxslt1.1 \
    libevent-2.1-7t64 \
    libopus0 \
    libwoff1 \
    libharfbuzz-icu0 \
    libgstreamer-gl1.0-0 \
    libvpx9 \
    libwebpdemux2 \
    libwebp7

# Ubuntu 24.04 specific packages
sudo apt install -y \
    libmanette-0.2-0 \
    libflite1

# Optional: Additional multimedia support
sudo apt install -y \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-pulseaudio
```

## Project Setup

### 1\. Create Projects Directory

```plaintext
# Create projects directory
mkdir -p ~/Projects
cd ~/Projects

# Or use your preferred location
# mkdir -p ~/Development
# cd ~/Development
```

### 2\. Clone the Repository

```plaintext
# Clone the repository
git clone <repository-url> ory-hydra-refrence-java

# Navigate to project directory
cd ory-hydra-refrence-java

# Verify project structure
ls -la

# Check Git status
git status
```

### 3\. Configure Gradle Wrapper

```plaintext
# Make gradlew executable
chmod +x gradlew

# Verify Gradle wrapper
./gradlew --version

# Expected output:
# Gradle 9.2.1
# Java 21.x.x
```

### 4\. Install Playwright Browsers

```plaintext
# Install Playwright browsers
./gradlew playwright --args="install"

# This will download:
# - Chromium
# - Firefox
# - WebKit
# - FFMPEG

# Wait for completion (may take 2-3 minutes)
```

### 5\. Build the Project

```plaintext
# Build without running tests (faster first build)
./gradlew build -x test

# Expected output: BUILD SUCCESSFUL in Xs

# Or build with tests (takes longer, ~5-6 minutes)
./gradlew build
```

### 6\. Verify Setup

```plaintext
# Run a quick test
./gradlew test --tests "LoginControllerTest"

# Expected: BUILD SUCCESSFUL

# Run all tests (optional, takes ~5-6 minutes)
./gradlew test
```

## Running the Application

### Prerequisites Check

Before starting, verify everything is ready:

```plaintext
# Check Java
java -version

# Check Docker
docker --version
docker ps

# Check project build
cd ~/Projects/ory-hydra-refrence-java
./gradlew --version
```

### Start Services (Two Terminal Windows)

#### Terminal 1: Start Ory Hydra

```plaintext
# Navigate to project directory
cd ~/Projects/ory-hydra-refrence-java

# Pull Hydra Docker image (first time only)
docker pull oryd/hydra:v25.4.0

# Start Hydra with docker-compose
docker-compose -f ./reference-app/src/test/resources/docker-compose.yml up

# Wait for these messages:
# ✓ "Successfully applied migrations!"
# ✓ "Setting up http server on :4444"
# ✓ "Setting up http server on :4445"

# Leave this terminal running
```

#### Terminal 2: Start Spring Boot Application

```plaintext
# Open a new terminal
# Navigate to project directory
cd ~/Projects/ory-hydra-refrence-java

# Start the application
./gradlew bootRun

# Wait for:
# ✓ "Started OryHydraReferenceApplication in X.XXX seconds"

# Leave this terminal running
```

### Verify Services Are Running

```plaintext
# Open a third terminal for verification

# Check Hydra Public API
curl http://localhost:4444/health/ready
# Expected: {"status":"ok"}

# Check Hydra Admin API
curl http://localhost:4445/health/ready
# Expected: {"status":"ok"}

# Check Spring Boot Application
curl http://localhost:8080/
# Expected: HTML response with "Welcome!"

# Check demo page
curl -I http://localhost:8080/demo
# Expected: HTTP/1.1 200
```

### Access the Application

Open your browser and navigate to:

*   **Demo Page**: http://localhost:8080/demo
*   **Main Page**: http://localhost:8080/
*   **Hydra Admin**: http://localhost:4445/admin/clients
*   **Hydra Public**: http://localhost:4444/.well-known/openid-configuration

## Troubleshooting Ubuntu 24.04

### Java Issues

#### Wrong Java Version

```plaintext
# Check current Java version
java -version

# List all installed Java versions
sudo update-alternatives --config java

# Select Java 21 (choose the number)
# Or set manually:
sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java

# Verify
java -version
```

#### JAVA\_HOME Not Set

```plaintext
# Check JAVA_HOME
echo $JAVA_HOME

# If empty, set it:
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Make permanent:
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' &gt;&gt; ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' &gt;&gt; ~/.bashrc
source ~/.bashrc
```

### Docker Issues (Ubuntu 24.04 Specific)

#### Docker Service Not Starting

```plaintext
# Check Docker service status
sudo systemctl status docker

# If not running, start it:
sudo systemctl start docker

# Enable on boot:
sudo systemctl enable docker

# Check for errors:
sudo journalctl -u docker --no-pager | tail -20
```

#### Permission Denied (Ubuntu 24.04)

```plaintext
# Add user to docker group
sudo usermod -aG docker $USER

# Verify group membership
groups $USER

# Apply changes (logout/login or use newgrp)
newgrp docker

# Test
docker ps

# If still issues, check Docker socket permissions:
sudo chmod 666 /var/run/docker.sock

# Or restart Docker:
sudo systemctl restart docker
```

#### Docker Compose Command Not Found

```plaintext
# Ubuntu 24.04 uses 'docker compose' (with space), not 'docker-compose'

# Check version:
docker compose version

# If not found, install:
sudo apt install -y docker-compose-v2

# Or use the old standalone version:
sudo apt install -y docker-compose
```

### Port Conflicts

```plaintext
# Check what's using ports
sudo ss -tulpn | grep :8080
sudo ss -tulpn | grep :4444
sudo ss -tulpn | grep :4445

# Or use lsof:
sudo lsof -i :8080
sudo lsof -i :4444
sudo lsof -i :4445

# Kill process if needed:
sudo kill -9 <pid>

# Or use fuser:
sudo fuser -k 8080/tcp
```

### Playwright Issues (Ubuntu 24.04)

#### Missing Libraries

```plaintext
# If you get library errors, install missing dependencies:
sudo apt install -y \
    libmanette-0.2-0 \
    libflite1 \
    libevent-2.1-7t64 \
    libvpx9

# Clear Playwright cache and reinstall:
rm -rf ~/.cache/ms-playwright
./gradlew playwright --args="install"
```

#### Browser Launch Fails

```plaintext
# Check for AppArmor restrictions (Ubuntu 24.04 specific)
sudo aa-status | grep chrome

# If AppArmor is blocking, you may need to disable for development:
# (Not recommended for production)
sudo systemctl stop apparmor
sudo systemctl disable apparmor

# Or run with --no-sandbox (development only):
# This is handled in test configuration
```

### Gradle Issues

#### Gradle Daemon Issues

```plaintext
# Stop all Gradle daemons
./gradlew --stop

# Clean build
./gradlew clean

# Rebuild
./gradlew build -x test
```

#### Out of Memory

```plaintext
# Check available memory
free -h

# Increase Gradle memory in gradle.properties:
echo "org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m" &gt;&gt; gradle.properties

# Or set environment variable:
export GRADLE_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=512m"
```

### Network Issues

#### Behind a Proxy

```plaintext
# Configure Docker proxy (Ubuntu 24.04)
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf

# Add:
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=https://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"

# Reload and restart:
sudo systemctl daemon-reload
sudo systemctl restart docker

# Configure Gradle proxy:
mkdir -p ~/.gradle
nano ~/.gradle/gradle.properties

# Add:
systemProp.http.proxyHost=proxy.example.com
systemProp.http.proxyPort=8080
systemProp.https.proxyHost=proxy.example.com
systemProp.https.proxyPort=8080
```

## Environment Configuration

### Environment Variables (Ubuntu 24.04)

Add these to `~/.bashrc`:

```plaintext
# Edit bashrc
nano ~/.bashrc

# Add at the end:

# Java Configuration
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Gradle Configuration (optional)
export GRADLE_USER_HOME="$HOME/.gradle"

# Docker Configuration (optional)
export DOCKER_HOST=unix:///var/run/docker.sock

# Save and exit (Ctrl+O, Enter, Ctrl+X)

# Apply changes:
source ~/.bashrc

# Verify:
echo $JAVA_HOME
echo $PATH
```

### Firewall Configuration (UFW)

```plaintext
# Check if UFW is active
sudo ufw status

# If active, allow development ports:
sudo ufw allow 8080/tcp comment 'Spring Boot Application'
sudo ufw allow 4444/tcp comment 'Hydra Public API'
sudo ufw allow 4445/tcp comment 'Hydra Admin API'

# Reload firewall:
sudo ufw reload

# Check status:
sudo ufw status numbered
```

### System Limits (Optional)

```plaintext
# Increase file descriptor limits for development
sudo nano /etc/security/limits.conf

# Add:
* soft nofile 65536
* hard nofile 65536

# Apply (logout/login required)
```

## Verification Script

Save this as `verify-ubuntu-24-setup.sh`:

```plaintext
#!/bin/bash

echo "=== Ubuntu 24.04 Setup Verification ==="
echo ""

# Ubuntu Version
echo "Ubuntu Version:"
lsb_release -d | cut -f2
echo ""

# Java
echo "Java Version:"
java -version 2&gt;&amp;1 | head -n 1
echo ""

# JAVA_HOME
echo "JAVA_HOME:"
echo $JAVA_HOME
echo ""

# Docker
echo "Docker Version:"
docker --version
echo ""

# Docker Compose
echo "Docker Compose Version:"
docker compose version
echo ""

# Docker Service
echo "Docker Service Status:"
systemctl is-active docker
echo ""

# Docker Permissions
echo "Docker Permissions (should not require sudo):"
docker ps &gt; /dev/null 2&gt;&amp;1 &amp;&amp; echo "✓ OK" || echo "✗ FAIL - Run: sudo usermod -aG docker $USER"
echo ""

# jq
echo "jq Version:"
jq --version
echo ""

# Git
echo "Git Version:"
git --version
echo ""

# Gradle
echo "Gradle Version:"
./gradlew --version 2&gt;/dev/null | grep "Gradle" || echo "Run from project directory"
echo ""

# Ports
echo "Port Status:"
echo -n "  Port 8080: "
ss -tuln | grep -q ":8080 " &amp;&amp; echo "IN USE" || echo "Available"
echo -n "  Port 4444: "
ss -tuln | grep -q ":4444 " &amp;&amp; echo "IN USE" || echo "Available"
echo -n "  Port 4445: "
ss -tuln | grep -q ":4445 " &amp;&amp; echo "IN USE" || echo "Available"
echo ""

# Playwright Dependencies
echo "Playwright Dependencies:"
dpkg -l | grep -q libmanette-0.2-0 &amp;&amp; echo "  ✓ libmanette-0.2-0" || echo "  ✗ libmanette-0.2-0 missing"
dpkg -l | grep -q libflite1 &amp;&amp; echo "  ✓ libflite1" || echo "  ✗ libflite1 missing"
echo ""

echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. cd ~/Projects/ory-hydra-refrence-java"
echo "2. ./gradlew build -x test"
echo "3. docker-compose -f ./reference-app/src/test/resources/docker-compose.yml up"
echo "4. ./gradlew bootRun"
```

Run it:

```plaintext
chmod +x verify-ubuntu-24-setup.sh
./verify-ubuntu-24-setup.sh
```

## Ubuntu 24.04 Specific Notes

### What's New in Ubuntu 24.04

*   **Java 21 Native**: OpenJDK 21 is available in default repositories
*   **Updated Libraries**: Many libraries have version bumps (e.g., libevent-2.1-7t64)
*   **Docker Updates**: Newer Docker versions in repositories
*   **AppArmor Changes**: Enhanced security policies may affect browser automation
*   **Wayland Default**: May affect some GUI applications (not relevant for this project)

### Ubuntu 24.04 Advantages

*   ✅ Java 21 out of the box (no PPA needed)
*   ✅ Updated Docker packages
*   ✅ Better ARM64 support
*   ✅ Improved security defaults
*   ✅ Long-term support until 2029

### Known Issues (Ubuntu 24.04)

**AppArmor Restrictions**: May block Playwright browsers

*   Solution: Disable AppArmor for development or configure policies

**Library Version Changes**: Some packages have new version numbers

*   Solution: Use the package list provided in this guide

**Snap vs APT**: Some packages prefer Snap

*   Solution: Use APT for better compatibility

## Additional Tools (Optional)

### IntelliJ IDEA

```plaintext
# Install via Snap (recommended for Ubuntu 24.04)
sudo snap install intellij-idea-community --classic

# Or download from JetBrains
wget https://download.jetbrains.com/idea/ideaIC-2024.3.tar.gz
tar -xzf ideaIC-2024.3.tar.gz
cd idea-IC-*/bin
./idea.sh
```

### Visual Studio Code

```plaintext
# Install via Snap
sudo snap install code --classic

# Or via APT
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor &gt; packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# Install Java extensions
code --install-extension vscjava.vscode-java-pack
```

### HTTPie

```plaintext
# Install HTTPie
sudo apt install -y httpie

# Usage
http GET http://localhost:4444/health/ready
```

### Postman

```plaintext
# Install via Snap
sudo snap install postman
```

##
