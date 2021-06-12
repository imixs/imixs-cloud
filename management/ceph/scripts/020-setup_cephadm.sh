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
echo " installing cephadm on deployment-host onyl...."
echo "#############################################"
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm
mv cephadm /usr/local/bin
chmod +x /usr/local/bin/cephadm
mkdir -p /etc/ceph

# add ceph common tools
cephadm add-repo --release octopus
cephadm install ceph-common



#####################################################################################
# cephadm is now installed to setup a ceph cluster with cephadmin
#####################################################################################


