#!/bin/bash

sudo apt update
[[ -x "$(command -v docker)" ]] || sudo apt install -y docker.io ; \
  sudo usermod -aG docker $(whoami)
[[ -x "$(command -v jq)" ]] ||  sudo apt install -y jq
[[ -x "$(command -v tmux)" ]] ||  sudo apt install -y tmux
[[ -x "$(command -v vim)" ]] ||  sudo apt install -y vim

# removing cloud init flag to run user data after each reboot
rm /var/lib/cloud/instance/sem/config_scripts_user