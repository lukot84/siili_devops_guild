#!/bin/bash

sudo apt update
[[ -x "$(command -v docker)" ]] || sudo apt install -y docker.io ; \
  sudo usermod -aG docker $(whoami)
[[ -x "$(command -v jq)" ]] ||  sudo apt install -y jq
[[ -x "$(command -v tmux)" ]] ||  sudo apt install -y tmux
[[ -x "$(command -v vim)" ]] ||  sudo apt install -y vim
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
[[ -x "$(command -v unzip)" ]] || sudo apt install unzip
unzip awscliv2.zip
./aws/install

curl -O https://raw.githubusercontent.com/lukot84/siili_devops_guild/main/ec2guard_Michal.sh /home/ubuntu/
(crontab -l ; echo "0 * * * * /home/ubuntu/ec2guard_Michal.sh") | sort - | uniq - | crontab -

# removing cloud init flag to run user data after each reboot
rm /var/lib/cloud/instance/sem/config_scripts_user