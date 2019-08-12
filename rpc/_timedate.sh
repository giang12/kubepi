#!/bin/bash -e

user=$1
address=$2

ssh $user@$address << EOF

sudo -s
sudo timedatectl set-timezone UTC
sudo apt install -y ntp
sudo systemctl enable ntp
sudo timedatectl set-ntp 1

reboot

EOF
