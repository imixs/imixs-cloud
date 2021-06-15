#!/bin/bash

############################################################
# Ceph Install Script for Debian 10 (Buster)
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
echo " adding core libraries..."
echo "#############################################"
apt update
apt install -y ne apt-transport-https ca-certificates curl gnupg lsb-release nftables ntp lvm2


echo "#############################################"
echo " installing docker...."
echo "#############################################"
# Add docker repositry
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
# install docker...
apt update
apt install -y docker-ce docker-ce-cli containerd.io



#####################################################################################
# docker is now installed 
#####################################################################################


