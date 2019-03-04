#!/bin/bash -e

user=$1
address=$2


#For Kubernetes 1.7 and onwards you will get an error if swap space is enabled.
ssh $user@$address << EOF
if ! kubeadm version; then
  sudo dphys-swapfile swapoff
  sudo dphys-swapfile uninstall
  sudo update-rc.d dphys-swapfile remove
  sudo swapon --summary

  curl -sLSf https://raw.githubusercontent.com/giang12/kubepi/94c2c5580a76c9efc05b4d1323ab136d71abc9d0/append_cmdline.sh | sudo sh


  echo "Setting up kubernetes"
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

  echo "Done, rebooting"
  sudo reboot

else
  echo "Kube already installed."
fi
EOF
