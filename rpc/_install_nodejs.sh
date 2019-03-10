#!/bin/bash -e

user=$1
address=$2

ssh $user@$address << EOF
if ! node -v; then
  echo "Setting up node"
  
  wget http://node-arm.herokuapp.com/node_latest_armhf.deb
  sudo dpkg -i node_latest_armhf.deb

  rm node_latest_armhf.deb
  
else
 echo "Nodejs already installed"
 npm version
fi
EOF
