#!/bin/bash -e

user=$1
address=$2


ssh $user@$address << EOF
echo "Rebooting $address"
sudo reboot
EOF
