#!/bin/bash

echo "🚀 Starting RL Swarm setup..."

# Detect OS
OS=$(uname)
if [[ "$OS" == "Darwin" ]]; then
    echo "🖥️ Detected macOS."
    INSTALL_CMD="brew install"
    PYTHON_CMD="python3"
elif [[ "$OS" == "Linux" ]]; then
    echo "🖥️ Detected Linux."
    INSTALL_CMD="sudo apt install -y"
    PYTHON_CMD="python3"
    sudo apt update && sudo apt upgrade -y
else
    echo "❌ Unsupported OS."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
if [[ "$OS" == "Darwin" ]]; then
    brew install python3 git docker docker-compose node yarn screen
elif [[ "$OS" == "Linux" ]]; then
    sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev
    sudo apt install -y python3 python3-pip python3.10-venv
fi

# Install Docker (Linux only)
if [[ "$OS" == "Linux" ]]; then
    echo "🐳 Installing Docker..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    newgrp docker
fi

# Install Node.js & Yarn (Linux only)
if [[ "$OS" == "Linux" ]]; then
    echo "📦 Installing Node.js & Yarn..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    # If Yarn is not installed, install it via npm
    if ! command -v yarn &> /dev/null; then
        sudo npm install -g yarn
    fi
fi

# Clone RL Swarm repository
if [ ! -d "rl-swarm" ]; then
    echo "🐝 Cloning RL Swarm repository..."
    git clone https://github.com/gensyn-ai/rl-swarm.git
else
    echo "✅ RL Swarm repository already exists."
fi
cd rl-swarm

# Set up Python virtual environment
echo "🐍 Setting up Python virtual environment..."
$PYTHON_CMD -m venv .venv
source .venv/bin/activate

# Ensure screen is installed (for Linux, if somehow missing)
if ! command -v screen &> /dev/null; then
    echo "❌ Screen is not installed. Installing..."
    if [[ "$OS" == "Linux" ]]; then
        sudo apt install -y screen
    elif [[ "$OS" == "Darwin" ]]; then
        brew install screen
    fi
fi

# Create and start RL Swarm inside a screen session if not already running
if ! screen -list | grep -q "swarm"; then
    echo "🖥️ Starting RL Swarm inside a new screen session..."
    screen -S swarm -dm bash -c "./run_rl_swarm.sh; exec bash"
else
    echo "✅ Found existing screen session 'swarm'."
fi

echo "✅ RL Swarm is now running in a background screen session."

# Ask if user wants to attach to the screen session to watch logs
read -p "🔌 Do you want to attach to the RL Swarm screen session to watch logs? (y/N): " ATTACH_SCREEN
if [[ "$ATTACH_SCREEN" == "y" || "$ATTACH_SCREEN" == "Y" ]]; then
    screen -r swarm
fi

# Prompt for SSH port forwarding setup
read -p "🌍 Do you want to enable SSH port forwarding for remote access? (y/N): " ENABLE_FORWARD
if [[ "$ENABLE_FORWARD" == "y" || "$ENABLE_FORWARD" == "Y" ]]; then
    read -p "🔗 Enter your VPS username: " VPS_USER
    read -p "🌎 Enter your VPS IP address: " VPS_IP
    echo "🛠️ To access RL Swarm remotely, run this command on your local machine (Mac):"
    echo "ssh -L 3000:localhost:3000 -L 8080:localhost:8080 $VPS_USER@$VPS_IP"
fi

# Prompt for launching Swarm Dashboard UI
read -p "📊 Do you want to launch the RL Swarm Dashboard UI? (y/N): " ENABLE_UI
if [[ "$ENABLE_UI" == "y" || "$ENABLE_UI" == "Y" ]]; then
    echo "🚀 Launching RL Swarm Dashboard UI..."
    docker compose up -d --build
    echo "🌍 Open http://localhost:8080 in your browser to view the UI."
fi

echo "✅ RL Swarm setup complete!"
echo "📌 To stop the Swarm node, use: screen -XS swarm quit"
