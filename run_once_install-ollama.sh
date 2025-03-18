#!/bin/bash

echo "Generating CDI 󰥔..."
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list

echo "Done!"

echo "Enabling device access for containers so I can use your GPU!"
sudo setsebool -P container_use_devices true

echo "Pulling Ollama image"
 ollama/ollama

echo "Creating systemd file for container..."

SYSTEMD_FILE_DEFINITION="
[Unit]
Description=The ollama container
# After=local-fs.target

[Container]
ContainerName=ollama
Image=ollama/ollama
AddDevice=nvidia.com/gpu=all
SecurityLabelDisable=true
PublishPort=11434:11434
Volume=ollama:/root/.ollama:z

# Remove if you don't want autostart
[Install]
WantedBy=default.target
"

echo "Creating file and directory if it is not there..."
mkdir -p ~/.config/containers/systemd
touch ~/.config/containers/systemd/ollama.container

echo "$SYSTEMD_FILE_DEFINITION" | sudo tee ~/.config/containers/systemd/ollama.container
