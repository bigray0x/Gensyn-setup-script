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
    sudo apt update
else
    echo "❌ Unsupported OS."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
if [[ "$OS" == "Darwin" ]]; then
    brew install python3 git docker docker-compose
elif [[ "$OS" == "Linux" ]]; then
    sudo apt install -y python3 python3-venv git curl docker docker-compose
fi

# Clone RL Swarm repository
if [ ! -d "rl-swarm" ]; then
    echo "🐝 Cloning RL Swarm repository..."
    git clone https://github.com/RL-Swarm/rl-swarm.git
else
    echo "✅ RL Swarm repository already exists."
fi
cd rl-swarm

# Set up Python virtual environment
echo "🐍 Setting up Python virtual environment..."
$PYTHON_CMD -m venv .venv
source .venv/bin/activate

# Prompt for Hugging Face Token
read -p "🔑 Enter your Hugging Face token (or leave blank to skip): " HF_TOKEN
if [[ -n "$HF_TOKEN" ]]; then
    echo "🤖 Logging into Hugging Face..."
    huggingface-cli login --token $HF_TOKEN
fi

# Start RL Swarm
echo "🚀 Starting RL Swarm..."
./run_rl_swarm.sh &

# Prompt for remote access setup
read -p "🌍 Do you want to enable SSH port forwarding for remote access? (y/N): " ENABLE_FORWARD
if [[ "$ENABLE_FORWARD" == "y" || "$ENABLE_FORWARD" == "Y" ]]; then
    read -p "🔗 Enter your VPS username: " VPS_USER
    read -p "🌎 Enter your VPS IP address: " VPS_IP
    echo "🛠️ Setting up SSH port forwarding..."
    echo "Run the following command on your local machine (Mac) to access RL Swarm remotely:"
    echo "ssh -L 3000:localhost:3000 -L 8080:localhost:8080 $VPS_USER@$VPS_IP"
fi

echo "✅ RL Swarm setup complete!"
echo "📌 To access the Swarm UI, open http://localhost:8080 in your browser."
