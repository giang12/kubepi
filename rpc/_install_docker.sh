#!/bin/bash -e

user=$1
address=$2

ssh $user@$address << EOF
if ! docker -v; then
  echo "Setting up docker"
  curl -sSL https://get.docker.com | sh
  sudo usermod lucy -aG docker
  sudo usermod $user -aG docker

  sudo systemctl enable docker
  sudo systemctl start docker
else
 echo "Docker already installed"
 docker version
fi
EOF
