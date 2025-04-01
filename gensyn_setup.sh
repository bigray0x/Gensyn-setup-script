#!/bin/bash
# gensyn swarm node setup script by bigray0x
# RL Swarm (Testnet) Node Setup Script
# This script automates the installation of dependencies, cloning of the RL Swarm repository,
# creation of a Python virtual environment, and running the RL Swarm node in a screen session.
# It also prints instructions for login and launching the dashboard UI.

set -e

echo "========================================"
echo "gensyn swarm node setup script by bigray0x"
echo "RL Swarm (Testnet) Node Setup Script"
echo "========================================"

# 1) Update System Packages
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# 2) Install General Utilities and Tools
echo "Installing general utilities and tools..."
sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev

# 3) Install Docker
echo "Removing any old Docker installations..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

echo "Adding Docker repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Testing Docker installation..."
sudo docker run hello-world

echo "Tip: To run Docker without sudo, run: sudo usermod -aG docker \$USER"

# 4) Install Python and venv
echo "Installing Python and venv..."
sudo apt-get install -y python3 python3-pip python3.10-venv

# 5) Install Node.js
echo "Installing Node.js..."
sudo apt-get update
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v

# 6) Install Yarn
echo "Installing Yarn via npm..."
sudo npm install -g yarn
yarn -v

echo "Installing Yarn via official install script..."
curl -o- -L https://yarnpkg.com/install.sh | bash
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
source ~/.bashrc

# 7) HuggingFace Access Token Reminder
echo "========================================"
echo "HuggingFace Setup Reminder:"
echo "----------------------------------------"
echo "Please create a HuggingFace account and generate an Access Token"
echo "with WRITE permissions. Save this token securely."
echo "You will be prompted for it later during the RL Swarm login via the browser."
echo "----------------------------------------"
echo "Press ENTER to continue once you've created your token..."
read -r

# 8) Clone the RL Swarm Repository
echo "Cloning the RL Swarm repository..."
if [ ! -d "rl-swarm" ]; then
    git clone https://github.com/gensyn-ai/rl-swarm.git
else
    echo "Repository already exists; pulling latest changes..."
    cd rl-swarm && git pull && cd ..
fi
cd rl-swarm

# 9) Run the Swarm Node in a Screen Session
echo "Creating a screen session named 'swarm' to run RL Swarm in the background..."
screen -S swarm -dm bash -c "
  echo 'Starting RL Swarm Node...';
  python3 -m venv .venv;
  source .venv/bin/activate;
  ./run_rl_swarm.sh;
  echo 'When prompted, press Y to join the testnet.';
  exec bash
"

echo "RL Swarm node is now running in a screen session named 'swarm'."
echo "To attach to the screen session and view logs, run: screen -r swarm"
echo "To detach from the session, press: Ctrl+A then D"
echo "To stop the node, run: screen -XS swarm quit"

# 10) Login and Remote Access Instructions
echo "========================================"
echo "Login and Remote Access Instructions"
echo "========================================"
echo "Once the node starts, you should see 'Waiting for userData.json to be created...' in the logs."
echo "Open your browser and navigate to:"
echo "  Local PC: http://localhost:3000/"
echo "  VPS: http://<Your_Server_IP>:3000/"
echo ""
echo "If you cannot login via your VPS address, set up SSH port forwarding."
echo "For example, on Windows (using PowerShell), run:"
echo "  ssh -L 3000:localhost:3000 root@<Server_IP> -p <SSH_PORT>"
echo "Then open http://localhost:3000/ in your browser to login."

# 11) Optional: Launch Swarm Dashboard UI
read -p "Do you want to launch the RL Swarm Dashboard UI now? (y/N): " launch_ui
if [[ "$launch_ui" =~ ^[Yy]$ ]]; then
    echo "Launching RL Swarm Dashboard UI..."
    docker compose up -d --build
    echo "Dashboard UI is available at:"
    echo "  Local PC: http://0.0.0.0:8080"
    echo "  VPS: http://<Your_Server_IP>:8080"
    echo "Official dashboard: https://dashboard.gensyn.ai/"
fi

echo "========================================"
echo "RL Swarm Node Setup Complete!"
echo "========================================"
