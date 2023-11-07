#!/bin/bash

# Function to install Docker on Ubuntu and derivatives
install_docker_ubuntu() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on CentOS and derivatives
install_docker_centos() {
  sudo yum check-update
  curl -fsSL https://get.docker.com/ | sh
}

# Function to install Docker on Fedora
install_docker_fedora() {
  sudo dnf -y install dnf-plugins-core
  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf -y install docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on Debian
install_docker_debian() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Detect the OS
OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

# Install Docker depending on the OS
case $OS_ID in
  ubuntu)
    install_docker_ubuntu
    ;;
  debian)
    install_docker_debian
    ;;
  centos)
    install_docker_centos
    ;;
  fedora)
    install_docker_fedora
    ;;
  *)
    echo "Unsupported operating system: $OS_ID"
    exit 1
    ;;
esac

# Enable and start Docker service
sudo systemctl enable --now docker

# Add the current user to the Docker group
sudo usermod -aG docker $USER

# Output Docker version information
docker version

# Prompt for a reboot
echo "Please reboot your system for the Docker installation to complete."
