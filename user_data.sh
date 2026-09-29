#!/bin/bash
# Executado uma unica vez, no primeiro boot, como root
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io git
systemctl enable --now docker
usermod -aG docker ubuntu
