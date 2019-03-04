#!/bin/bash -e
user=$1
address=$2
hostname=$3

ssh $user@$address << EOF
  echo "Setting hostname to $hostname"
  sudo hostname $hostname
  sudo sh -c 'echo $hostname > /etc/hostname'
  sudo sh -c 'echo "127.0.1.1 $hostname" >> /etc/hosts'

  sudo reboot
fi
EOF
