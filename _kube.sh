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


  sudo cp /boot/cmdline.txt /boot/cmdline_backup.txt
  sed '$s/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"/' /boot/cmdline.txt



else
  echo "Kube already installed."
fi
EOF


# echo Adding "cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory" to /boot/cmdline.txt
# sudo cp /boot/cmdline.txt /boot/cmdline_backup.txt
# sudo sh -c 'echo -n cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory >> /boot/cmdline.txt'
# 


# echo "Setting up kubernetes"
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# sudo apt-get update
# sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# echo "Done, rebooting"
# sudo reboot
