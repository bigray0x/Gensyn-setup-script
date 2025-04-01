#!/bin/bash

echo "===================================="
echo "  Gensyn Swarm Node Setup Script by bigray0x  "
echo "===================================="
sleep 2

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Installing essential utilities..."
sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev \
    tar clang bsdmainutils ncdu unzip

# Install Docker if not already installed
if ! command_exists docker; then
    echo "Installing Docker..."

    # Remove old Docker versions
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg; 
    done

    # Add Docker repository if GPG key does not exist
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
    fi

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "Docker installation complete!"
else
    echo "Docker is already installed. Skipping installation."
fi

# Install Python if not already installed
if ! command_exists python3; then
    echo "Installing Python..."
    sudo apt-get install -y python3 python3-pip python3.10-venv
else
    echo "Python is already installed. Skipping installation."
fi

# Install Node.js if not already installed or is below version 14
node_version=$(node -v | sed 's/v//')
if ! command_exists node || [ "$node_version" \< "14" ]; then
    echo "Installing/updating Node.js to version 14+..."
    curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt-get install -y nodejs
    node -v
else
    echo "Node.js is already installed and compatible. Skipping installation."
fi

# Install Yarn if not already installed
if ! command_exists yarn; then
    echo "Installing Yarn..."
    curl -o- -L https://yarnpkg.com/install.sh | bash
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    source ~/.bashrc
    yarn -v
else
    echo "Yarn is already installed. Skipping installation."
fi

# Prompt to create a Hugging Face token
echo "--------------------------------------------"
echo "Create a Hugging Face access token (Write permissions)"
echo "Visit: https://huggingface.co/settings/tokens"
echo "Save the token somewhere safe."
echo "--------------------------------------------"
sleep 5

# Clone the RL Swarm repository if not already cloned
if [ ! -d "$HOME/rl-swarm" ]; then
    echo "Cloning RL Swarm repository..."
    git clone https://github.com/gensyn-ai/rl-swarm.git $HOME/rl-swarm
else
    echo "RL Swarm repository already exists. Skipping cloning."
fi

# Change to RL Swarm directory
cd $HOME/rl-swarm

# Ensure port 3000 is open
echo "Opening port 3000..."
sudo ufw allow 3000/tcp
sudo ufw reload

# Start RL Swarm in a screen session
if ! screen -list | grep -q "swarm"; then
    echo "Creating a new screen session for RL Swarm..."
    screen -dmS swarm bash -c "
        python3 -m venv .venv &&
        source .venv/bin/activate &&
        ./run_rl_swarm.sh &&
        exec bash
    "
else
    echo "Screen session 'swarm' already exists."
fi

# Attach to the screen session
echo "Attaching to RL Swarm session..."
sleep 2
screen -r swarm

echo "===================================="
echo "   RL Swarm setup complete!   "
echo "   Follow the instructions below:  "
echo "===================================="
echo "1. Wait for 'Waiting for userData.json to be created...' in the logs."
echo "2. Open the login page:"
echo "   - If on a local PC: http://localhost:3000/"
echo "   - If on a VPS: http://<YOUR_SERVER_IP>:3000/"
echo "3. If you can't access the login page remotely, forward the port:"
echo "   - Open PowerShell on your local PC"
echo "   - Run: ssh -L 3000:localhost:3000 root@<YOUR_SERVER_IP> -p <SSH_PORT>"
echo "   - Then open http://localhost:3000/ in your browser"
echo "4. After logging in, the node will complete setup."
echo "5. Find your node name by searching for 'Hello' in the terminal."
echo "6. Save the swarm.pem file in: /root/rl-swarm/"
echo "===================================="
echo "Screen Commands:"
echo " - Detach: CTRL + A + D"
echo " - Reattach: screen -r swarm"
echo " - Stop: screen -XS swarm quit"
echo "===================================="
