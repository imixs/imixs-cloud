#!/bin/bash

############################################################
# Kubernetes Install Script for Debian 10 (Buster)
# 
# run as sudo 
############################################################

 
# determine if we run as sudo
userid="${SUDO_USER:-$USER}"
if [ "$userid" == 'root' ]
  then 
    echo "Please run the setup as sudo and not as root!"
    exit 1
fi
if [ "$EUID" -ne 0 ]
  then 
    echo "Please run setup as sudo!"
    exit 1
fi


echo "#############################################"
echo " adding repositories..."
echo "#############################################"
apt update
apt install -y apt-transport-https ca-certificates ne curl gnupg2 software-properties-common nftables

# Add docker repositry
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/debian \
           $(lsb_release -cs) \
           stable"
           
# Add kubernetes repository           
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF



echo "...letting iptables see bridged traffic..."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


echo "#############################################"
echo " installing kubernetes...."
echo "#############################################"
apt update
apt install -y containerd kubelet kubeadm kubectl open-iscsi apache2-utils


echo "...setup containerd..."
#sudo apt-get update && sudo apt-get install -y containerd.io
# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
# Restart containerd
sudo systemctl restart containerd



echo "#############################################"
echo " setup for docker and kubernetes completed."
echo "#############################################"


#####################################################################################
# Kubernetes is now installed. To setup a new kubernetes cluster with a master node 
# run:
#  $ kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=[YOUR-NODE-IP-ADDRESS]
#
# This command will setup a new cluster. Follow the instructions of the output.
# The output will show also the command how to join a worker node.
# You can use this script also to install a worker node. 
#####################################################################################


