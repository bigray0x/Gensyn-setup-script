#!/bin/bash

echo "===================================="
echo "  Gensyn Swarm Node Setup Script by bigray0x  "
echo "===================================="
sleep 2

# Update and install required packages
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt install -y python3 python3-venv python3-pip curl screen git

# Install Yarn properly (if missing)
if ! command -v yarn &> /dev/null; then
    echo "Adding Yarn repository..."
    sudo curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo tee /usr/share/keyrings/yarn-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update && sudo apt install -y yarn
else
    echo "Yarn is already installed."
fi

# Clone the gensyn-setup-script repository
echo "Cloning gensyn-setup-script repository..."
rm -rf gensyn-setup-script
if git clone https://github.com/bigray0x/gensyn-setup-script.git; then
    cd gensyn-setup-script || { echo "Failed to enter gensyn-setup-script directory! Exiting."; exit 1; }
else
    echo "Failed to clone repository! Exiting."
    exit 1
fi

# Make gensyn_setup.sh executable and run it
chmod +x gensyn_setup.sh
echo "Running gensyn_setup.sh..."
./gensyn_setup.sh

# Change to rl-swarm directory after gensyn_setup.sh execution
cd ../rl-swarm || { echo "Failed to enter rl-swarm directory! Exiting."; exit 1; }

# Create a new screen session and run RL Swarm
echo "Starting RL Swarm in a screen session..."
screen -dmS gensyn bash -c "
    cd '$(pwd)' &&
    python3 -m venv .venv &&
    source .venv/bin/activate &&
    ./run_rl_swarm.sh
"

echo "RL Swarm is now running in a detached screen session named 'gensyn'."
echo "Use 'screen -r gensyn' to attach to it."

# Prompt to create a Hugging Face token
echo "--------------------------------------------"
echo "Create a Hugging Face access token (Write permissions)"
echo "Visit: https://huggingface.co/settings/tokens"
echo "Save the token somewhere safe."
echo "--------------------------------------------"
sleep 5

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
echo " - Reattach: screen -r gensyn"
echo " - Stop: screen -XS gensyn quit"
echo "===================================="
