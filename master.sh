#!/bin/bash -e

host="kubemaster"
address=$1


ssh $USER@$address << EOF
if [[ \$(ifconfig | grep 10.0.0.1) ]] ; then
  if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo "Kubeadm already initialized. Nothing to do"
  else
    echo "Initializing kubeadm"
    sudo kubeadm init \
      --pod-network-cidr 10.244.0.0/16 \
      --apiserver-advertise-address 10.0.0.1 \
      --apiserver-cert-extra-sans $address
    mkdir ~/pki
    sudo cp /etc/kubernetes/pki/* ~/pki
    sudo chown $USER ~/pki/*
  fi

else
  echo "Change to the permanent network and reboot the machine"
fi
EOF

./login.sh $address
kubectl apply -f manifests/flannel.yml
