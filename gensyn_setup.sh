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

# Run gensyn_setup.sh with a timeout (prevent infinite loops)
echo "Running gensyn_setup.sh..."
timeout 600 ./gensyn_setup.sh  # ⏳ Stops execution if it runs longer than 10 minutes

# Check if gensyn_setup.sh completed successfully
if [ $? -ne 0 ]; then
    echo "gensyn_setup.sh did not complete successfully. Exiting."
    exit 1
fi

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
echo "===================================="
