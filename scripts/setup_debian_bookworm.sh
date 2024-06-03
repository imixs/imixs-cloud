#!/bin/bash

############################################################
# Kubernetes Install Script for Debian 12 (Bookworm)
# This script installed the container runtime cri-o
# Find details: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
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
echo " adding k8s repositories ..."
apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
apt-get install -y apt-transport-https ca-certificates gnupg curl ufw

# Add kubernetes repository 
KUBERNETES_VERSION=v1.29
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg 
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

echo "#############################################"
echo " adding cri-o  repositories ..."
# See  also: https://github.com/cri-o/cri-o/blob/main/install.md#readme"
PROJECT_PATH=prerelease:/main
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list


echo "#############################################"
echo " installing kubernetes and container runtime CRI-O...."

apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl
apt-mark hold cri-o kubelet kubeadm kubectl

# Start and enable CRI-O
systemctl start crio.service
swapoff -a
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1



echo "#############################################"
echo " Setup completed."
echo " Kubernetes is now installed. "
echo " You can next setup a new kubernetes cluster with 'init' or join a cluster with 'join'"
echo "#####################################################################################"


