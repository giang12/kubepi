#!/bin/bash -e
user=$1
address=$2
hostname=$3


ssh $user@$address << EOF
if [[ \$(sudo grep "$hostname" /etc/hostname) ]] ; then
  echo "hostname already configured"
else
  echo "Running apt-get update"
  sudo apt-get update
  sudo apt-get install -y policykit-1

  echo "Setting hostname to $hostname"
  sudo hostname $hostname
  sudo sh -c 'echo $hostname > /etc/hostname'
  sudo sh -c 'echo "127.0.1.1 $hostname" >> /etc/hostnames'
fi
EOF
