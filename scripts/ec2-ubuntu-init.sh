#!/usr/bin/env bash
# EC2 Ubuntu: Java 21, Docker, Docker Compose plugin.
# Run as the login user who should use Docker (typically `ubuntu`):
#   chmod +x scripts/ec2-ubuntu-init.sh
#   ./scripts/ec2-ubuntu-init.sh
# Or: sudo -E ./scripts/ec2-ubuntu-init.sh  (uses SUDO_USER for docker group)

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# User to add to the docker group (correct when script is run under sudo)
TARGET_USER="${SUDO_USER:-$USER}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "Could not determine a non-root user for the docker group." >&2
  echo "Run this script as your SSH user (e.g. ubuntu), not as root-only." >&2
  exit 1
fi

echo "==> apt update && apt upgrade"
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==> Install OpenJDK 21"
sudo apt-get install -y openjdk-21-jdk

echo "==> Install Docker and Compose v2 plugin"
sudo apt-get install -y docker.io docker-compose-v2

echo "==> Enable Docker"
sudo systemctl enable --now docker

echo "==> Add ${TARGET_USER} to docker group"
sudo usermod -aG docker "${TARGET_USER}"

echo
echo "Docker is installed. Group membership applies after a new login."
echo "Next steps:"
echo "  1) Log out and SSH back in, OR run: newgrp docker"
echo "  2) Then: docker ps"
echo
echo "Quick check without reconnecting (optional):"
if command -v sg >/dev/null 2>&1; then
  sg docker -c "docker ps" || true
fi
